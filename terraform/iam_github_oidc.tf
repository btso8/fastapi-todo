data "aws_caller_identity" "current" {}

locals {
  github_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_deployer" {
  name               = var.oidc_role_name
  description        = "GitHub Actions OIDC deployer for ECS/ECR"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
}

data "aws_iam_policy_document" "ecs_ecr_min" {
  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:DescribeRepositories"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:ListTaskDefinitions",
      "ecs:ListServices",
      "ecs:ListTasks",
      "ecs:DescribeTasks"
    ]
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/fastapi-todo-*"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_ecr_min" {
  role   = aws_iam_role.github_actions_deployer.name
  policy = data.aws_iam_policy_document.ecs_ecr_min.json
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_deployer.arn
  description = "ARN of the IAM role for GitHub Actions OIDC ECS deployments"
}
