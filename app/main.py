from __future__ import annotations

import os
from typing import List, Optional

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Query
from pydantic import BaseModel, Field
from sqlmodel import Session, SQLModel, create_engine, select

# Your ORM model lives here
from app.models import (  # Task(table=True) with fields: id, title, completed, description?, tag?
    Task,
)

# -----------------------------------------------------------------------------
# DB setup
# -----------------------------------------------------------------------------
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./dev.db")

# Handle special cases depending on backend
engine_kwargs = {}

if DATABASE_URL.startswith("sqlite"):
    # SQLite requires this for multithreaded FastAPI
    engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(DATABASE_URL, echo=False, **engine_kwargs)


def get_session():
    with Session(engine) as session:
        yield session


# -----------------------------------------------------------------------------
# Pydantic I/O models (DTOs)
# -----------------------------------------------------------------------------
class TaskIn(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(default=None, max_length=2000)
    tag: Optional[str] = Field(default=None, max_length=50)


class TaskOut(TaskIn):
    id: int
    completed: bool


# -----------------------------------------------------------------------------
# App + routes
# -----------------------------------------------------------------------------
app = FastAPI(title="FastAPI To-Do")


@app.on_event("startup")
def init_db():
    if DATABASE_URL.startswith("sqlite"):
        SQLModel.metadata.create_all(engine)


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
    # Start with a basic select; build WHEREs if you prefer DB-side filtering
    stmt = select(Task)
    items = session.exec(stmt).all()

    # Lightweight Python-side filtering (fine for small dev datasets)
    if search:
        s = search.lower()
        items = [
            t
            for t in items
            if s in (t.title or "").lower() or s in (t.description or "").lower()
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
