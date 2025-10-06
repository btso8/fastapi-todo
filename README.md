# FastAPI To-Do (SQLModel + Alembic) — Cloud-native Demo

Production-grade FastAPI app with CI/CD to AWS App Runner, observability, security scanning, and operational runbooks.

## TL;DR
- **Deploys:** Merge to `main` → image pushed to ECR as `:latest` → App Runner auto-deploys.
- **Observe:** Prometheus `/metrics`, CloudWatch dashboard + alarms, 10-min canary.
- **Secure:** Security CI (pip-audit, Bandit, Hadolint, Trivy), Gitleaks, Dependabot, SBOM on releases.
- **Operate:** Rollback via `scripts/rollback_to_sha.sh <sha>`, DR runbooks & RDS PITR helper.

---

## Architecture
- **API:** FastAPI + SQLModel; Gunicorn+Uvicorn workers.
- **DB:** SQLite (dev) or Postgres (prod).
- **Infra:** AWS App Runner (container) + ECR.
- **Obs:** `prometheus_fastapi_instrumentator` → `/metrics`, CloudWatch alarms/dashboards, structured logs.
- **Security:** HTTP headers + CORS middleware; CI scanners; SBOM on tag.

---

## Local Dev
```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export DATABASE_URL=sqlite:///./dev.db
alembic upgrade head
uvicorn app.main:app --reload
