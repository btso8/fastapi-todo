output "region" {
  value = var.region
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "rds_endpoint" {
  value = aws_db_instance.pg.address
}

output "database_url_secret_arn" {
  value = aws_secretsmanager_secret.database_url.arn
}

output "app_runner_service_url" {
  value = aws_apprunner_service.app.service_url
}

output "app_runner_service_arn" {
  value = aws_apprunner_service.app.arn
}

output "ecr_repository" {
  value = aws_ecr_repository.app.name
}

output "ecr_registry" {
  value = aws_ecr_repository.app.repository_url != "" ? split("/", aws_ecr_repository.app.repository_url)[0] : ""
}

output "deploy_role_arn" {
  value = aws_iam_role.gha_deploy.arn
}
