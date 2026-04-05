#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# postgres-demo.sh  –  PostgreSQL query demo
#                      (Aurora PostgreSQL via RDS in MiniStack)
#
# MiniStack creates a real PostgreSQL container.
# The endpoint is fetched via: aws rds describe-db-instances
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566 --region us-east-1"
INSTANCE_ID="ministack-postgres"

echo "═══════════════════════════════════════════"
echo "  PostgreSQL (Aurora via RDS) – Mini-Stack"
echo "═══════════════════════════════════════════"

echo ""
echo "▸ Fetching RDS endpoint via AWS CLI..."
RDS_HOST=$($AWS rds describe-db-instances \
  --db-instance-identifier "$INSTANCE_ID" \
  --query 'DBInstances[0].Endpoint.Address' --output text)
RDS_PORT=$($AWS rds describe-db-instances \
  --db-instance-identifier "$INSTANCE_ID" \
  --query 'DBInstances[0].Endpoint.Port' --output text)
DB_STATUS=$($AWS rds describe-db-instances \
  --db-instance-identifier "$INSTANCE_ID" \
  --query 'DBInstances[0].DBInstanceStatus' --output text)

echo "  Instance : $INSTANCE_ID"
echo "  Endpoint : $RDS_HOST:$RDS_PORT"
echo "  Status   : $DB_STATUS"

PSQL="psql -h $RDS_HOST -p $RDS_PORT -U admin -d ministack"
export PGPASSWORD="admin123"

echo ""
echo "▸ Tables in 'ministack':"
$PSQL -c "\dt"

echo ""
echo "▸ PostgreSQL version:"
$PSQL -c "SELECT version();"

echo ""
echo "▸ All users:"
$PSQL -c "SELECT username, email, full_name, created_at FROM users ORDER BY created_at;"

echo ""
echo "▸ Product catalog with category:"
$PSQL -c "
SELECT p.sku, p.name, c.name AS category, p.price, p.stock
FROM products p
JOIN categories c ON c.id = p.category_id
ORDER BY c.name, p.price DESC;
"

echo ""
echo "▸ Order summary (via view v_order_summary):"
$PSQL -c "SELECT * FROM v_order_summary ORDER BY order_id;"

echo ""
echo "▸ Revenue by order status:"
$PSQL -c "
SELECT
    o.status,
    COUNT(o.id)                          AS order_count,
    SUM(oi.quantity * oi.unit_price)     AS total_revenue,
    AVG(oi.quantity * oi.unit_price)     AS avg_ticket
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.status
ORDER BY total_revenue DESC;
"

echo ""
echo "▸ Best-selling products:"
$PSQL -c "
SELECT
    p.sku,
    p.name,
    SUM(oi.quantity)                      AS units_sold,
    SUM(oi.quantity * oi.unit_price)      AS revenue
FROM order_items oi
JOIN products p ON p.id = oi.product_id
JOIN orders   o ON o.id = oi.order_id
WHERE o.status NOT IN ('cancelled')
GROUP BY p.sku, p.name
ORDER BY units_sold DESC;
"

echo ""
echo "▸ Low-stock products (< 60 units):"
$PSQL -c "
SELECT sku, name, stock
FROM products
WHERE stock < 60
ORDER BY stock ASC;
"

echo ""
echo "▸ Inserting a new user..."
$PSQL -c "
INSERT INTO users (username, email, full_name)
VALUES ('user_006', 'frank@example.com', 'Frank Oliveira')
ON CONFLICT (username) DO NOTHING;
SELECT username, email FROM users WHERE username = 'user_006';
"

echo ""
echo "▸ Updating P002 stock (-5 units)..."
$PSQL -c "
UPDATE products SET stock = stock - 5 WHERE sku = 'P002';
SELECT sku, name, stock FROM products WHERE sku = 'P002';
"

echo ""
echo "✔  PostgreSQL (RDS) demo complete."
