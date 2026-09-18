"""Test-scoped wrapper around load_skola24_data, for small controlled runs
against the real (non-sandbox) Skola24 API without touching production
tables or pulling the full student population.

Not used in production -- kept separate so source_skola24.py stays free of
test-only knobs. Uses dlt's own resource limiting (DltResource.add_limit)
rather than a custom cap threaded through the source itself.

Loads into its own skola24_test_* tables (dlt_extract_pipeline.run_source()
prefixes tables with the source name), so test runs never touch the
production skola24_* tables.
"""
from ockero_ingest.dlt_extract.source_skola24 import load_skola24_data


def load_skola24_data_test(cfg: dict):
    max_students = int(cfg.get("max_students", 50))
    source = load_skola24_data(cfg)
    source.persons.add_limit(max_students)
    return source
