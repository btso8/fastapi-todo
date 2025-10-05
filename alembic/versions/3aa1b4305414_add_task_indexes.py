"""add task indexes

Revision ID: 3aa1b4305414
Revises: d2fd140158f0
Create Date: 2025-10-05 18:34:10.193830
"""

import sqlalchemy as sa

from alembic import op

revision = "3aa1b4305414"
down_revision = "d2fd140158f0"
branch_labels = None
depends_on = None


def _create_index_if_missing(table: str, name: str, columns: list[str]) -> None:
    bind = op.get_bind()
    insp = sa.inspect(bind)
    existing = {ix["name"] for ix in insp.get_indexes(table)}
    if name not in existing:
        op.create_index(name, table, columns)


def upgrade() -> None:
    _create_index_if_missing("task", "ix_task_completed", ["completed"])
    _create_index_if_missing("task", "ix_task_tag", ["tag"])
    _create_index_if_missing("task", "ix_task_completed_tag", ["completed", "tag"])


def downgrade() -> None:
    for name in ("ix_task_completed_tag", "ix_task_tag", "ix_task_completed"):
        try:
            op.drop_index(name, table_name="task")
        except Exception:
            pass
