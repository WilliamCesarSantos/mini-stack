#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# sqs-demo.sh  –  SQS operations demo
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --no-cli-pager --endpoint-url=http://localhost:4566 --region us-east-1"
ORDERS_QUEUE="http://localhost:4566/000000000000/mini-stack-orders-queue"
EVENTS_QUEUE="http://localhost:4566/000000000000/mini-stack-events-queue"

echo "═══════════════════════════════════════════"
echo "  SQS Demo – Mini-Stack"
echo "═══════════════════════════════════════════"

echo ""
echo "▸ Available queues:"
$AWS sqs list-queues

echo ""
echo "▸ Attributes of the orders queue:"
$AWS sqs get-queue-attributes \
  --queue-url "$ORDERS_QUEUE" \
  --attribute-names All \
  --query 'Attributes.{Messages:ApproximateNumberOfMessages,InFlight:ApproximateNumberOfMessagesNotVisible,DLQ:RedrivePolicy}'

echo ""
echo "▸ Sending messages directly to mini-stack-events-queue..."
for i in 1 2 3; do
  MSG_ID=$($AWS sqs send-message \
    --queue-url "$EVENTS_QUEUE" \
    --message-body "{\"event\":\"user.action\",\"user_id\":\"user_00${i}\",\"action\":\"page_view\",\"page\":\"/products\"}" \
    --message-attributes "{\"source\":{\"DataType\":\"String\",\"StringValue\":\"web-app\"}}" \
    --query MessageId --output text)
  echo "  Message $i sent – MessageId: $MSG_ID"
done

echo ""
echo "▸ Receiving messages from mini-stack-orders-queue (SNS fan-out):"
RESULT=$($AWS sqs receive-message \
  --queue-url "$ORDERS_QUEUE" \
  --max-number-of-messages 5 \
  --wait-time-seconds 2 \
  --attribute-names All 2>/dev/null || echo '{"Messages":[]}')

COUNT=$(echo "$RESULT" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('Messages',[])))" 2>/dev/null || echo "0")
echo "  Messages available: $COUNT"

if [ "$COUNT" -gt 0 ]; then
  echo "$RESULT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for i, msg in enumerate(data.get('Messages', []), 1):
    body = json.loads(msg['Body'])
    print(f'  [{i}] MessageId: {msg[\"MessageId\"]}')
    print(f'      Body: {json.dumps(body)[:120]}')
"
fi

echo ""
echo "▸ Receiving messages from mini-stack-events-queue:"
$AWS sqs receive-message \
  --queue-url "$EVENTS_QUEUE" \
  --max-number-of-messages 5 \
  --wait-time-seconds 2 | python3 -c "
import sys, json
data = json.load(sys.stdin)
for i, msg in enumerate(data.get('Messages', []), 1):
    print(f'  [{i}] {msg[\"Body\"]}')
" 2>/dev/null || echo "  (no messages)"

echo ""
echo "▸ Approximate message count per queue:"
for queue_url in "$ORDERS_QUEUE" "$EVENTS_QUEUE"; do
  name=$(basename "$queue_url")
  count=$($AWS sqs get-queue-attributes \
    --queue-url "$queue_url" \
    --attribute-names ApproximateNumberOfMessages \
    --query Attributes.ApproximateNumberOfMessages --output text)
  echo "  $name: ~$count message(s)"
done

echo ""
echo "✔  SQS demo complete."
