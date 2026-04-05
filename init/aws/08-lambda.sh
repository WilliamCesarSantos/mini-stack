#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 08-lambda.sh  –  Lambda initialization
# Packages and deploys the hello-world Python function
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --no-cli-pager --endpoint-url=http://localhost:4566 --region us-east-1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_DIR="$SCRIPT_DIR/lambda"
ZIP_FILE="/tmp/hello_world.zip"
FUNCTION_NAME="mini-stack-hello-world"

echo ">>> [Lambda] Packaging hello_world.py..."
cd "$LAMBDA_DIR"
zip -j "$ZIP_FILE" hello_world.py
cd - > /dev/null

echo ">>> [Lambda] Deploying function: $FUNCTION_NAME..."
# Delete previous version if it exists (idempotent re-run)
$AWS lambda delete-function --function-name "$FUNCTION_NAME" 2>/dev/null || true

$AWS lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime python3.12 \
  --handler hello_world.handler \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --zip-file "fileb://$ZIP_FILE" \
  --query '{FunctionName:FunctionName, Runtime:Runtime, Handler:Handler, State:State}' \
  --output table

echo ">>> [Lambda] Initialization complete."
