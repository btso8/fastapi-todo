locals {
  create_oidc_role = var.enable_github_oidc_role
}

data "aws_iam_openid_connect_provider" "github" {
  count = local.create_oidc_role ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_oidc_trust" {
  count = local.create_oidc_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:ref:${var.github_ref}"]
    }
  }
}

resource "aws_iam_role" "github_actions_deployer" {
  count              = local.create_oidc_role ? 1 : 0
  name               = var.oidc_role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust[0].json
  description        = "GitHub Actions OIDC deployer for ECS/ECR"
}

data "aws_iam_policy_document" "ecs_ecr_min" {
  count = local.create_oidc_role ? 1 : 0

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
}

resource "aws_iam_role_policy" "ecs_ecr_min" {
  count  = local.create_oidc_role ? 1 : 0
  role   = aws_iam_role.github_actions_deployer[0].id
  policy = data.aws_iam_policy_document.ecs_ecr_min[0].json
}

output "github_actions_role_arn" {
  value       = local.create_oidc_role ? aws_iam_role.github_actions_deployer[0].arn : null
  description = "ARN of the IAM role for GitHub Actions OIDC ECS deployments"
}
