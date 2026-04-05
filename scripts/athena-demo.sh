#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# athena-demo.sh  –  Athena query demo
# Athena in MiniStack runs real SQL via DuckDB
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566 --region us-east-1"
OUTPUT_LOCATION="s3://mini-stack-athena-results/"
DATABASE="ministack"

echo "═══════════════════════════════════════════"
echo "  Athena Demo – Mini-Stack"
echo "═══════════════════════════════════════════"

# Helper: submit a query and wait for the result
run_query() {
  local description="$1"
  local sql="$2"

  echo ""
  echo "▸ $description"
  echo "  SQL: $sql"

  QUERY_ID=$($AWS athena start-query-execution \
    --query-string "$sql" \
    --result-configuration "OutputLocation=${OUTPUT_LOCATION}" \
    --query-execution-context "Database=${DATABASE}" \
    --query QueryExecutionId --output text)

  echo "  QueryExecutionId: $QUERY_ID"

  # Poll until finished (max 30s)
  for i in $(seq 1 15); do
    STATE=$($AWS athena get-query-execution \
      --query-execution-id "$QUERY_ID" \
      --query 'QueryExecution.Status.State' --output text)
    if [[ "$STATE" == "SUCCEEDED" || "$STATE" == "FAILED" || "$STATE" == "CANCELLED" ]]; then
      break
    fi
    sleep 2
  done

  echo "  Final state: $STATE"

  if [[ "$STATE" == "SUCCEEDED" ]]; then
    $AWS athena get-query-results \
      --query-execution-id "$QUERY_ID" \
      --query 'ResultSet.Rows' \
      --output table 2>/dev/null || echo "  (results available at $OUTPUT_LOCATION)"
  fi
}

echo ""
echo "▸ Tables in database '$DATABASE':"
$AWS glue get-tables --database-name "$DATABASE" \
  --query 'TableList[].{Table:Name,Type:TableType,Location:StorageDescriptor.Location}' \
  --output table

run_query \
  "Count total products" \
  "SELECT COUNT(*) AS total_products FROM ${DATABASE}.products"

run_query \
  "Products grouped by category with average price" \
  "SELECT category, COUNT(*) AS qty, AVG(price) AS avg_price FROM ${DATABASE}.products GROUP BY category ORDER BY qty DESC"

run_query \
  "Products with stock below 100" \
  "SELECT product_id, name, stock FROM ${DATABASE}.products WHERE stock < 100 ORDER BY stock ASC"

run_query \
  "Access logs: requests by status code" \
  "SELECT status_code, COUNT(*) AS total FROM ${DATABASE}.access_logs GROUP BY status_code ORDER BY total DESC"

run_query \
  "Access logs: actions from user_001" \
  "SELECT timestamp, action, resource, status_code FROM ${DATABASE}.access_logs WHERE user_id = 'user_001' ORDER BY timestamp"

echo ""
echo "▸ Result files in the Athena results bucket:"
$AWS s3 ls "$OUTPUT_LOCATION" --recursive --human-readable 2>/dev/null || echo "  (no results yet)"

echo ""
echo "✔  Athena demo complete."
