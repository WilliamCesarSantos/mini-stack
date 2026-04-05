#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 03-sqs.sh  –  SQS initialization
#
# Queues created:
#   mini-stack-orders-queue  →  subscribed to the SNS topic (fan-out)
#   mini-stack-events-queue  →  standalone queue for generic events
#   mini-stack-orders-dlq    →  dead-letter queue for orders-queue
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566 --region us-east-1"
ACCOUNT_ID="000000000000"
REGION="us-east-1"
TOPIC_ARN="arn:aws:sns:${REGION}:${ACCOUNT_ID}:mini-stack-topic"

echo ">>> [SQS] Creating Dead-Letter Queue..."
DLQ_URL=$($AWS sqs create-queue \
  --queue-name mini-stack-orders-dlq \
  --attributes '{"MessageRetentionPeriod":"86400"}' \
  --query QueueUrl --output text)
DLQ_ARN=$($AWS sqs get-queue-attributes \
  --queue-url "$DLQ_URL" \
  --attribute-names QueueArn \
  --query Attributes.QueueArn --output text)
echo ">>> [SQS] DLQ: $DLQ_ARN"

# ── Queue 1: orders-queue (subscribed to SNS) ─────────────────
echo ">>> [SQS] Creating mini-stack-orders-queue..."
ORDERS_URL=$($AWS sqs create-queue \
  --queue-name mini-stack-orders-queue \
  --attributes "{
    \"VisibilityTimeout\": \"30\",
    \"MessageRetentionPeriod\": \"345600\",
    \"RedrivePolicy\": \"{\\\"deadLetterTargetArn\\\":\\\"${DLQ_ARN}\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"
  }" \
  --query QueueUrl --output text)

ORDERS_ARN=$($AWS sqs get-queue-attributes \
  --queue-url "$ORDERS_URL" \
  --attribute-names QueueArn \
  --query Attributes.QueueArn --output text)

# Access policy allowing SNS to send messages to this queue
$AWS sqs set-queue-attributes \
  --queue-url "$ORDERS_URL" \
  --attributes "{
    \"Policy\": \"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":[{\\\"Effect\\\":\\\"Allow\\\",\\\"Principal\\\":{\\\"Service\\\":\\\"sns.amazonaws.com\\\"},\\\"Action\\\":\\\"sqs:SendMessage\\\",\\\"Resource\\\":\\\"${ORDERS_ARN}\\\",\\\"Condition\\\":{\\\"ArnEquals\\\":{\\\"aws:SourceArn\\\":\\\"${TOPIC_ARN}\\\"}}}]}\"
  }"

# Subscribe the queue to the SNS topic
echo ">>> [SQS] Subscribing orders-queue to SNS topic..."
$AWS sns subscribe \
  --topic-arn "$TOPIC_ARN" \
  --protocol sqs \
  --notification-endpoint "$ORDERS_ARN"

# ── Queue 2: events-queue (standalone) ───────────────────────
echo ">>> [SQS] Creating mini-stack-events-queue..."
$AWS sqs create-queue \
  --queue-name mini-stack-events-queue \
  --attributes '{"VisibilityTimeout":"60","MessageRetentionPeriod":"172800"}' \
  --query QueueUrl --output text

echo ">>> [SQS] Queues created:"
$AWS sqs list-queues

echo ">>> [SNS] Subscriptions:"
$AWS sns list-subscriptions

echo ">>> [SQS] Initialization complete."
