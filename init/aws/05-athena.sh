#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 05-athena.sh  –  Athena / Glue initialization
# Athena in MiniStack runs real SQL via DuckDB
# ─────────────────────────────────────────────────────────────
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566 --region us-east-1"

echo ">>> [Athena] Creating Glue database 'ministack'..."
$AWS glue create-database --database-input '{"Name":"ministack","Description":"Mini-Stack demo database"}'

echo ">>> [Athena] Creating external table 'access_logs'..."
$AWS glue create-table \
  --database-name ministack \
  --table-input '{
    "Name": "access_logs",
    "StorageDescriptor": {
      "Columns": [
        {"Name": "timestamp",    "Type": "string"},
        {"Name": "user_id",      "Type": "string"},
        {"Name": "action",       "Type": "string"},
        {"Name": "resource",     "Type": "string"},
        {"Name": "status_code",  "Type": "int"}
      ],
      "Location": "s3://mini-stack-data/logs/",
      "InputFormat":  "org.apache.hadoop.mapred.TextInputFormat",
      "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
      "SerdeInfo": {
        "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
        "Parameters": {"field.delim": ",", "skip.header.line.count": "1"}
      }
    },
    "TableType": "EXTERNAL_TABLE"
  }'

echo ">>> [Athena] Creating external table 'products'..."
$AWS glue create-table \
  --database-name ministack \
  --table-input '{
    "Name": "products",
    "StorageDescriptor": {
      "Columns": [
        {"Name": "product_id", "Type": "string"},
        {"Name": "name",       "Type": "string"},
        {"Name": "category",   "Type": "string"},
        {"Name": "price",      "Type": "double"},
        {"Name": "stock",      "Type": "int"}
      ],
      "Location": "s3://mini-stack-data/products/",
      "InputFormat":  "org.apache.hadoop.mapred.TextInputFormat",
      "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
      "SerdeInfo": {
        "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
        "Parameters": {"field.delim": ",", "skip.header.line.count": "1"}
      }
    },
    "TableType": "EXTERNAL_TABLE"
  }'

echo ">>> [Athena] Registered tables:"
$AWS glue get-tables --database-name ministack --query 'TableList[].Name'

echo ">>> [Athena] Initialization complete."
