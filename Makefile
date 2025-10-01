.PHONY: install-dev install-prod dev test lint fmt coverage migrate-new migrate-up migrate-down up down logs help

install-prod: ## Install runtime deps
	pip install -r requirements.txt

install-dev: ## Install runtime + dev deps
	pip install -r requirements.txt -r requirements-dev.txt

dev: ## Run FastAPI in dev mode
	uvicorn app.main:app --reload

test: ## Run pytest with coverage (threshold is set in pyproject)
	pytest

coverage: ## Generate HTML coverage report in htmlcov/
	pytest --cov=app --cov-report=html

lint: ## Run linters
	ruff check .
	black --check .
	isort --check-only .

fmt: ## Auto-format code
	ruff check . --fix
	black .
	isort .

migrate-new: ## Create new Alembic migration, pass m="message"
	@if [ -z "$(m)" ]; then echo "Usage: make migrate-new m='message'"; exit 1; fi
	alembic revision --autogenerate -m "$(m)"

migrate-up: ## Apply latest migrations
	alembic upgrade head

migrate-down: ## Roll back one migration
	alembic downgrade -1

up: ## Start Docker Compose (API + DB)
	docker compose up -d

down: ## Stop and remove Docker Compose
	docker compose down -v

logs: ## Tail Docker logs
	docker compose logs -f

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?##' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
