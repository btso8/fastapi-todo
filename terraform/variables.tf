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

# Container settings
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

# Leave blank to default to ECR repo created by this stack
variable "container_image" {
  type    = string
  default = ""
}

# Extra environment variables to inject into the container
variable "extra_env" {
  type    = map(string)
  default = {}
}

# RDS config
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
