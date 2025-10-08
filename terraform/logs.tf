resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 14

  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}
