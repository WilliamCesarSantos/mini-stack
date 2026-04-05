#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# startup.sh  –  Starts MiniStack and bootstraps all services
#
# Pair with: bash scripts/down.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

ENDPOINT="http://localhost:4566"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_DIR="$BASE_DIR/init/aws"

# ── Start docker compose ──────────────────────────────────────
echo "⏳ Starting docker compose..."
docker compose -f "$BASE_DIR/docker-compose.yml" up -d
echo ""

# ── Wait for MiniStack to be healthy ─────────────────────────
echo "⏳ Waiting for MiniStack to start..."
for i in $(seq 1 30); do
  if curl -sf "$ENDPOINT/_ministack/health" > /dev/null 2>&1; then
    echo "✔  MiniStack is healthy."
    break
  fi
  [[ $i -eq 30 ]] && { echo "✘  MiniStack did not respond. Check: docker compose ps"; exit 1; }
  sleep 2
done

# ── Run initialization scripts ────────────────────────────────
run_init() {
  local script="$1"
  echo ""
  echo "──────────────────────────────────────────"
  bash "$INIT_DIR/$script"
}

run_init "01-s3.sh"
run_init "02-sns.sh"
run_init "03-sqs.sh"
run_init "04-dynamodb.sh"
run_init "05-athena.sh"
run_init "06-rds.sh"
run_init "07-elasticache.sh"
run_init "08-lambda.sh"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "  ✔  All services initialized!             "
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Run the demos:  bash scripts/run-all-demos.sh"
echo "Shut down:      bash down.sh"
