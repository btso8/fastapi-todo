# ECS Fargate Migration (HTTP-only, no AWS Secrets)

This package replaces App Runner with **ECS on Fargate** behind a public **ALB (HTTP :80)**.
- No Route 53, no HTTPS
- No Secrets Manager (all env vars are plain values via ECS task definition)
- CloudWatch logs + basic alarms + autoscaling (CPU target 60%, min/max configurable)
- GitHub Actions OIDC workflow for build/push/deploy

## Quick Start

1) **Terraform init and create ECR**
```bash
cd terraform
terraform init
terraform apply -target=aws_ecr_repository.app -auto-approve
```

2) **Build & push the image**
```bash
REPO=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region)
docker build -t ${REPO}:latest -f ../Dockerfile ..
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${REPO%%/*}"
docker push ${REPO}:latest
sed -i 's#^container_image *=.*#container_image = "'"$REPO"':latest"#' terraform.tfvars
terraform apply -auto-approve

```

3) **Fill `terraform.tfvars`**
- Set `container_image = "<ECR_URL>:latest"`
- Fill your `DATABASE_URL` host if you use a DB.

4) **Deploy stack**
```bash
terraform -chdir=terraform apply -auto-approve
```

5) **Open the app**
```
http://$(terraform -chdir=terraform output -raw alb_dns_name)
```

## CI/CD (GitHub Actions)
- Terraform creates an OIDC role and outputs `github_oidc_role_arn`.
- Add it in your GitHub repo **Secrets** as `AWS_GITHUB_OIDC_ROLE_ARN`.
- Push to `main` to build+push and blue/green update the ECS service.

---
