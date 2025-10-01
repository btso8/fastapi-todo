import pytest
from fastapi.testclient import TestClient
from prometheus_client import REGISTRY
from sqlmodel import Session, SQLModel, create_engine

from app.main import app, get_session


@pytest.fixture(autouse=True, scope="function")
def reset_metrics_registry():
    """Reset Prometheus collectors between tests (testing only)."""
    collectors = list(getattr(REGISTRY, "_collector_to_names", {}).keys())
    for c in collectors:
        try:
            REGISTRY.unregister(c)
        except KeyError:
            pass


@pytest.fixture(scope="session")
def tmp_db_url(tmp_path_factory):
    # Use a file-backed SQLite so the app + test client share the same DB
    db_file = tmp_path_factory.mktemp("db") / "test.db"
    return f"sqlite:///{db_file}"


@pytest.fixture(scope="session")
def engine(tmp_db_url):
    # Create engine for the tests
    engine = create_engine(tmp_db_url, echo=False)
    # Build schema once for the test session
    SQLModel.metadata.create_all(engine)
    return engine


@pytest.fixture(scope="function")
def session(engine):
    # Fresh transactional session for each test function
    with Session(engine) as s:
        yield s
        s.rollback()  # just in case


@pytest.fixture(scope="function")
def test_client(session, tmp_db_url, monkeypatch):
    """
    Override the app's get_session dependency to use our test Session.
    Also make sure anything reading DATABASE_URL (if your app does) points
    at the test DB.
    """
    # Point the app's env var to the test DB (harmless if unused)
    monkeypatch.setenv("DATABASE_URL", tmp_db_url)

    def _override_get_session():
        yield session

    app.dependency_overrides[get_session] = _override_get_session
    client = TestClient(app)
    try:
        yield client
    finally:
        app.dependency_overrides.clear()
