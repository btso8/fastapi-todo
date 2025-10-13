FROM python:3.14-slim AS base

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements.txt .
RUN python -m pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip install gunicorn uvicorn   # make sure server deps are present

COPY . .

COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

ENV WEB_CONCURRENCY=2

EXPOSE 8000
CMD ["/app/entrypoint.sh"]
