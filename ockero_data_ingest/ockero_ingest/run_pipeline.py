import sys
from ockero_ingest.config_loader import load_config
from ockero_ingest.utils.logger import PipelineLogger, Timer
from ockero_ingest.dlt_extract.dlt_extract_pipeline import run_source as _run_source


def run_sources(source_names: list = None):
    """Run selected sources, or all enabled sources if source_names is None."""
    logger = PipelineLogger()
    timer = Timer()
    config = load_config()

    if source_names is None:
        source_names = [name for name, cfg in config["sources"].items() if cfg.get("enabled", False)]

    logger.print_header("OCKERO DATA INGEST")
    timer.start()

    total = len(source_names)
    for i, name in enumerate(source_names, 1):
        step_timer = Timer()
        step_timer.start()
        logger.print_section(f"SOURCE {i}/{total}: {name.upper()}")
        logger.print_step(i, total, "START", name)

        try:
            _run_source(name, config)
            logger.print_step(i, total, "OK", name, step_timer.elapsed())
        except Exception as e:
            logger.print_step(i, total, "ERROR", name, step_timer.elapsed())
            logger.print_error(str(e))
            logger.print_failure(f"Source: {name}")
            sys.exit(1)

    logger.print_success_summary(timer.elapsed(), [{"name": n} for n in source_names])
