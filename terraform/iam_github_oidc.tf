# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    # GitHub Actions OIDC root CA thumbprint (RSA 4096 / DigiCert)
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# Deploy role for GitHub Actions
data "aws_iam_policy_document" "gha_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/*",
        "repo:${var.github_owner}/${var.github_repo}:pull_request"
      ]
    }
  }
}

resource "aws_iam_role" "gha_deploy" {
  name               = "${local.name_prefix}-gha-deploy"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
}

# Allow: login to ECR + push/pull, update App Runner service
data "aws_iam_policy_document" "gha_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "apprunner:DescribeService",
      "apprunner:UpdateService",
      "apprunner:ListServices",
      "apprunner:StartDeployment"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gha_policy" {
  name   = "${local.name_prefix}-gha-deploy"
  policy = data.aws_iam_policy_document.gha_policy.json
}

resource "aws_iam_role_policy_attachment" "gha_attach" {
  role       = aws_iam_role.gha_deploy.name
  policy_arn = aws_iam_policy.gha_policy.arn
}
