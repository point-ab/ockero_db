import typer
from ockero_ingest.run_pipeline import run_sources

app = typer.Typer(help="Ockero data ingestion pipeline")


@app.command()
def run(
    schoolsoft: bool = typer.Option(False, "--schoolsoft", help="Run Schoolsoft API source"),
    elin: bool = typer.Option(False, "--elin", help="Run Elevinformation API source"),
    csv: bool = typer.Option(False, "--csv", help="Run Schoolsoft CSV source"),
):
    """Run data ingestion. No flags = run all sources enabled in config.yml."""
    selected = [name for name, flag in [("schoolsoft", schoolsoft), ("elin", elin), ("schoolsoft_csv", csv)] if flag]
    run_sources(selected or None)


if __name__ == "__main__":
    app()
