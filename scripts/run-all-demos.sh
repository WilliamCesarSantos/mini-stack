#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# run-all-demos.sh  –  Runs all service demos in sequence
# ─────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_demo() {
  local name="$1"
  local script="$2"
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "  Starting: $name"
  echo "╚══════════════════════════════════════════╝"
  bash "$SCRIPT_DIR/$script"
  echo ""
}

run_demo "S3"                   "s3-demo.sh"
run_demo "SNS"                  "sns-demo.sh"
run_demo "SQS"                  "sqs-demo.sh"
run_demo "DynamoDB"             "dynamodb-demo.sh"
run_demo "Athena"               "athena-demo.sh"
run_demo "PostgreSQL (Aurora)"  "postgres-demo.sh"
run_demo "ElastiCache (Redis)"  "elasticache-demo.sh"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "  ✔  All demos complete!                   "
echo "╚══════════════════════════════════════════╝"
