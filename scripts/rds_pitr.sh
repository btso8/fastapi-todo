#!/usr/bin/env bash
set -euo pipefail
# Restore an RDS instance to a point in time (for DR drills).
# Usage:
#   scripts/rds_pitr.sh <source_instance_id> <new_instance_id> <timestamp_utc|"latest"> [region]
SRC="${1:?source instance id required}"
NEW="${2:?new instance id required}"
POINT="${3:?UTC timestamp or 'latest' required}"
REGION="${4:-eu-west-2}"

if [ "$POINT" = "latest" ]; then
  aws rds restore-db-instance-to-point-in-time \
    --region "$REGION" \
    --source-db-instance-identifier "$SRC" \
    --target-db-instance-identifier "$NEW" \
    --use-latest-restorable-time >/dev/null
else
  aws rds restore-db-instance-to-point-in-time \
    --region "$REGION" \
    --source-db-instance-identifier "$SRC" \
    --target-db-instance-identifier "$NEW" \
    --restore-time "$POINT" >/dev/null
fi

echo "Restore started: $NEW. Waiting for 'available'..."
aws rds wait db-instance-available --region "$REGION" --db-instance-identifier "$NEW"

EP=$(aws rds describe-db-instances --region "$REGION" \
      --db-instance-identifier "$NEW" \
      --query 'DBInstances[0].Endpoint.Address' --output text)
PORT=$(aws rds describe-db-instances --region "$REGION" \
      --db-instance-identifier "$NEW" \
      --query 'DBInstances[0].Endpoint.Port' --output text)

echo "DR instance ready:"
echo "  endpoint = $EP"
echo "  port     = $PORT"
echo "postgresql+psycopg://<user>:<pass>@$EP:$PORT/<dbname>?sslmode=require"
