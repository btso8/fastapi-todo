from __future__ import annotations

import os
import sys
from logging.config import fileConfig
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import engine_from_config, pool
from sqlmodel import SQLModel

from alembic import context

# -------------------------------------------------------------
# Load .env and ensure 'app' package is importable
# -------------------------------------------------------------
load_dotenv()

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

# Optional: src/ layout
SRC_DIR = PROJECT_ROOT / "src"
if SRC_DIR.exists() and str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

# Import models so they register on SQLModel.metadata
from app import models  # noqa: E402,F401

# Alembic config + logging
config = context.config
if config.config_file_name:
    fileConfig(config.config_file_name)

target_metadata = SQLModel.metadata


def _get_db_url() -> str:
    """Resolve DB URL from CLI (-x), env, ini, or fallback sqlite."""
    x_args = context.get_x_argument(as_dictionary=True)
    if x_args.get("DB_URL"):
        return x_args["DB_URL"]

    env_url = os.getenv("DATABASE_URL")
    if env_url:
        return env_url

    ini_url = (config.get_main_option("sqlalchemy.url") or "").strip()
    if ini_url and not (ini_url.startswith("${") and ini_url.endswith("}")):
        return ini_url

    return "sqlite:///./dev.db"


def run_migrations_offline():
    url = _get_db_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
        compare_server_default=True,
        render_as_batch=url.startswith("sqlite"),
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    url = _get_db_url()
    if not (config.get_main_option("sqlalchemy.url") or "").strip():
        config.set_main_option("sqlalchemy.url", url)

    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
        future=True,
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
