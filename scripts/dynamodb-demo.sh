#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# dynamodb-demo.sh  –  DynamoDB operations demo
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --no-cli-pager --endpoint-url=http://localhost:4566 --region us-east-1"

echo "═══════════════════════════════════════════"
echo "  DynamoDB Demo – Mini-Stack"
echo "═══════════════════════════════════════════"

echo ""
echo "▸ Available tables:"
$AWS dynamodb list-tables

echo ""
echo "▸ Full scan of Products:"
$AWS dynamodb scan --table-name Products \
  --query 'Items[].{ID:product_id.S,Name:name.S,Category:category.S,Price:price.N,Stock:stock.N}' \
  --output table

echo ""
echo "▸ Get item P001:"
$AWS dynamodb get-item \
  --table-name Products \
  --key '{"product_id":{"S":"P001"}}' \
  --output json

echo ""
echo "▸ Products in category 'Peripherals' (via GSI):"
$AWS dynamodb query \
  --table-name Products \
  --index-name category-index \
  --key-condition-expression "category = :cat" \
  --expression-attribute-values '{":cat":{"S":"Peripherals"}}' \
  --query 'Items[].{SKU:product_id.S,Name:name.S,Price:price.N}' \
  --output table

echo ""
echo "▸ Updating stock of P002 (200 → 195)..."
$AWS dynamodb update-item \
  --table-name Products \
  --key '{"product_id":{"S":"P002"}}' \
  --update-expression "SET stock = :new_stock" \
  --expression-attribute-values '{":new_stock":{"N":"195"}}' \
  --return-values UPDATED_NEW

echo ""
echo "▸ Inserting new order ORD-100..."
$AWS dynamodb put-item \
  --table-name Orders \
  --item '{
    "order_id":  {"S":"ORD-100"},
    "user_id":   {"S":"user_003"},
    "product_id":{"S":"P007"},
    "quantity":  {"N":"2"},
    "total":     {"N":"799.80"},
    "status":    {"S":"processing"}
  }'
echo "  Order ORD-100 inserted."

echo ""
echo "▸ Orders for user_001 (via GSI):"
$AWS dynamodb query \
  --table-name Orders \
  --index-name user-orders-index \
  --key-condition-expression "user_id = :uid" \
  --expression-attribute-values '{":uid":{"S":"user_001"}}' \
  --query 'Items[].{Order:order_id.S,Product:product_id.S,Total:total.N,Status:status.S}' \
  --output table

echo ""
echo "▸ Orders with status 'processing':"
$AWS dynamodb scan \
  --table-name Orders \
  --filter-expression "#s = :status" \
  --expression-attribute-names '{"#s":"status"}' \
  --expression-attribute-values '{":status":{"S":"processing"}}' \
  --query 'Items[].{Order:order_id.S,User:user_id.S,Total:total.N}' \
  --output table

echo ""
echo "✔  DynamoDB demo complete."
