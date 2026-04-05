#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 04-dynamodb.sh  –  DynamoDB initialization
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --no-cli-pager --endpoint-url=http://localhost:4566 --region us-east-1"

echo ">>> [DynamoDB] Creating Products table..."
$AWS dynamodb create-table \
  --table-name Products \
  --attribute-definitions \
      AttributeName=product_id,AttributeType=S \
      AttributeName=category,AttributeType=S \
  --key-schema \
      AttributeName=product_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --global-secondary-indexes "[
    {
      \"IndexName\": \"category-index\",
      \"KeySchema\": [{\"AttributeName\":\"category\",\"KeyType\":\"HASH\"}],
      \"Projection\": {\"ProjectionType\":\"ALL\"}
    }
  ]"

$AWS dynamodb wait table-exists --table-name Products

echo ">>> [DynamoDB] Inserting products..."
items=(
  '{"product_id":{"S":"P001"},"name":{"S":"Notebook Pro 15"},"category":{"S":"Electronics"},"price":{"N":"4599.90"},"stock":{"N":"50"},"active":{"BOOL":true}}'
  '{"product_id":{"S":"P002"},"name":{"S":"RGB Gaming Mouse"},"category":{"S":"Peripherals"},"price":{"N":"189.90"},"stock":{"N":"200"},"active":{"BOOL":true}}'
  '{"product_id":{"S":"P003"},"name":{"S":"Mechanical Keyboard"},"category":{"S":"Peripherals"},"price":{"N":"349.90"},"stock":{"N":"150"},"active":{"BOOL":true}}'
  '{"product_id":{"S":"P004"},"name":{"S":"27in 4K Monitor"},"category":{"S":"Electronics"},"price":{"N":"2199.90"},"stock":{"N":"30"},"active":{"BOOL":true}}'
  '{"product_id":{"S":"P005"},"name":{"S":"Wireless Headset"},"category":{"S":"Audio"},"price":{"N":"499.90"},"stock":{"N":"80"},"active":{"BOOL":false}}'
)
for item in "${items[@]}"; do
  $AWS dynamodb put-item --table-name Products --item "$item"
done

echo ">>> [DynamoDB] Creating Orders table..."
$AWS dynamodb create-table \
  --table-name Orders \
  --attribute-definitions \
      AttributeName=order_id,AttributeType=S \
      AttributeName=user_id,AttributeType=S \
  --key-schema \
      AttributeName=order_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --global-secondary-indexes "[
    {
      \"IndexName\": \"user-orders-index\",
      \"KeySchema\": [{\"AttributeName\":\"user_id\",\"KeyType\":\"HASH\"}],
      \"Projection\": {\"ProjectionType\":\"ALL\"}
    }
  ]"

$AWS dynamodb wait table-exists --table-name Orders

$AWS dynamodb put-item --table-name Orders --item \
  '{"order_id":{"S":"ORD-001"},"user_id":{"S":"user_001"},"product_id":{"S":"P001"},"quantity":{"N":"1"},"total":{"N":"4599.90"},"status":{"S":"delivered"}}'
$AWS dynamodb put-item --table-name Orders --item \
  '{"order_id":{"S":"ORD-002"},"user_id":{"S":"user_002"},"product_id":{"S":"P002"},"quantity":{"N":"2"},"total":{"N":"379.80"},"status":{"S":"processing"}}'
$AWS dynamodb put-item --table-name Orders --item \
  '{"order_id":{"S":"ORD-003"},"user_id":{"S":"user_001"},"product_id":{"S":"P004"},"quantity":{"N":"1"},"total":{"N":"2199.90"},"status":{"S":"shipped"}}'

echo ">>> [DynamoDB] Tables:"
$AWS dynamodb list-tables

echo ">>> [DynamoDB] Initialization complete."
