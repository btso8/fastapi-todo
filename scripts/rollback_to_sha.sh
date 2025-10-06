#!/usr/bin/env bash
set -euo pipefail
# Usage: rollback_to_sha.sh <sha_tag> [region] [repository_name]
# Example: ./scripts/rollback_to_sha.sh 1a2b3c4 eu-west-2 btso8/fastapi-todo
SHA_TAG="${1:?Usage: rollback_to_sha.sh <sha_tag> [region] [repository_name]}"
REGION="${2:-eu-west-2}"
REPO="${3:-btso8/fastapi-todo}"  # ECR "repositoryName" (no registry prefix)

echo "Rolling back ECR $REPO:latest to tag $SHA_TAG in $REGION"
MANIFEST=$(aws ecr batch-get-image --region "$REGION" \
  --repository-name "$REPO" \
  --image-ids imageTag="$SHA_TAG" \
  --query 'images[0].imageManifest' --output text)

if [ -z "$MANIFEST" ] || [ "$MANIFEST" = "None" ]; then
  echo "Tag not found: $REPO:$SHA_TAG"; exit 1
fi

aws ecr put-image --region "$REGION" \
  --repository-name "$REPO" \
  --image-tag latest \
  --image-manifest "$MANIFEST" >/dev/null

echo "Retagged $REPO:$SHA_TAG -> $REPO:latest"
echo "App Runner (tracking :latest) will auto-deploy."
