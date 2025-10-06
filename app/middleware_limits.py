import os
import time

from fastapi import HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

MAX_BYTES = int(os.getenv("MAX_BODY_BYTES", "1048576"))
WINDOW_SECS = int(os.getenv("RL_WINDOW_SECS", "60"))
MAX_REQS = int(os.getenv("RL_MAX_REQS", "120"))

_buckets = {}


class MaxBodySizeMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        cl = request.headers.get("content-length")
        if cl and int(cl) > MAX_BYTES:
            raise HTTPException(status_code=413, detail="Request too large")
        return await call_next(request)


class SimpleRateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        now = int(time.time())
        key = (request.client.host or "unknown", now // WINDOW_SECS)
        _buckets[key] = _buckets.get(key, 0) + 1
        if _buckets[key] > MAX_REQS:
            raise HTTPException(status_code=429, detail="Too Many Requests")
        return await call_next(request)
