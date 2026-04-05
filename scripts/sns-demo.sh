#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# sns-demo.sh  –  SNS operations demo
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --no-cli-pager --endpoint-url=http://localhost:4566 --region us-east-1"
ACCOUNT_ID="000000000000"
TOPIC_ARN="arn:aws:sns:us-east-1:${ACCOUNT_ID}:mini-stack-topic"

echo "═══════════════════════════════════════════"
echo "  SNS Demo – Mini-Stack"
echo "═══════════════════════════════════════════"

echo ""
echo "▸ Available topics:"
$AWS sns list-topics

echo ""
echo "▸ Attributes of mini-stack-topic:"
$AWS sns get-topic-attributes --topic-arn "$TOPIC_ARN"

echo ""
echo "▸ Topic subscriptions:"
$AWS sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN"

echo ""
echo "▸ Publishing order.created event..."
MSG_ID=$($AWS sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"event":"order.created","order_id":"ORD-100","user_id":"user_001","total":4599.90}' \
  --subject "New Order Created" \
  --message-attributes '{"event_type":{"DataType":"String","StringValue":"order.created"}}' \
  --query MessageId --output text)
echo "  MessageId: $MSG_ID"

echo ""
echo "▸ Publishing stock.updated event..."
MSG_ID2=$($AWS sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"event":"stock.updated","product_id":"P001","old_stock":50,"new_stock":49}' \
  --subject "Stock Updated" \
  --message-attributes '{"event_type":{"DataType":"String","StringValue":"stock.updated"}}' \
  --query MessageId --output text)
echo "  MessageId: $MSG_ID2"

echo ""
echo "▸ Publishing order.cancelled event..."
MSG_ID3=$($AWS sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"event":"order.cancelled","order_id":"ORD-005","reason":"customer_request"}' \
  --subject "Order Cancelled" \
  --query MessageId --output text)
echo "  MessageId: $MSG_ID3"

echo ""
echo "✔  SNS demo complete. Check the SQS queue for delivered messages."
