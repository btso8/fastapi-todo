# ---- Required for your image ----
# Leave blank to default to ECR repo from this stack + :latest
# container_image = "123456789012.dkr.ecr.eu-west-2.amazonaws.com/fastapi-todo:latest"

project_name = "fastapi-todo"
environment  = "prod"
aws_region   = "eu-west-2"

# ECS sizing
cpu           = 512
memory        = 1024
desired_count = 1
min_capacity  = 1
max_capacity  = 4

# DB credentials (raw values, as requested)
db_username = "todo"
db_password = "change-me-strong"
db_name     = "todo"

# Extra app env (optional)
# extra_env = {
#   FEATURE_FLAG = "on"
# }

container_image = "960096061391.dkr.ecr.eu-west-2.amazonaws.com/fastapi-todo:latest"
