from typing import Optional

from sqlmodel import Field, SQLModel


class Task(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str = Field(index=True, max_length=200)
    description: Optional[str] = Field(default=None, max_length=2000)
    tag: Optional[str] = Field(default=None, index=True, max_length=50)
    completed: bool = Field(default=False, index=True)
