variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "project_name" {
  type    = string
  default = "fastapi-todo"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "container_name" {
  type    = string
  default = "fastapi-todo"
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 4
}

variable "cpu" {
  description = "Fargate CPU units (eg 256, 512, 1024)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Fargate Memory (MB) (eg 1024, 2048)"
  type        = number
  default     = 1024
}

variable "container_image" {
  type    = string
  default = ""
}

variable "extra_env" {
  description = "Extra environment variables to inject into the container"
  type        = map(string)
  default     = {}
}

variable "db_username" {
  type    = string
  default = "todo"
}

variable "db_password" {
  type      = string
  default   = "change-me-strong"
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "todo"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "enable_github_oidc_role" {
  description = "Whether to create a GitHub OIDC IAM role for ECS deployments"
  type        = bool
  default     = true
}

variable "github_owner" {
  description = "GitHub username or organization (e.g., brandon-oliver)"
  type        = string
  default     = "brandon-oliver"
}

variable "github_repo" {
  description = "GitHub repository name (e.g., test-project)"
  type        = string
  default     = "test-project"
}

variable "github_ref" {
  description = "GitHub ref filter for OIDC (e.g., refs/heads/main or refs/heads/*)"
  type        = string
  default     = "refs/heads/main"
}

variable "github_sub_wildcard" {
  type        = bool
  description = "Also allow all refs for this repo (repo:owner/repo:*)"
  default     = false
}

variable "oidc_role_name" {
  description = "Name of the IAM role to create for GitHub Actions"
  type        = string
  default     = "github-actions-oidc-ecs-deployer"
}
