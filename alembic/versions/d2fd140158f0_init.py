"""init

Revision ID: d2fd140158f0
Revises:
Create Date: 2025-09-30 14:07:17.287416
"""

import sqlalchemy as sa
import sqlmodel

from alembic import op

revision = "d2fd140158f0"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "task",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("title", sqlmodel.sql.sqltypes.AutoString(length=200), nullable=False),
        sa.Column("description", sqlmodel.sql.sqltypes.AutoString(length=2000), nullable=True),
        sa.Column("tag", sqlmodel.sql.sqltypes.AutoString(length=50), nullable=True),
        sa.Column("completed", sa.Boolean(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_task_completed"), "task", ["completed"], unique=False)
    op.create_index(op.f("ix_task_tag"), "task", ["tag"], unique=False)
    op.create_index(op.f("ix_task_title"), "task", ["title"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_task_title"), table_name="task")
    op.drop_index(op.f("ix_task_tag"), table_name="task")
    op.drop_index(op.f("ix_task_completed"), table_name="task")
    op.drop_table("task")
