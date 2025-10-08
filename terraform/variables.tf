variable "project_name" {
  type        = string
  description = "Project/system name (e.g., fastapi-todo)"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name (dev/stage/prod)"
}

variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS region"
}

variable "github_owner" {
  type        = string
  description = "GitHub org or username for OIDC"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name for OIDC"
}

variable "alert_email" {
  type        = string
  description = "Email address to receive alerts"
}

variable "db_username" {
  type        = string
  default     = "todo"
  description = "Postgres username"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t4g.micro"
  description = "RDS instance class (free-tier friendly)"
}

variable "allocated_storage_gb" {
  type        = number
  default     = 20
  description = "RDS storage in GB"
}

variable "use_private_ecr_image" {
  type        = bool
  default     = false
  description = "If true, App Runner uses your private ECR repo image:latest; otherwise uses a public placeholder image"
}

variable "apprunner_port" {
  type        = number
  default     = 8000
  description = "Container port exposed by your app (for health check/traffic)"
}

variable "apprunner_cpu" {
  type        = string
  default     = "0.25 vCPU"
  description = "App Runner CPU (e.g., 0.25 vCPU, 0.5 vCPU, 1 vCPU, 2 vCPU, 4 vCPU)"
}

variable "apprunner_memory" {
  type        = string
  default     = "0.5 GB"
  description = "App Runner Memory (e.g., 0.5 GB, 1 GB, 2 GB, 3 GB, 4 GB, 8 GB)"
}

variable "budget_monthly_limit" {
  type        = number
  default     = 10
  description = "Monthly budget limit for alerting"
}
