#!/usr/bin/env sh
set -e

echo "Running migrations..."
alembic upgrade head || echo "Migrations failed or already applied."

echo "Starting app with Gunicorn (workers=${WEB_CONCURRENCY:-2})..."
exec gunicorn \
  -k uvicorn.workers.UvicornWorker \
  -w "${WEB_CONCURRENCY:-2}" \
  -b 0.0.0.0:8000 \
  --access-logfile - \
  --error-logfile - \
  app.main:app
