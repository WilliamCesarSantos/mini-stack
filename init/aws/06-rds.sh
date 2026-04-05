#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 06-rds.sh  –  RDS initialization (Aurora PostgreSQL)
#
# MiniStack spins up a real PostgreSQL Docker container and
# returns the actual host:port endpoint via the AWS API.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --no-cli-pager --endpoint-url=http://localhost:4566 --region us-east-1"
INSTANCE_ID="ministack-postgres"
DB_NAME="ministack"
DB_USER="admin"
DB_PASS="admin123"

echo ">>> [RDS] Creating PostgreSQL instance '$INSTANCE_ID'..."
$AWS rds create-db-instance \
  --db-instance-identifier "$INSTANCE_ID" \
  --db-instance-class       db.t3.micro \
  --engine                  postgres \
  --engine-version          16 \
  --master-username         "$DB_USER" \
  --master-user-password    "$DB_PASS" \
  --db-name                 "$DB_NAME" \
  --allocated-storage       20

echo ">>> [RDS] Waiting for instance to become available..."
for i in $(seq 1 30); do
  STATUS=$($AWS rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo "creating")
  echo "  Status: $STATUS"
  [[ "$STATUS" == "available" ]] && break
  sleep 5
done

# Retrieve the real endpoint provided by MiniStack
RDS_HOST=$($AWS rds describe-db-instances \
  --db-instance-identifier "$INSTANCE_ID" \
  --query 'DBInstances[0].Endpoint.Address' --output text)
RDS_PORT=$($AWS rds describe-db-instances \
  --db-instance-identifier "$INSTANCE_ID" \
  --query 'DBInstances[0].Endpoint.Port' --output text)

echo ">>> [RDS] Endpoint: $RDS_HOST:$RDS_PORT"
echo ">>> [RDS] Applying schema and seed data..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$SCRIPT_DIR/../sql"

echo "RDS_HOST = $RDS_HOST"
echo "RDS_PORT = $RDS_PORT"

export PGPASSWORD="$DB_PASS"
psql -h "$RDS_HOST" -p "$RDS_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_DIR/01-schema.sql"
psql -h "$RDS_HOST" -p "$RDS_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_DIR/02-seed.sql"

echo ">>> [RDS] Database ready at $RDS_HOST:$RDS_PORT"
echo ">>> [RDS] Initialization complete."
