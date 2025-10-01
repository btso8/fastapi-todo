# FastAPI To-Do App

A simple **FastAPI + SQLModel** to-do service with **SQLite/Postgres support**, **Alembic migrations**, **Docker Compose**, and **CI**.

## Features
- CRUD API for tasks (`/tasks`).
- Works with **SQLite** (local dev) or **Postgres** (prod / Docker).
- **Alembic** for database migrations.
- **Dockerfile** + **docker-compose.yml** for containerized dev.
- **Makefile** shortcuts for common commands.
- **Pre-commit** hooks (Ruff, Black, isort).
- **GitHub Actions CI** with lint + migrations + tests.

---

## Quickstart (Local Dev)

1. Clone and enter project
   ```bash
   git clone <your-repo-url>
   cd test-project
   ```

2. Create virtual environment
   ```bash
   python3.12 -m venv .venv
   source .venv/bin/activate
   ```

3. Install dependencies
   ```bash
   make install-dev
   ```

4. Run the app (SQLite by default)
   ```bash
   make dev
   ```
   → Open <http://127.0.0.1:8000/docs>

---

## Database Setup

### Using SQLite (default)
`.env.example`:
```env
DATABASE_URL=sqlite:///./dev.db
```
Tables auto-create on startup.

### Using Postgres (local)
Start DB:
```bash
docker compose up -d db
```
`.env`:
```env
DATABASE_URL=postgresql+psycopg://todo:todo@localhost:5432/todo
```
Run migrations:
```bash
make migrate-up
```

### Using Postgres (in Docker network)
If app runs inside `docker-compose`, use:
```env
DATABASE_URL=postgresql+psycopg://todo:todo@db:5432/todo
```

---

## Migrations

- New migration:
  ```bash
  make migrate-new m="add field"
  ```
- Apply latest:
  ```bash
  make migrate-up
  ```
- Roll back one:
  ```bash
  make migrate-down
  ```

---

## Makefile Commands

| Command                   | Description                         |
|----------------------------|-------------------------------------|
| `make install-dev`         | Install runtime + dev deps          |
| `make install-prod`        | Install runtime deps only           |
| `make dev`                 | Run FastAPI in dev mode             |
| `make test`                | Run pytest with coverage            |
| `make lint`                | Run Ruff/Black/isort checks         |
| `make fmt`                 | Auto-format code                    |
| `make migrate-new m="msg"` | Create new Alembic migration        |
| `make migrate-up`          | Apply migrations                    |
| `make migrate-down`        | Roll back one migration             |
| `make up`                  | Start Docker Compose (API + DB)     |
| `make down`                | Stop and remove Docker Compose      |
| `make logs`                | Follow Docker logs                  |

---

## Pre-commit Hooks

Install once:
```bash
pre-commit install
```

Run on all files:
```bash
pre-commit run --all-files
```

---

## Docker Usage

Build & run app + Postgres:
```bash
make up
```
→ API: <http://localhost:8000/docs>
→ DB: `localhost:5432` (`todo:todo` / `todo`)

Stop & clean:
```bash
make down
```

---

## CI (GitHub Actions)

- Installs runtime + dev deps.
- Runs **Ruff/Black/isort** checks.
- Runs `alembic upgrade head` against SQLite.
- Runs **pytest**.

---

## Health Check

- `/health` → returns `{ "status": "ok" }`

---

## Requirements

- Python 3.12+
- SQLite (built-in) or Postgres 16
- Docker
