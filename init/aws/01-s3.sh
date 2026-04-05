#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 01-s3.sh  –  S3 initialization
# Creates buckets and uploads sample text files
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566 --region us-east-1"

echo ">>> [S3] Creating buckets..."
$AWS s3 mb s3://mini-stack-data
$AWS s3 mb s3://mini-stack-athena-results

echo ">>> [S3] Generating sample files..."

# File 1 – access logs (CSV compatible with Athena/DuckDB)
cat <<CSVEOF > /tmp/access-logs.csv
timestamp,user_id,action,resource,status_code
2024-01-15T08:00:00Z,user_001,GET,/api/products,200
2024-01-15T08:01:30Z,user_002,POST,/api/orders,201
2024-01-15T08:03:45Z,user_001,GET,/api/orders/42,200
2024-01-15T08:05:00Z,user_003,DELETE,/api/cart/7,204
2024-01-15T08:06:20Z,user_004,GET,/api/products,200
2024-01-15T08:07:55Z,user_002,PUT,/api/orders/42,200
2024-01-15T08:10:00Z,user_005,POST,/api/auth/login,401
2024-01-15T08:12:10Z,user_005,POST,/api/auth/login,200
CSVEOF

# File 2 – product catalog (CSV)
cat <<CSVEOF > /tmp/products.csv
product_id,name,category,price,stock
P001,Notebook Pro 15,Electronics,4599.90,50
P002,RGB Gaming Mouse,Peripherals,189.90,200
P003,Mechanical Keyboard,Peripherals,349.90,150
P004,27in 4K Monitor,Electronics,2199.90,30
P005,Wireless Headset,Audio,499.90,80
P006,HD 1080p Webcam,Peripherals,279.90,120
P007,1TB NVMe SSD,Storage,399.90,90
P008,7-Port USB-C Hub,Accessories,129.90,300
CSVEOF

# File 3 – plain-text note
cat <<TXTEOF > /tmp/readme.txt
Mini-Stack Demo
===============

This bucket stores demonstration data for the mini-stack project.

Layout:
  logs/     -> application access logs (CSV)
  products/ -> product catalog (CSV)
  docs/     -> documentation and notes

Created at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Environment: MiniStack (https://github.com/Nahuel990/ministack)
TXTEOF

echo ">>> [S3] Uploading files..."
$AWS s3 cp /tmp/access-logs.csv  s3://mini-stack-data/logs/access-logs.csv
$AWS s3 cp /tmp/products.csv     s3://mini-stack-data/products/products.csv
$AWS s3 cp /tmp/readme.txt       s3://mini-stack-data/docs/readme.txt

echo ">>> [S3] Contents of mini-stack-data:"
$AWS s3 ls s3://mini-stack-data --recursive

echo ">>> [S3] Initialization complete."
