#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# s3-demo.sh  –  S3 operations demo
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566 --region us-east-1"

echo "═══════════════════════════════════════════"
echo "  S3 Demo – Mini-Stack"
echo "═══════════════════════════════════════════"

echo ""
echo "▸ Listing all buckets:"
$AWS s3 ls

echo ""
echo "▸ Contents of mini-stack-data (recursive):"
$AWS s3 ls s3://mini-stack-data --recursive --human-readable

echo ""
echo "▸ Uploading a new report file..."
TMP=$(mktemp)
cat <<REPORT > "$TMP"
Sales Report – $(date +"%B %Y")
================================
Total orders:    5
Gross revenue:   $8,229.50
Average ticket:  $1,645.90
Unique products: 6

Top 3 products:
  1. Notebook Pro 15  –  $4,599.90
  2. 27in 4K Monitor  –  $2,199.90
  3. Wireless Headset –  $  499.90
REPORT
$AWS s3 cp "$TMP" s3://mini-stack-data/reports/sales-report.txt
echo "  Upload complete."

echo ""
echo "▸ Downloading readme.txt:"
$AWS s3 cp s3://mini-stack-data/docs/readme.txt /tmp/readme-downloaded.txt
cat /tmp/readme-downloaded.txt

echo ""
echo "▸ Copying products.csv to backup/..."
$AWS s3 cp \
  s3://mini-stack-data/products/products.csv \
  s3://mini-stack-data/backup/products-backup.csv

echo ""
echo "▸ Metadata for access-logs.csv:"
$AWS s3api head-object \
  --bucket mini-stack-data \
  --key logs/access-logs.csv

echo ""
echo "▸ Final bucket state:"
$AWS s3 ls s3://mini-stack-data --recursive --human-readable

rm -f "$TMP" /tmp/readme-downloaded.txt
echo ""
echo "✔  S3 demo complete."
