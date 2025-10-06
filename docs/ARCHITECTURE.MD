```mermaid
flowchart LR
    client[User/Client] -->|HTTPS| apprunner[App Runner: Todo API]
    apprunner -->|SQL| rds[(RDS Postgres)]
    apprunner -->|Logs| cloudwatch[(CloudWatch Logs)]
    apprunner -->|Secrets read| secrets[(Secrets Manager)]
    gh[GitHub Actions] -->|OIDC AssumeRole| aws[IAM Role (ECR Push)]
    gh -->|docker push| ecr[ECR]
    apprunner -->|pull image| ecr
