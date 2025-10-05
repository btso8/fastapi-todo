#!/usr/bin/env bash
set -euo pipefail
# Usage: rollback_to_sha.sh <sha_tag> [region] [repo]
SHA_TAG="${1:?Usage: rollback_to_sha.sh <sha_tag> [region] [repo]}"
REGION="${2:-eu-west-2}"
REPO="${3:-btso8/fastapi-todo}"  # ECR repo name (no registry prefix)

# Grab manifest for the old tag and retag it as latest
MANIFEST=$(aws ecr batch-get-image --region "$REGION" \
  --repository-name "$REPO" \
  --image-ids imageTag="$SHA_TAG" \
  --query 'images[0].imageManifest' --output text)

aws ecr put-image --region "$REGION" \
  --repository-name "$REPO" \
  --image-tag latest \
  --image-manifest "$MANIFEST"

echo "Retagged $REPO:$SHA_TAG -> $REPO:latest (App Runner will auto-deploy)"
