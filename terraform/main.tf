terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Helpful naming locals
locals {
  name_prefix = var.project_name
  image_uri   = var.container_image != "" ? var.container_image : "${aws_ecr_repository.app.repository_url}:latest"
}
