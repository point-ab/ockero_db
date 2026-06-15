import os
from datetime import date
from dotenv import load_dotenv
from dlt.sources.rest_api import rest_api_source

load_dotenv()


def load_elin_data(cfg: dict):
    today = date.today()
    to_date = today.strftime("%Y-%m-%d")
    from_date = f"{today.year if today.month > 6 else today.year - 1}-07-01"

    return rest_api_source({
        "client": {
            "base_url": cfg.get("base_url", "https://elevinformation.se/api"),
            "auth": {
                "type": "http_basic",
                "username": os.getenv("elin_username"),
                "password": os.getenv("elin_password"),
            },
            "paginator": {"type": "single_page"},
        },
        "resource_defaults": {"write_disposition": "replace"},
        "resources": [
            {
                "name": "export_data",
                "endpoint": {
                    "path": "Export",
                    "params": {
                        "from": from_date,
                        "to": to_date,
                        "method": cfg.get("method", "gbg"),
                        "kommunkod": cfg.get("kommunkod", "1407"),
                    },
                },
            }
        ],
    })
