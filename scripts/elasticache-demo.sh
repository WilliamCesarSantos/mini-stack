#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# elasticache-demo.sh  –  ElastiCache (Redis) operations demo
#
# MiniStack creates a real Redis container.
# The endpoint is fetched via: aws elasticache describe-cache-clusters
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --no-cli-pager --endpoint-url=http://localhost:4566 --region us-east-1"
CLUSTER_ID="ministack-redis"

echo "═══════════════════════════════════════════"
echo "  ElastiCache (Redis) Demo – Mini-Stack"
echo "═══════════════════════════════════════════"

echo ""
echo "▸ Fetching ElastiCache endpoint via AWS CLI..."
REDIS_HOST=$($AWS elasticache describe-cache-clusters \
  --cache-cluster-id "$CLUSTER_ID" \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)
REDIS_PORT=$($AWS elasticache describe-cache-clusters \
  --cache-cluster-id "$CLUSTER_ID" \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Port' --output text)
CLUSTER_STATUS=$($AWS elasticache describe-cache-clusters \
  --cache-cluster-id "$CLUSTER_ID" \
  --query 'CacheClusters[0].CacheClusterStatus' --output text)

echo "  Cluster  : $CLUSTER_ID"
echo "  Endpoint : $REDIS_HOST:$REDIS_PORT"
echo "  Status   : $CLUSTER_STATUS"

REDIS="redis-cli -h $REDIS_HOST -p $REDIS_PORT"

echo ""
echo "▸ Checking connectivity:"
$REDIS PING
$REDIS INFO server | grep -E "redis_version|uptime_in_seconds"

# Strings: session cache
echo ""
echo "▸ Storing user sessions (TTL 30min)..."
$REDIS SET "session:user_001" '{"user_id":"user_001","name":"Alice Silva","role":"customer"}' EX 1800
$REDIS SET "session:user_002" '{"user_id":"user_002","name":"Bob Santos","role":"customer"}'  EX 1800
$REDIS SET "session:admin_01" '{"user_id":"admin_01","name":"Admin","role":"admin"}'          EX 3600
echo "  TTL for session:user_001: $($REDIS TTL session:user_001)s"

echo ""
echo "▸ Reading session for user_001:"
$REDIS GET "session:user_001"

# Hash: product cache
echo ""
echo "▸ Caching product P001 as Hash (TTL 5min)..."
$REDIS HSET "product:P001" name "Notebook Pro 15" category "Electronics" price "4599.90" stock "50"
$REDIS EXPIRE "product:P001" 300
echo "  Fields for product:P001:"
$REDIS HGETALL "product:P001"

# Counters: rate limiting
echo ""
echo "▸ Simulating rate limiting (INCR + EXPIRE)..."
$REDIS DEL "rate:user_001" > /dev/null
for i in 1 2 3; do
  COUNT=$($REDIS INCR "rate:user_001")
  echo "  Request #$COUNT from user_001"
done
$REDIS EXPIRE "rate:user_001" 60

# List: notification queue
echo ""
echo "▸ Notification queue (List)..."
$REDIS RPUSH "notifications:user_001" \
  "Your order ORD-001 has been delivered!" \
  "Deal: 10% off Electronics today!"
echo "  Notifications for user_001:"
$REDIS LRANGE "notifications:user_001" 0 -1
echo "  Consuming first notification:"
$REDIS LPOP "notifications:user_001"

# Set: viewed products
echo ""
echo "▸ Products viewed by user_001 (Set)..."
$REDIS SADD "viewed:user_001" "P001" "P004" "P005" "P002" "P001"
echo "  Unique products viewed: $($REDIS SCARD viewed:user_001)"
$REDIS SMEMBERS "viewed:user_001"

# Sorted Set: popularity ranking
echo ""
echo "▸ Most-viewed products ranking (Sorted Set)..."
$REDIS ZADD "product:views" 150 "P001" 320 "P002" 280 "P004" 95 "P007" 410 "P003"
echo "  Top 3:"
$REDIS ZREVRANGE "product:views" 0 2 WITHSCORES

echo ""
echo "▸ All keys in Redis:"
$REDIS KEYS "*" | sort

echo ""
echo "✔  ElastiCache (Redis) demo complete."
