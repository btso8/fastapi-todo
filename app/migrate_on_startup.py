import logging
import os
from contextlib import contextmanager

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

from alembic import command
from alembic.config import Config

log = logging.getLogger(__name__)
LOCK_KEY = 777_777_777


def _engine() -> Engine:
    return create_engine(os.environ["DATABASE_URL"], pool_pre_ping=True)


@contextmanager
def advisory_lock(engine: Engine):
    with engine.begin() as conn:
        conn.execute(text("SELECT pg_advisory_lock(:k)"), {"k": LOCK_KEY})
    try:
        yield
    finally:
        with engine.begin() as conn:
            conn.execute(text("SELECT pg_advisory_unlock(:k)"), {"k": LOCK_KEY})


def run_migrations_if_enabled():
    if os.getenv("RUN_MIGRATIONS", "1") not in ("1", "true", "True"):
        log.info("RUN_MIGRATIONS disabled; skipping Alembic.")
        return

    db_url = os.environ["DATABASE_URL"]
    cfg = Config("alembic.ini")
    cfg.set_main_option("sqlalchemy.url", db_url)

    log.info("Running Alembic migrations…")
    with advisory_lock(_engine()):
        command.upgrade(cfg, "head")
    log.info("Migrations complete.")
