#!/usr/bin/env bash
set -euo pipefail
# Usage: scripts/sqlite_restore.sh <s3_key> <dest_db_path> <s3_bucket> [region]
KEY="${1:?s3 object key required}"
DEST="${2:-./dev_restored.db}"
BUCKET="${3:?s3 bucket required}"
REGION="${4:-eu-west-2}"
echo "Restoring s3://$BUCKET/$KEY -> $DEST"
aws s3 cp "s3://$BUCKET/$KEY" - --region "$REGION" | gunzip > "$DEST"
echo "Restored to $DEST"
