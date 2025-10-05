FROM python:3.12-slim AS base

# Fast, quiet, no .pyc, unbuffered logs
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install runtime deps
COPY requirements.txt .
# Ensure pip is modern, then install your deps
RUN python -m pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip install gunicorn uvicorn   # make sure server deps are present

# App code
COPY . .

# Entrypoint script
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# Default worker count; override in App Runner env if needed
ENV WEB_CONCURRENCY=2

EXPOSE 8000
CMD ["/app/entrypoint.sh"]
