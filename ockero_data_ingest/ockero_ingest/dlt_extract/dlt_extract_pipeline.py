import os
import dlt
from dotenv import load_dotenv
from dlt.destinations.impl.mssql.configuration import MsSqlCredentials
from ockero_ingest.dlt_extract.dlt_utils import run_pipeline
from ockero_ingest.dlt_extract.source_schoolsoft import schoolsoft_source
from ockero_ingest.dlt_extract.source_elin import load_elin_data
from ockero_ingest.dlt_extract.source_schoolsoft_csv import load_data_csv_file
from ockero_ingest.dlt_extract.source_ss12000 import load_ss12000_data

load_dotenv()

_SOURCE_FACTORIES = {
    "schoolsoft": schoolsoft_source,
    "elin": load_elin_data,
    "schoolsoft_csv": load_data_csv_file,
    "ss12000": load_ss12000_data,
}


def _mssql_destination():
    creds = MsSqlCredentials()
    creds.host = os.getenv("MSSQL_HOST", "localhost")
    creds.port = int(os.getenv("MSSQL_PORT", "1433"))
    creds.database = os.getenv("MSSQL_DATABASE")
    creds.username = os.getenv("MSSQL_USERNAME")
    creds.password = os.getenv("MSSQL_PASSWORD")
    creds.driver = os.getenv("MSSQL_DRIVER", "ODBC Driver 17 for SQL Server")
    creds.query = {"TrustServerCertificate": "yes", "Encrypt": "no"}
    return dlt.destinations.mssql(credentials=creds)


def run_source(name: str, config: dict):
    schema = config.get("destination", {}).get("schema", "bronze")
    src_cfg = config["sources"][name]

    pipeline = dlt.pipeline(
        pipeline_name=f"{name}_pipeline",
        destination=_mssql_destination(),
        dataset_name=schema,
    )

    source = _SOURCE_FACTORIES[name](src_cfg)

    # Prefix every table with the source name: {source}_{table}
    for resource_name in list(source.resources.keys()):
        source.resources[resource_name].apply_hints(table_name=f"{name}_{resource_name}")

    active_resources = [r for r, enabled in src_cfg.get("resources", {}).items() if enabled]
    if active_resources:
        source = source.with_resources(*active_resources)

    run_pipeline(pipeline, source)
