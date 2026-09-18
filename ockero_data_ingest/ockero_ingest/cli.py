import typer
from ockero_ingest.run_pipeline import run_sources

app = typer.Typer(help="Ockero data ingestion pipeline")


@app.command()
def run(
    schoolsoft: bool = typer.Option(False, "--schoolsoft", help="Run Schoolsoft API source"),
    elin: bool = typer.Option(False, "--elin", help="Run Elevinformation API source"),
    csv: bool = typer.Option(False, "--csv", help="Run Schoolsoft CSV source"),
    ss12000: bool = typer.Option(False, "--ss12000", help="Run SS12000 (Schoolsoft) source"),
    skola24: bool = typer.Option(False, "--skola24", help="Run Skola24 Samverkansprogram SS12000 source"),
    skola24_test: bool = typer.Option(False, "--skola24-test", help="Run Skola24 source capped to a small student count, into skola24_test_* tables"),
):
    """Run data ingestion. No flags = run all sources enabled in config.yml."""
    selected = [name for name, flag in [("schoolsoft", schoolsoft), ("elin", elin), ("schoolsoft_csv", csv), ("ss12000", ss12000), ("skola24", skola24), ("skola24_test", skola24_test)] if flag]
    run_sources(selected or None)


if __name__ == "__main__":
    app()
