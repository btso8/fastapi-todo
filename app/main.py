from __future__ import annotations

import contextvars
import logging
import os
import uuid
from contextlib import asynccontextmanager
from typing import List, Optional

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Query
from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_fastapi_instrumentator.metrics import default, latency
from prometheus_fastapi_instrumentator.metrics import requests as reqs_inprogress
from pydantic import BaseModel, Field
from sqlmodel import Session, create_engine, select
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.json_logging import setup_dual_logging
from app.middleware_limits import MaxBodySizeMiddleware, SimpleRateLimitMiddleware
from app.middleware_security import security_middlewares
from app.migrate_on_startup import run_migrations_if_enabled
from app.models import Task

setup_dual_logging()
logger = logging.getLogger("app")

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./dev.db")

if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, echo=False, connect_args={"check_same_thread": False})
else:
    POOL_SIZE = int(os.getenv("DB_POOL_SIZE", "5"))
    MAX_OVERFLOW = int(os.getenv("DB_MAX_OVERFLOW", "10"))
    POOL_RECYCLE = int(os.getenv("DB_POOL_RECYCLE", "1800"))
    engine = create_engine(
        DATABASE_URL,
        echo=False,
        pool_size=POOL_SIZE,
        max_overflow=MAX_OVERFLOW,
        pool_recycle=POOL_RECYCLE,
        pool_pre_ping=True,
    )


def get_session():
    with Session(engine) as session:
        yield session


class TaskIn(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(default=None, max_length=2000)
    tag: Optional[str] = Field(default=None, max_length=50)


class TaskOut(TaskIn):
    id: int
    completed: bool


_request_id_ctx = contextvars.ContextVar("request_id", default=None)


class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        rid = request.headers.get("x-request-id") or str(uuid.uuid4())
        token = _request_id_ctx.set(rid)
        try:
            response = await call_next(request)
        finally:
            _request_id_ctx.reset(token)
        response.headers["x-request-id"] = rid
        return response


def get_request_id() -> str:
    return _request_id_ctx.get() or ""


@asynccontextmanager
async def lifespan(app: FastAPI):
    run_migrations_if_enabled()
    yield


app = FastAPI(title="FastAPI To-Do (SQLModel + Alembic)", lifespan=lifespan)

for m in security_middlewares():
    opts = getattr(m, "options", None)
    if opts is None:
        opts = getattr(m, "kwargs", {})
    app.add_middleware(m.cls, **opts)


instrumentator = Instrumentator(
    should_instrument_requests_inprogress=True,
    excluded_handlers={"/metrics", "/health"},
    should_respect_env_var=True,
)
instrumentator.add(default())
instrumentator.add(latency(buckets=(50, 100, 200, 300, 500, 1000, 2000, 5000)))
instrumentator.add(reqs_inprogress())
instrumentator.instrument(app).expose(app, include_in_schema=False, should_gzip=True)

app.add_middleware(RequestIDMiddleware)
app.add_middleware(MaxBodySizeMiddleware)
app.add_middleware(SimpleRateLimitMiddleware)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    from time import perf_counter

    start = perf_counter()
    response = await call_next(request)
    duration_ms = (perf_counter() - start) * 1000
    logger.info(
        "request",
        extra={
            "request_id": get_request_id(),
            "path": request.url.path,
            "method": request.method,
            "status_code": response.status_code,
            "duration_ms": round(duration_ms, 2),
            "user_agent": request.headers.get("user-agent", ""),
        },
    )
    return response


@app.middleware("http")
async def relax_csp_for_docs(request: Request, call_next):
    resp = await call_next(request)
    p = request.url.path
    if p.startswith("/docs"):
        resp.headers["Content-Security-Policy"] = (
            "default-src 'none'; "
            "connect-src 'self'; "
            "img-src 'self' data:; "
            "script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; "
            "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net"
        )
    elif p.startswith("/redoc"):
        resp.headers["Content-Security-Policy"] = (
            "default-src 'none'; connect-src 'self'; img-src 'self' data:; "
            "script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; "
            "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net"
        )
    return resp


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.post("/tasks/", response_model=TaskOut, status_code=201)
def create_task(body: TaskIn, session: Session = Depends(get_session)):
    task = Task(**body.model_dump())
    session.add(task)
    session.commit()
    session.refresh(task)
    return task


@app.get("/tasks/", response_model=List[TaskOut])
def list_tasks(
    search: Optional[str] = Query(default=None, description="Search in title/description/tag"),
    tag: Optional[str] = Query(default=None),
    completed: Optional[bool] = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=int(os.getenv("DEFAULT_PAGE_SIZE", "50")), ge=1, le=500),
    session: Session = Depends(get_session),
):
    stmt = select(Task)
    if tag is not None:
        stmt = stmt.where(Task.tag == tag)
    if completed is not None:
        stmt = stmt.where(Task.completed == completed)
    if search:
        s = f"%{search.lower()}%"
        try:
            stmt = stmt.where(
                (Task.title.ilike(s)) | (Task.description.ilike(s)) | (Task.tag.ilike(s))
            )
        except Exception:
            pass
    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    items = session.exec(stmt).all()
    return items


@app.get("/tasks/{task_id}", response_model=TaskOut)
def get_task(task_id: int, session: Session = Depends(get_session)):
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.put("/tasks/{task_id}", response_model=TaskOut)
def update_task(task_id: int, body: TaskIn, session: Session = Depends(get_session)):
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    for k, v in body.model_dump().items():
        setattr(task, k, v)
    session.add(task)
    session.commit()
    session.refresh(task)
    return task


@app.patch("/tasks/{task_id}/complete", response_model=TaskOut)
def complete_task(task_id: int, session: Session = Depends(get_session)):
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    task.completed = True
    session.add(task)
    session.commit()
    session.refresh(task)
    return task


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, session: Session = Depends(get_session)):
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    session.delete(task)
    session.commit()
    return None
