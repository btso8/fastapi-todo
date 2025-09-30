# FastAPI To‑Do (Weeks 1–4)

A learning project that builds a To‑Do API over four weeks.

## Weeks 1–2 (Bootstrap)
- **FastAPI skeleton** with `/health`
- **Repo hygiene**: `.gitignore`, `pyproject.toml`
- **Dockerfile** to containerize the app
- **GitHub Actions CI**: install deps, run tests, run Alembic upgrade (SQLite)
- **Docs**: initial user stories
- **Infra scaffold**: `infra/main.tf` placeholder for AWS

## Weeks 3–4 (Data + CRUD)
- **SQLModel** `Task` model
- **DB session mgmt** (`app/db.py`), lifespan startup
- **CRUD endpoints**: `/tasks` (create, list, get, update, delete)
- **Alembic** configured (env‑driven `DATABASE_URL`)
- **Initial migration** included for portability
- **docker-compose** with Postgres 16 for local dev
- **Tests** for core flow

---

## Quickstart (SQLite)

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

export DATABASE_URL=sqlite:///./dev.db
alembic upgrade head  # applies included migration

uvicorn app.main:app --reload
# http://127.0.0.1:8000/docs
```

## Postgres (Docker)

```bash
docker compose up -d db
export DATABASE_URL=postgresql+psycopg://todo:todo@localhost:5432/todo
alembic upgrade head
uvicorn app.main:app --reload
```

## Tests

```bash
pytest -q
```

## Environment
- `DATABASE_URL` is read by Alembic and the app.
  - SQLite: `sqlite:///./dev.db`
  - Postgres: `postgresql+psycopg://USER:PASS@HOST:PORT/DB`

## CI
GitHub Actions runs on push/PR to `main`: installs Python 3.12, caches deps,
sets `DATABASE_URL=sqlite:///./dev.db`, applies Alembic upgrade, and runs tests.
