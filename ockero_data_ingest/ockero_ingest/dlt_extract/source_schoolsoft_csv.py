import dlt
import csv
import chardet
from pathlib import Path
from datetime import datetime
from ockero_ingest.config_loader import project_root


def _detect_csv_params(file_path: Path):
    with open(file_path, "rb") as f:
        result = chardet.detect(f.read())
    encoding = result["encoding"] or "utf-8-sig"
    print(f"{file_path.name} — encoding: {encoding}")

    with open(file_path, "r", encoding=encoding) as f:
        try:
            delimiter = csv.Sniffer().sniff(f.read(2048)).delimiter
        except csv.Error:
            delimiter = ","
    print(f"{file_path.name} — delimiter: {repr(delimiter)}")
    return encoding, delimiter


def _file_modified_time(file_path: Path) -> str:
    return datetime.fromtimestamp(file_path.stat().st_mtime).isoformat()


def _make_csv_resource(resource_name: str, data_dir: Path, filename: str):
    @dlt.resource(name=resource_name, write_disposition="replace")
    def _resource():
        file_path = data_dir / filename
        encoding, delimiter = _detect_csv_params(file_path)
        modified_at = _file_modified_time(file_path)
        with open(file_path, "r", encoding=encoding, newline="") as f:
            for row in csv.DictReader(f, delimiter=delimiter):
                row["file_modified_at"] = modified_at
                yield row
    return _resource()


@dlt.source
def load_data_csv_file(cfg: dict):
    import_dir = cfg.get("import_dir", "import_data")
    raw = Path(import_dir)
    data_dir = raw if raw.is_absolute() else project_root() / raw
    files = cfg.get("files", {})
    resources = []
    if "ea_elever" in files:
        resources.append(_make_csv_resource("ea_elever", data_dir, files["ea_elever"]))
    if "ea_barn" in files:
        resources.append(_make_csv_resource("ea_barn", data_dir, files["ea_barn"]))
    return resources
