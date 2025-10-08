#!/usr/bin/env bash
set -euo pipefail
IMAGE_URI="${1:-}"
CONTEXT="${2:-.}"
if [[ -z "$IMAGE_URI" ]]; then echo "Usage: $0 <image_uri> [context]"; exit 1; fi
AWS_REGION="${AWS_REGION:-eu-west-2}"
docker build -t "$IMAGE_URI" "$CONTEXT"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$(echo "$IMAGE_URI" | awk -F/ '{print $1}')"
docker push "$IMAGE_URI"
