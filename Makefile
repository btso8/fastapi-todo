.PHONY: dev test lint fmt migrate-new migrate-up migrate-down up down logs

# -------- Python local --------
dev:
	uvicorn app.main:app --reload

test:
	pytest -q

lint:
	ruff check .
	black --check .
	isort --check-only .

fmt:
	ruff check . --fix
	black .
	isort .

# -------- Alembic --------
migrate-new:
	@if [ -z "$(m)" ]; then echo "Usage: make migrate-new m='message'"; exit 1; fi
	alembic revision --autogenerate -m "$(m)"

migrate-up:
	alembic upgrade head

migrate-down:
	alembic downgrade -1

# -------- Docker Compose (Postgres + API) --------
up:
	docker compose up -d

down:
	docker compose down -v

logs:
	docker compose logs -f
