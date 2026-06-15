import yaml
from pathlib import Path


def load_config() -> dict:
    config_path = Path.cwd() / "config.yml"
    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def project_root() -> Path:
    return Path.cwd()
