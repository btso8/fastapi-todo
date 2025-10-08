#!/usr/bin/env bash
set -euo pipefail
CLUSTER="${1:-}"; SERVICE="${2:-}"; CONTAINER="${3:-fastapi-todo}"; NEW_IMAGE="${4:-}"
if [[ -z "$CLUSTER" || -z "$SERVICE" || -z "$NEW_IMAGE" ]]; then
  echo "Usage: $0 <cluster> <service> [container_name] <new_image_uri>"; exit 1; fi
TD_ARN=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" --query "services[0].taskDefinition" --output text)
TD_JSON=$(aws ecs describe-task-definition --task-definition "$TD_ARN" --query "taskDefinition")
echo "$TD_JSON" | jq --arg name "$CONTAINER" --arg image "$NEW_IMAGE"   '.containerDefinitions |= (map(if .name==$name then .image=$image else . end)) |
   del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)' > /tmp/new-td.json
NEW_TD_ARN=$(aws ecs register-task-definition --cli-input-json file:///tmp/new-td.json --query "taskDefinition.taskDefinitionArn" --output text)
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --task-definition "$NEW_TD_ARN"
aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE"
echo "Updated $SERVICE to $NEW_TD_ARN"
