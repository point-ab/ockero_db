import os
from dotenv import load_dotenv
from dlt.sources.rest_api import rest_api_source

load_dotenv()

_ALL_RESOURCES = ["persons", "duties", "placements", "organisations", "groups", "activities"]


def load_ss12000_data(cfg: dict):
    return rest_api_source({
        "client": {
            "base_url": cfg.get("base_url", "https://sms.schoolsoft.se/ockero/ss12000/v2/"),
            "auth": {
                "type": "bearer",
                "token": os.getenv("SS12000_TOKEN"),
            },
        },
        "resource_defaults": {"write_disposition": "replace"},
        "resources": [{"name": r, "endpoint": r} for r in _ALL_RESOURCES],
    })
