# App Runner service role for ECR access (managed policy)
resource "aws_iam_role" "apprunner_service" {
  name = "${local.name_prefix}-apprunner-service"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "build.apprunner.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_service.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# Instance role to read Secrets Manager
resource "aws_iam_role" "apprunner_instance" {
  name = "${local.name_prefix}-apprunner-instance"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "tasks.apprunner.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "apprunner_instance_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = [
      aws_secretsmanager_secret.database_url.arn,
      # KMS key is AWS managed for Secrets Manager by default; kms:Decrypt on "*" is safest minimal for managed.
      "*"
    ]
  }
}

resource "aws_iam_policy" "apprunner_instance_policy" {
  name   = "${local.name_prefix}-apprunner-instance"
  policy = data.aws_iam_policy_document.apprunner_instance_policy.json
}

resource "aws_iam_role_policy_attachment" "apprunner_instance_attach" {
  role       = aws_iam_role.apprunner_instance.name
  policy_arn = aws_iam_policy.apprunner_instance_policy.arn
}
