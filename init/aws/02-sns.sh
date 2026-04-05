#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 02-sns.sh  –  SNS initialization
# Creates the main topic
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --no-cli-pager --endpoint-url=http://localhost:4566 --region us-east-1"

echo ">>> [SNS] Creating topic mini-stack-topic..."
TOPIC_ARN=$($AWS sns create-topic --name mini-stack-topic --query TopicArn --output text)
echo ">>> [SNS] Topic created: $TOPIC_ARN"

$AWS sns set-topic-attributes \
  --topic-arn "$TOPIC_ARN" \
  --attribute-name DisplayName \
  --attribute-value "Mini Stack Events"

echo ">>> [SNS] Listing topics:"
$AWS sns list-topics

echo ">>> [SNS] Initialization complete."
