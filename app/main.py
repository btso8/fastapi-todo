from __future__ import annotations

import logging
import os
from contextlib import asynccontextmanager
from typing import List, Optional

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Query
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel, Field
from sqlmodel import Session, create_engine, select

from app.json_logging import setup_dual_logging
from app.migrate_on_startup import run_migrations_if_enabled
from app.models import Task

# -------------------------------------------------------------------
# Logging setup
# -------------------------------------------------------------------
setup_dual_logging()
logger = logging.getLogger("app")

# -------------------------------------------------------------------
# DB setup
# -------------------------------------------------------------------
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./dev.db")
engine = create_engine(DATABASE_URL, echo=False)


def get_session():
    with Session(engine) as session:
        yield session


# -------------------------------------------------------------------
# Pydantic DTOs
# -------------------------------------------------------------------
class TaskIn(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(default=None, max_length=2000)
    tag: Optional[str] = Field(default=None, max_length=50)


class TaskOut(TaskIn):
    id: int
    completed: bool


# -------------------------------------------------------------------
# Lifespan: run migrations before serving
# -------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    run_migrations_if_enabled()
    yield


app = FastAPI(title="FastAPI To-Do (SQLModel + Alembic)", lifespan=lifespan)

# Instrumentation
instrumentator = Instrumentator().instrument(app)
instrumentator.expose(app, include_in_schema=False)


# -------------------------------------------------------------------
# Middleware + routes
# -------------------------------------------------------------------
@app.middleware("http")
async def log_requests(request, call_next):
    from time import perf_counter

    start = perf_counter()
    response = await call_next(request)
    duration_ms = (perf_counter() - start) * 1000
    logger.info(
        "request",
        extra={
            "path": request.url.path,
            "method": request.method,
            "status_code": response.status_code,
            "duration_ms": round(duration_ms, 2),
        },
    )
    return response


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
    search: Optional[str] = Query(default=None),
    tag: Optional[str] = Query(default=None),
    completed: Optional[bool] = Query(default=None),
    session: Session = Depends(get_session),
):
    stmt = select(Task)
    items = session.exec(stmt).all()
    if search:
        s = search.lower()
        items = [
            t
            for t in items
            if s in (t.title or "").lower()
            or s in (t.description or "").lower()
            or s in (t.tag or "").lower()
        ]
    if tag is not None:
        items = [t for t in items if t.tag == tag]
    if completed is not None:
        items = [t for t in items if t.completed == completed]
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
