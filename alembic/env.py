from __future__ import annotations

import os
import sys
from pathlib import Path
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

from dotenv import load_dotenv

load_dotenv()  # this loads .env into os.environ


# -------------------------------------------------------------------
# Make sure we can import your app package (supports root or src layout)
#   Project structure expected at runtime:
#     <project>/
#       alembic/
#         env.py  <-- this file
#       app/      <-- your package (or inside src/app)
# -------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = PROJECT_ROOT / "src"

# Add PROJECT_ROOT
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))
# Also add ./src if it exists (so "from app import ..." works in src layout)
if SRC_DIR.exists() and str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

# ---- Import your models' metadata ----
from app.models import SQLModel  # adjust if your module is named differently

target_metadata = SQLModel.metadata
# --------------------------------------

# Alembic Config object, provides access to the .ini file values
config = context.config

# Configure Python logging via the config file, if present
if config.config_file_name is not None:
    fileConfig(config.config_file_name)


def _get_db_url() -> str:
    # 1) Env var from OS or .env
    env_url = os.getenv("DATABASE_URL")
    if env_url:
        return env_url

    # 2) Try alembic.ini [alembic] sqlalchemy.url
    ini_url = config.get_main_option("sqlalchemy.url") or ""
    ini_url = ini_url.strip()
    if ini_url and not (ini_url.startswith("${") and ini_url.endswith("}")):
        return ini_url

    # 3) Default fallback
    return "sqlite:///./dev.db"


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = _get_db_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    url = _get_db_url()

    # Build a minimal config dict; avoids needing full ini plumbing
    connectable = engine_from_config(
        {"sqlalchemy.url": url},
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=True,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
