{{config(alias='aktiviteter')}}

select
    a.id                as activity_id
    ,a.syllabus__id     as syllabus_id
    ,a.organisation__id as organisation_id-- alla samma, så öckerö kommun
    ,ag.id              as group_id
    ,ad.duty__id        as duty_id
    ,a.display_name     as activity_name
    ,a.activity_type
    ,a.minutes_planned
    ,a.calendar_events_required
    ,a.start_date
    ,a.end_date
    ,a.meta__created    as meta_created
    ,a.meta__modified   as meta_modified
    ,a._dlt_load_id     as dlt_load_id
    ,a._dlt_id          as dlt_id
from
            dlt_ss12000.activities           as a
left join   dlt_ss12000.activities__groups   as ag on a._dlt_id = ag._dlt_parent_id
left join   dlt_ss12000.activities__teachers as ad on a._dlt_id = ad._dlt_parent_id
