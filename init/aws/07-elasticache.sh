#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 07-elasticache.sh  –  ElastiCache initialization (Redis)
#
# MiniStack spins up a real Redis Docker container and
# returns the actual host:port endpoint via the AWS API.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --no-cli-pager --endpoint-url=http://localhost:4566 --region us-east-1"
CLUSTER_ID="ministack-redis"

echo ">>> [ElastiCache] Creating Redis cluster '$CLUSTER_ID'..."
$AWS elasticache create-cache-cluster \
  --cache-cluster-id    "$CLUSTER_ID" \
  --cache-node-type     cache.t3.micro \
  --engine              redis \
  --engine-version      7.0 \
  --num-cache-nodes     1

echo ">>> [ElastiCache] Waiting for cluster to become available..."
for i in $(seq 1 30); do
  STATUS=$($AWS elasticache describe-cache-clusters \
    --cache-cluster-id "$CLUSTER_ID" \
    --query 'CacheClusters[0].CacheClusterStatus' --output text 2>/dev/null || echo "creating")
  echo "  Status: $STATUS"
  [[ "$STATUS" == "available" ]] && break
  sleep 5
done

REDIS_HOST=$($AWS elasticache describe-cache-clusters \
  --cache-cluster-id "$CLUSTER_ID" \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)
REDIS_PORT=$($AWS elasticache describe-cache-clusters \
  --cache-cluster-id "$CLUSTER_ID" \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Port' --output text)

echo ">>> [ElastiCache] Endpoint: $REDIS_HOST:$REDIS_PORT"

echo ">>> [ElastiCache] Testing connection..."
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" PING

echo ">>> [ElastiCache] Initialization complete."
