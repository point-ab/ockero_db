import functools
import math
import os
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta

import dlt
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from dotenv import load_dotenv

from ockero_ingest.utils.logger import StepLogger

load_dotenv()

# base_url and token_url are NOT defaulted here -- both are required in config.yml
# (see load_skola24_data below), so there's exactly one place that defines which
# tenant/endpoint a run talks to.
non_student_group_types = {"Personalgrupp"}  # group types to skip when harvesting student IDs from group memberships
max_persons_batch = 300  # Person.MaxPostIds -- API cap on ids per POST persons/lookup; also the persons_batch_size default
attendance_batch_size = 75  # activities per POST attendances/lookup to start with; halved on 503 (see attendance_lookup)
max_window_days = 30  # CalendarEvents.MaxDaysBetween -- hard API limit on the start-time range; also the calendar_window_days fallback/cap
throttle_window = 60  # seconds -- every endpoint's throttle is "HitLimit requests per 60 s"
throttle_limits = {  # HitLimit per endpoint family (first path segment), from the API provider's config 2026-09-16
    "organisations": 25,
    "groups": 100,
    "activities": 100,
    "persons": 50,
    "calendarEvents": 10,
    "attendances": 100,
}
rate_limit_cooldown = throttle_window  # fallback if a 429 still slips through: wait out a full window

# Skola24 Samverkansprogram is an SS12000 API, but this client's access is
# privacy-gated: `persons` and `attendances` cannot be listed, and every other
# collection must be filtered by organisation.
#   - GET  organisations                          -> all orgs (unfiltered)
#   - GET  groups?organisation={id}               -> groups + groupMemberships (student IDs)
#   - GET  activities?organisation={id}           -> recurring course/class sections (activity IDs)
#   - POST persons/lookup {"ids":[...]}           -> many persons per call (batched)
#   - POST attendances/lookup {"activities":[...]} -> ALL students' full attendance history
#                                                    for those activities (no date filter).
#                                                    503 means "response too large, split
#                                                    the batch" -- not transient, so we halve
#                                                    and retry (see attendance_lookup()).
#   - GET  calendarEvents?organisation=...        -> lessons; needs a <=30 day window
#                                                    (startTime.onOrAfter/onOrBefore)
# Student IDs come from group memberships and activity IDs from activities, so
# persons/attendances only depend on cheap per-org listings. The attendance row
# carries only calendarEvent.id, not the lesson date -- join calendar_events in dbt.
#
# Throttling is per endpoint (throttle_limits above), not per client: calendarEvents
# allows only 10 requests/60 s, attendances 100/60 s. pace() below spreads requests
# so we never hit a limit; a 429 (never carries Retry-After) is only a fallback.
# Attendances also caps a response at 30,000 rows -- that is the 503 handled in
# attendance_lookup().


def get_token(token_url: str, scope: str = None) -> str:
    """Fetch an OAuth2 client_credentials bearer token. Needed because every
    request to the API must carry one, and it can expire mid-run (re-fetched
    on 401 by auth_retry() below)."""
    data = {
        "grant_type": "client_credentials",
        "client_id": os.getenv("skola24_clientid"),
        "client_secret": os.getenv("skola24_client_secret"),
    }
    if scope:
        data["scope"] = scope
    resp = requests.post(token_url, data=data, timeout=30)
    resp.raise_for_status()
    return resp.json()["access_token"]


def build_session(token: str) -> requests.Session:
    """A requests.Session reused for the whole run, with the bearer token set
    and an adapter that retries genuinely transient 500/502/504 errors --
    needed so a single flaky response doesn't fail a run that otherwise makes
    hundreds of requests. 429 is avoided by pace() and, as a fallback, handled
    by rate_limit_retry(); 503 is handled by attendance_lookup() (means "split
    the batch") -- so neither belongs in this adapter."""
    session = requests.Session()
    session.headers["Authorization"] = "Bearer " + token
    retry = Retry(
        total=5,
        backoff_factor=2,  # 0, 2, 4, 8, 16 seconds
        status_forcelist=[500, 502, 504],
        allowed_methods=frozenset(["GET", "POST"]),
        raise_on_status=False,
    )
    session.mount("https://", HTTPAdapter(max_retries=retry))
    return session


def date_windows(start_str: str, end_str: str, step_days: int = max_window_days):
    """Split a date range into <=step_days chunks. Needed because calendarEvents
    rejects any query spanning more than 30 days, so a wider calendar_start/
    calendar_end range from config.yml has to be fetched in multiple windows."""
    start = datetime.strptime(start_str, "%Y-%m-%d")
    end = datetime.strptime(end_str, "%Y-%m-%d")
    cur = start
    while cur <= end:
        win_end = min(cur + timedelta(days=step_days - 1), end)
        yield (
            cur.strftime("%Y-%m-%dT00:00:00Z"),
            win_end.strftime("%Y-%m-%dT23:59:59Z"),
        )
        cur = win_end + timedelta(days=1)


def rows(resp: requests.Response) -> list:
    """Raise on HTTP errors, then unwrap the body -- lookup endpoints answer
    either a bare list or {"data": [...]}."""
    resp.raise_for_status()
    body = resp.json()
    return body if isinstance(body, list) else body.get("data", [])


@dlt.source(name="skola24")
def load_skola24_data(cfg: dict):
    token_url = cfg.get("token_url")
    if not token_url:
        raise ValueError(
            "skola24.token_url is not set in config.yml. Add the OAuth2 token "
            "endpoint from your Skola24 Samverkansprogram onboarding."
        )

    raw_base_url = cfg.get("base_url")
    if not raw_base_url:
        raise ValueError(
            "skola24.base_url is not set in config.yml. Add the SS12000 API "
            "base URL from your Skola24 Samverkansprogram onboarding."
        )
    base_url = raw_base_url.rstrip("/") + "/"
    scope = cfg.get("scope")
    persons_batch_size = min(int(cfg.get("persons_batch_size", max_persons_batch)), max_persons_batch)
    calendar_window_days = min(int(cfg.get("calendar_window_days", max_window_days)), max_window_days)

    session = build_session(get_token(token_url, scope))

    # ---- HTTP layer -------------------------------------------------------

    def auth_retry(resp, redo):
        if resp.status_code == 401:
            session.headers["Authorization"] = "Bearer " + get_token(token_url, scope)
            resp = redo()
        return resp

    request_times = defaultdict(deque)  # endpoint family -> timestamps of requests in the current window

    def pace(endpoint):
        """Sleep just long enough to stay under the endpoint family's HitLimit
        per throttle_window, so a 429 is never triggered in the first place."""
        family = endpoint.split("/")[0]
        limit = throttle_limits.get(family)
        if not limit:
            return
        times = request_times[family]
        now = time.monotonic()
        while times and now - times[0] >= throttle_window:
            times.popleft()
        if len(times) >= limit:
            time.sleep(throttle_window - (now - times[0]) + 0.5)
        times.append(time.monotonic())

    def rate_limit_retry(resp, redo):
        while resp.status_code == 429:
            time.sleep(float(resp.headers.get("Retry-After") or rate_limit_cooldown))
            resp = redo()
        return resp

    def request(method, endpoint, **kwargs):
        def redo():
            pace(endpoint)
            return session.request(method, base_url + endpoint, timeout=120, **kwargs)
        return rate_limit_retry(auth_retry(redo(), redo), redo)

    def paged(endpoint, params=None, empty_on_400=False):
        params = dict(params or {})
        while True:
            resp = request("GET", endpoint, params=params)
            # calendarEvents answers 400 when a filter matches no rows
            # ("...resulterade i inget svar").
            if empty_on_400 and resp.status_code == 400:
                return
            resp.raise_for_status()
            body = resp.json()
            yield from body.get("data", [])
            page_token = body.get("pageToken")
            if not page_token:
                return
            params["pageToken"] = page_token

    # ---- Cached crawls ----------------------------------------------------
    # functools.cache on these zero-argument helpers means each listing is
    # fetched once per run and shared by every resource that needs it (groups
    # feed both student_ids() and group_memberships, activities feed both
    # activity_ids() and the activities resource).

    @functools.cache
    def organisation_list():
        logger = StepLogger("organisations", 1)
        t = time.time()
        orgs = list(paged("organisations"))
        logger.log("all", len(orgs), time.time() - t)
        return orgs

    def org_ids():
        return [org["id"] for org in organisation_list()]

    def crawl_by_org(endpoint):
        """GET {endpoint}?organisation={id} for every org -> {org_id: rows}."""
        org_id_list = org_ids()
        logger = StepLogger(endpoint, len(org_id_list))
        result = {}
        for org_id in org_id_list:
            t = time.time()
            result[org_id] = list(paged(endpoint, {"organisation": org_id}))
            logger.log(f"org {logger.i + 1}/{len(org_id_list)}", len(result[org_id]), time.time() - t)
        return result

    @functools.cache
    def groups_by_org():
        return crawl_by_org("groups")

    @functools.cache
    def activities_by_org():
        return crawl_by_org("activities")

    @functools.cache
    def student_ids():
        students = set()
        for groups in groups_by_org().values():
            for group in groups:
                if group.get("groupType") in non_student_group_types:
                    continue
                for member in group.get("groupMemberships") or []:
                    pid = (member.get("person") or {}).get("id")
                    if pid:
                        students.add(pid)
        return sorted(students)

    def calendar_range():
        start = cfg.get("calendar_start")
        end = cfg.get("calendar_end")
        if not (start and end):
            raise ValueError(
                "skola24.calendar_start and calendar_end (YYYY-MM-DD) must be set "
                "in config.yml to ingest calendar_events/attendances."
            )
        return start, end

    @functools.cache
    def activity_ids():
        # Only activities that overlap calendar_start..calendar_end. attendances/lookup
        # returns each activity's FULL history, and the tenant keeps three school
        # years of finished activities (~2.7M rows) -- without this filter every run
        # would reload all of it. Dates are YYYY-MM-DD strings, so plain comparison works.
        start, end = calendar_range()
        return sorted(
            activity["id"]
            for activities in activities_by_org().values()
            for activity in activities
            if activity.get("id")
            and (activity.get("endDate") or "9999") >= start
            and (activity.get("startDate") or "0000") <= end
        )

    def attendance_lookup(batch):
        """POST attendances/lookup {"activities": batch}. On the "response too
        large" 503 (size-dependent, not a fixed activity count), halve the batch
        and retry each half recursively."""
        if not batch:
            return
        resp = request("POST", "attendances/lookup", json={"activities": batch})
        if resp.status_code == 503 and len(batch) > 1:
            mid = len(batch) // 2
            yield from attendance_lookup(batch[:mid])
            yield from attendance_lookup(batch[mid:])
            return
        yield from rows(resp)

    # ---- Resources --------------------------------------------------------

    @dlt.resource(name="organisations", write_disposition="replace")
    def organisations():
        yield from organisation_list()

    @dlt.resource(name="group_memberships", write_disposition="replace")
    def group_memberships():
        for org_id, groups in groups_by_org().items():
            for group in groups:
                for member in group.get("groupMemberships") or []:
                    yield {
                        "person_id": (member.get("person") or {}).get("id"),
                        "group_id": group.get("id"),
                        "group_display_name": group.get("displayName"),
                        "group_type": group.get("groupType"),
                        "school_type": group.get("schoolType"),
                        "organisation_id": org_id,
                        "start_date": member.get("startDate"),
                        "end_date": member.get("endDate"),
                    }

    # Recurring course/class sections (name, type, teachers, groups, syllabus,
    # start/end dates). Attendance rows reference activity.id -- join here for
    # the course name.
    @dlt.resource(name="activities", write_disposition="replace")
    def activities():
        for org_activities in activities_by_org().values():
            yield from org_activities

    @dlt.resource(name="persons", write_disposition="replace")
    def persons():
        ids = student_ids()
        logger = StepLogger("persons/lookup", math.ceil(len(ids) / persons_batch_size))
        for start in range(0, len(ids), persons_batch_size):
            chunk = ids[start : start + persons_batch_size]
            t = time.time()
            people = rows(request("POST", "persons/lookup", json={"ids": chunk}))
            yield from people
            logger.log(f"{start + len(chunk)}/{len(ids)} ids", len(people), time.time() - t)

    # Per-student, per-lesson attendance, fetched by activity: every activity's
    # FULL history (no date filter), for all students at once. Far fewer
    # activities than students, so this is one to two orders of magnitude fewer
    # requests than fetching per student. Which activities: see activity_ids().
    @dlt.resource(name="attendances", write_disposition="replace")
    def attendances():
        ids = activity_ids()
        logger = StepLogger("attendances/lookup", math.ceil(len(ids) / attendance_batch_size))
        for start in range(0, len(ids), attendance_batch_size):
            batch = ids[start : start + attendance_batch_size]
            t = time.time()
            n = 0
            for row in attendance_lookup(batch):
                n += 1
                yield row
            logger.log(f"{start + len(batch)}/{len(ids)} activities", n, time.time() - t)

    # Lesson schedule (date/time/activity/room/teacher) for the configured
    # calendar_start..calendar_end range, streamed per org and <=30-day window.
    # Only orgs that have activities can have lessons -- skipping the rest matters
    # here because calendarEvents allows just 10 requests per minute.
    @dlt.resource(name="calendar_events", write_disposition="replace")
    def calendar_events():
        start, end = calendar_range()
        org_id_list = [org_id for org_id, org_activities in activities_by_org().items() if org_activities]
        windows = list(date_windows(start, end, calendar_window_days))
        logger = StepLogger("calendarEvents", len(org_id_list) * len(windows))
        for oi, org_id in enumerate(org_id_list, 1):
            for after, before in windows:
                params = {
                    "organisation": org_id,
                    "startTime.onOrAfter": after,
                    "startTime.onOrBefore": before,
                }
                t = time.time()
                n = 0
                for row in paged("calendarEvents", params, empty_on_400=True):
                    n += 1
                    yield row
                logger.log(f"org {oi}/{len(org_id_list)} {after[:10]}", n, time.time() - t)

    return [organisations, group_memberships, activities, persons, attendances, calendar_events]
