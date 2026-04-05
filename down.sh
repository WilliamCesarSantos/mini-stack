#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# down.sh  –  Stops MiniStack and all containers it spawned
#
# Use instead of: docker compose down
#
# Removes the MiniStack volume so the next `setup.sh` starts
# completely fresh (RDS, ElastiCache containers are recreated).
# ─────────────────────────────────────────────────────────────
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "⏳ Stopping MiniStack child containers..."

# Stop and remove containers spawned by MiniStack (RDS, ElastiCache, etc.)
SPAWNED=$(docker ps -a \
  --filter "name=ministack-rds-" \
  --filter "name=ministack-elasticache-" \
  --format "{{.Names}}" 2>/dev/null || true)

if [[ -n "$SPAWNED" ]]; then
  echo "$SPAWNED" | xargs docker rm -f
  echo "✔  Removed: $(echo "$SPAWNED" | tr '\n' ' ')"
else
  echo "  No child containers found."
fi

echo ""
echo "⏳ Stopping docker compose and removing volumes..."
# -v removes the ministack-data volume so state is cleared on next up
docker compose -f "$BASE_DIR/docker-compose.yml" down -v "$@"

echo ""
echo "✔  All done. Run 'bash startup.sh' to restart."
