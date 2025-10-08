resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&()*+,-.:;<=>?[]^_{|}~" # excludes / @ " and space
}

resource "aws_db_subnet_group" "pg" {
  name       = "${local.name_prefix}-pg-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "pg" {
  identifier        = "${local.name_prefix}-pg"
  engine            = "postgres"
  engine_version    = "16.4"
  instance_class    = var.db_instance_class
  allocated_storage = var.allocated_storage_gb
  storage_encrypted = true

  db_name  = replace(var.project_name, "-", "")
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.pg.name
  multi_az               = false
  publicly_accessible    = false

  deletion_protection = false
  skip_final_snapshot = true

  backup_retention_period = 0

  apply_immediately = true

  lifecycle {
    ignore_changes = [engine_version]
  }

  tags = {
    Name = "${local.name_prefix}-pg"
  }
}

# Secrets Manager: store a single-string DATABASE_URL
resource "aws_secretsmanager_secret" "database_url" {
  name = "${local.name_prefix}/DATABASE_URL"
}

locals {
  db_url = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.pg.address}:${aws_db_instance.pg.port}/${aws_db_instance.pg.db_name}?sslmode=require"
}

resource "aws_secretsmanager_secret_version" "database_url_v" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = local.db_url
}
