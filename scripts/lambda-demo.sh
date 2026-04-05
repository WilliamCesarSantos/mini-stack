#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lambda-demo.sh  –  Lambda operations demo
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --no-cli-pager --endpoint-url=http://localhost:4566 --region us-east-1"
FUNCTION_NAME="mini-stack-hello-world"
RESPONSE_FILE="/tmp/lambda-response.json"

echo "═══════════════════════════════════════════"
echo "  Lambda Demo – Mini-Stack"
echo "═══════════════════════════════════════════"

echo ""
echo "▸ Listing deployed functions:"
$AWS lambda list-functions \
  --query 'Functions[*].{Name:FunctionName, Runtime:Runtime, Handler:Handler}' \
  --output table

echo ""
echo "▸ Invoke #1 – with name payload:"
$AWS lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload '{"name": "MiniStack"}' \
  --cli-binary-format raw-in-base64-out \
  "$RESPONSE_FILE" > /dev/null
echo "  Response:"
python3 -c "
import json
with open('$RESPONSE_FILE') as f:
    resp = json.load(f)
body = json.loads(resp['body'])
print(f\"  statusCode : {resp['statusCode']}\")
print(f\"  message    : {body['message']}\")
"

echo ""
echo "▸ Invoke #2 – without payload (defaults to 'World'):"
$AWS lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  "$RESPONSE_FILE" > /dev/null
echo "  Response:"
python3 -c "
import json
with open('$RESPONSE_FILE') as f:
    resp = json.load(f)
body = json.loads(resp['body'])
print(f\"  statusCode : {resp['statusCode']}\")
print(f\"  message    : {body['message']}\")
"

echo ""
echo "✔  Lambda demo complete."
