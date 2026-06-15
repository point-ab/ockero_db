import dlt
import requests
import csv
import os
from io import StringIO
from typing import Iterator, Dict, Any, Optional
from dotenv import load_dotenv

load_dotenv()

_ENDPOINTS = {
    "schools": "/export/schools.jsp",
    "students": "/export/students.jsp",
    "studentgrades": "/export/studentgradesubjects.jsp",
    "subjects": "/export/gradesubjects.jsp",
}


def _fetch(base_url: str, endpoint: str, params: Optional[Dict[str, str]] = None) -> str:
    api_password = os.getenv("SS12000_SECRET")
    headers = {"X-REMOTEPWD": api_password}
    params = dict(params or {})
    params.setdefault("fileFormat", "txt")
    response = requests.get(f"{base_url}{endpoint}", headers=headers, params=params)
    response.raise_for_status()
    return response.text


def _parse_tsv(tsv_text: str) -> list:
    try:
        reader = csv.DictReader(StringIO(tsv_text), delimiter="\t")
        items = list(reader)
        print(f"Parsed {len(items)} rows, columns: {list(items[0].keys()) if items else []}")
        return items
    except Exception as e:
        print(f"TSV parse error: {e}")
        return [{"raw_response": tsv_text, "parse_error": str(e)}]


def _make_resource(name: str, base_url: str, endpoint: str, params: Dict[str, Any] = None):
    @dlt.resource(name=name, write_disposition="replace")
    def _resource() -> Iterator[Dict[str, Any]]:
        print(f"Fetching {name} from {endpoint}")
        for item in _parse_tsv(_fetch(base_url, endpoint, params)):
            yield item
    return _resource()


@dlt.source
def schoolsoft_source(cfg: dict):
    base_url = cfg["base_url"]
    return [_make_resource(name, base_url, endpoint) for name, endpoint in _ENDPOINTS.items()]
