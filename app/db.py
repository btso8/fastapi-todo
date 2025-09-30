import os
from contextlib import contextmanager

from sqlmodel import Session, SQLModel, create_engine

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./dev.db")

# pool_pre_ping helps with recycled connections; echo=False keeps logs clean
engine = create_engine(DATABASE_URL, echo=False, pool_pre_ping=True)


def init_db() -> None:
    # Only used for SQLite local quickstart (Alembic handles Postgres schema)
    if DATABASE_URL.startswith("sqlite"):
        SQLModel.metadata.create_all(engine)


@contextmanager
def get_session():
    with Session(engine) as session:
        yield session
