resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name_prefix}-td"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = local.image_uri
      essential = true

      portMappings = [
        { containerPort = var.container_port, protocol = "tcp" }
      ]

      environment = concat(
        [
          { name = "APP_ENV", value = var.environment },
          {
            name  = "DATABASE_URL",
            value = "postgresql+psycopg://${var.db_username}:${var.db_password}@${aws_db_instance.app.address}:5432/${var.db_name}"
          }
        ],
        [for k, v in var.extra_env : { name = k, value = v }]
      )

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = local.name_prefix
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "python - <<'PY'\nimport sys, urllib.request\ntry:\n  urllib.request.urlopen('http://localhost:${var.container_port}/health', timeout=3)\nexcept Exception:\n  sys.exit(1)\nPY"
        ]
        interval = 30
        timeout  = 5
        retries  = 3
      }
    }
  ])

  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}

resource "aws_ecs_service" "app" {
  name             = "${local.name_prefix}-svc"
  cluster          = aws_ecs_cluster.this.arn
  task_definition  = aws_ecs_task_definition.app.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    assign_public_ip = true
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.svc.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Project = var.project_name
    Env     = var.environment
  }

  depends_on = [aws_lb_listener.http]
}
