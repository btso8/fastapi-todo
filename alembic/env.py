# alembic/env.py
from __future__ import annotations

import os
import sys
from pathlib import Path
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool
from dotenv import load_dotenv
from sqlmodel import SQLModel  # <-- import SQLModel from sqlmodel

# Load .env into os.environ
load_dotenv()

# -------------------------------------------------------------------
# Ensure we can import your app package (root or src layout)
# -------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = PROJECT_ROOT / "src"

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))
if SRC_DIR.exists() and str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

# Import models so tables register on SQLModel.metadata
from app import models  # noqa: F401

# Alembic config + logging
config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Metadata for autogenerate
target_metadata = SQLModel.metadata


def _get_db_url() -> str:
    # 1) .env / environment
    env_url = os.getenv("DATABASE_URL")
    if env_url:
        return env_url.strip()

    # 2) alembic.ini [alembic] sqlalchemy.url
    ini_url = (config.get_main_option("sqlalchemy.url") or "").strip()
    if ini_url and not (ini_url.startswith("${") and ini_url.endswith("}")):
        return ini_url

    # 3) default: local SQLite file
    return "sqlite:///./dev.db"


def _is_sqlite(url: str) -> bool:
    return url.startswith("sqlite")


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = _get_db_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
        compare_server_default=True,
        render_as_batch=_is_sqlite(url),  # needed for SQLite
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    url = _get_db_url()

    # If alembic.ini didn't have a URL, inject the resolved one (helps logging etc.)
    if not (config.get_main_option("sqlalchemy.url") or "").strip():
        config.set_main_option("sqlalchemy.url", url)

    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
        future=True,  # SQLAlchemy 2.x style engine
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=True,
            render_as_batch=connection.engine.url.get_backend_name() == "sqlite",
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
