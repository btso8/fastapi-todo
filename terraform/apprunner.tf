# --- Choose image based on phase ---
locals {
  public_placeholder_image = "public.ecr.aws/docker/library/nginx:alpine"
  private_ecr_image        = "${aws_ecr_repository.app.repository_url}:latest"
  chosen_image             = var.use_private_ecr_image ? local.private_ecr_image : local.public_placeholder_image
}

# --- App Runner service (TEMP: egress DEFAULT, no VPC connector) ---
resource "aws_apprunner_service" "app" {
  service_name = "${local.name_prefix}-svc"

  source_configuration {
    image_repository {
      image_repository_type = var.use_private_ecr_image ? "ECR" : "ECR_PUBLIC"
      image_identifier      = local.chosen_image

      image_configuration {
        port = tostring(var.apprunner_port)

        # maps not list-of-objects
        runtime_environment_variables = {
          UVICORN_WORKERS = "2"
        }

        runtime_environment_secrets = {
          DATABASE_URL = aws_secretsmanager_secret.database_url.arn
        }
      }
    }

    auto_deployments_enabled = true

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_service.arn
    }
  }

  instance_configuration {
    instance_role_arn = aws_iam_role.apprunner_instance.arn
    cpu               = var.apprunner_cpu
    memory            = var.apprunner_memory
  }

  # TEMP: No VPC connector until App Runner is initialized in the account.
  network_configuration {
    egress_configuration {
      egress_type = "DEFAULT"
    }
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 1
    unhealthy_threshold = 5
    interval            = 10
    timeout             = 5
  }

  observability_configuration {
    observability_enabled = true
  }

  tags = {
    Name = "${local.name_prefix}-apprunner"
  }

  depends_on = [
    aws_secretsmanager_secret_version.database_url_v
  ]
}
