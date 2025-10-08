resource "aws_db_subnet_group" "app" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name    = "${local.name_prefix}-db-subnet-group"
    Project = var.project_name
    Env     = var.environment
  }
}

# Dedicated DB SG
resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "Allow Postgres from ECS service"
  vpc_id      = aws_vpc.this.id

  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}

# allow ECS service -> DB on 5432
resource "aws_vpc_security_group_ingress_rule" "db_from_ecs" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.svc.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Postgres from ECS tasks"
}

# egress all from DB
resource "aws_vpc_security_group_egress_rule" "db_all_out" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_db_instance" "app" {
  identifier                 = "${local.name_prefix}-db"
  engine                     = "postgres"
  engine_version             = "16.3"
  instance_class             = var.db_instance_class
  username                   = var.db_username
  password                   = var.db_password
  db_name                    = var.db_name
  allocated_storage          = var.db_allocated_storage
  publicly_accessible        = true
  vpc_security_group_ids     = [aws_security_group.db.id]
  db_subnet_group_name       = aws_db_subnet_group.app.name
  skip_final_snapshot        = true
  deletion_protection        = false
  backup_retention_period    = 0
  apply_immediately          = true
  auto_minor_version_upgrade = true

  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}
