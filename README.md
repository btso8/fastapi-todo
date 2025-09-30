
# FastAPI To-Do App

A modern **To-Do API** built with **FastAPI**, **SQLModel**, and **Alembic** for migrations.  
Includes full CRUD endpoints, search and filter support, and a pytest-based test suite.  

---

## ✨ Features

- Create, read, update, complete, and delete tasks  
- Filtering by search term, tag, and completion status  
- Database migrations with Alembic  
- SQLite for local dev, PostgreSQL-ready for production  
- `.env` support for configuration  
- pytest test suite with isolated DB  
- Clean `.gitignore` (ignores `.venv`, `.env`, caches, Docker, Terraform files, etc.)

---

## 📂 Project Structure

```
.
├── app/
│   ├── main.py         # FastAPI entrypoint + routes
│   ├── models.py       # SQLModel Task model
│   ├── db.py           # Database session helpers
│   └── ...
├── alembic/
│   ├── env.py          # Alembic config
│   ├── script.py.mako  # Migration template
│   └── versions/       # Migration history
├── tests/
│   ├── conftest.py     # Test DB + overrides
│   └── test_tasks.py   # Task API test suite
├── dev.db              # Local SQLite DB (ignored in git)
├── .env                # Environment variables (ignored in git)
├── .gitignore
├── pyproject.toml      # Dependencies/config
└── README.md
```

---

## 🚀 Getting Started

### 1. Clone & Setup
```bash
git clone <your-repo-url>
cd test-project

# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

---

### 2. Configure Environment

Create a `.env` file in the project root:

```dotenv
DATABASE_URL=sqlite:///./dev.db
# Or Postgres:
# DATABASE_URL=postgresql+psycopg://user:password@localhost:5432/tododb
```

---

### 3. Run Migrations
```bash
alembic upgrade head
```

---

### 4. Run the App
```bash
uvicorn app.main:app --reload
```

API docs available at:  
➡️ http://127.0.0.1:8000/docs

---

## 🧪 Running Tests

```bash
pytest -q
```

Covers:

- Healthcheck  
- Create & retrieve tasks  
- Filtering (search, tags, completed)  
- Update & complete tasks  
- Delete & 404 errors  

Tests run against a **temporary SQLite DB**, so `dev.db` is not affected.

---

## 📌 Example API Usage

Create a new task:
```bash
curl -X POST http://127.0.0.1:8000/tasks/   -H "Content-Type: application/json"   -d '{"title": "Buy milk", "tag": "home"}'
```

List all tasks:
```bash
curl http://127.0.0.1:8000/tasks/
```

Get a task by ID:
```bash
curl http://127.0.0.1:8000/tasks/1
```

Update a task:
```bash
curl -X PUT http://127.0.0.1:8000/tasks/1   -H "Content-Type: application/json"   -d '{"title": "Buy oat milk", "tag": "home"}'
```

Mark a task complete:
```bash
curl -X PATCH http://127.0.0.1:8000/tasks/1/complete
```

Delete a task:
```bash
curl -X DELETE http://127.0.0.1:8000/tasks/1
```

---

---

## 📌 Roadmap

- ✅ Alembic migrations working  
- ✅ Full pytest test suite  
- ✅ Example API usage in README  
- 🔜 JWT authentication  
- 🔜 Dockerfile + Compose  
- 🔜 Terraform infra  
- 🔜 CI/CD pipeline  
