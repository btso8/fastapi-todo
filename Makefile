.PHONY: install-dev install-prod dev test lint fmt coverage migrate-new migrate-up migrate-down up down logs help

install-prod:
	pip install -r requirements.txt

install-dev:
	pip install -r requirements.txt -r requirements-dev.txt

dev:
	uvicorn app.main:app --reload

test:
	pytest

coverage:
	pytest --cov=app --cov-report=html

lint:
	ruff check .
	black --check .
	isort --check-only .

fmt:
	ruff check . --fix
	black .
	isort .

migrate-new:
	@if [ -z "$(m)" ]; then echo "Usage: make migrate-new m='message'"; exit 1; fi
	alembic revision --autogenerate -m "$(m)"

migrate-up:
	alembic upgrade head

migrate-down:
	alembic downgrade -1

up:
	docker compose up -d

down:
	docker compose down -v

logs:
	docker compose logs -f

help:
	@grep -E '^[a-zA-Z_-]+:.*?##' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
