#!/usr/bin/env bash
set -euo pipefail
# Usage: scripts/sqlite_backup.sh <db_path> <s3_bucket> [region]
DB="${1:-./dev.db}"
BUCKET="${2:?s3 bucket (no s3://) required}"
REGION="${3:-eu-west-2}"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT="sqlite-$(basename "$DB").$STAMP.gz"
echo "Backing up $DB -> s3://$BUCKET/$OUT"
gzip -c "$DB" | aws s3 cp - "s3://$BUCKET/$OUT" --region "$REGION"
echo "Uploaded s3://$BUCKET/$OUT"
