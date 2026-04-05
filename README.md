# Mini-Stack

Demonstration project for AWS services emulated locally with **[MiniStack](https://github.com/Nahuel990/ministack)** — a free, open-source, drop-in replacement for LocalStack, compatible with the AWS CLI, boto3, Terraform, and any AWS SDK.

> **Why MiniStack?** LocalStack moved its core services behind a paid plan. MiniStack emulates 38+ AWS services in a single container, free forever.

## Services

| Service           | How it is emulated                        | Port    |
|-------------------|-------------------------------------------|---------|
| S3                | MiniStack (emulated)                      | 4566    |
| SNS               | MiniStack (emulated)                      | 4566    |
| SQS               | MiniStack (emulated)                      | 4566    |
| DynamoDB          | MiniStack (emulated)                      | 4566    |
| Athena + Glue     | MiniStack + **DuckDB** (real SQL engine)  | 4566    |
| Lambda            | MiniStack (Python 3.12 runtime)           | 4566    |
| Aurora PostgreSQL | MiniStack → real PostgreSQL container     | dynamic |
| ElastiCache       | MiniStack → real Redis container          | dynamic |

> RDS and ElastiCache spin up real Docker containers. Their endpoints (host:port) are retrieved at runtime via `aws rds describe-db-instances` and `aws elasticache describe-cache-clusters`.

## Project Layout

```
mini-stack/
├── docker-compose.yml              # Single MiniStack service
├── .env                            # AWS credentials and DB config
├── startup.sh                      # Start docker compose + bootstrap all services
├── down.sh                         # Stop everything, including RDS/ElastiCache containers
├── init/
│   ├── aws/                        # AWS resource initialization scripts
│   │   ├── 01-s3.sh                # Create buckets + upload CSV/TXT sample files
│   │   ├── 02-sns.sh               # Create mini-stack-topic
│   │   ├── 03-sqs.sh               # Create 2 queues + subscribe orders-queue to SNS
│   │   ├── 04-dynamodb.sh          # Create Products/Orders tables + seed items
│   │   ├── 05-athena.sh            # Create Glue database + external tables over S3
│   │   ├── 06-rds.sh               # Create RDS PostgreSQL instance + apply schema/seed
│   │   ├── 07-elasticache.sh       # Create ElastiCache Redis cluster
│   │   ├── 08-lambda.sh            # Package and deploy hello-world Python Lambda
│   │   └── lambda/
│   │       └── hello_world.py      # Lambda handler source code
│   └── sql/                        # SQL files applied by 06-rds.sh
│       ├── 01-schema.sql           # Tables, indexes, and summary view
│       └── 02-seed.sql             # Initial demo data
└── scripts/
    ├── s3-demo.sh                  # Upload, download, copy, list
    ├── sns-demo.sh                 # Publish events to topic
    ├── sqs-demo.sh                 # Send/receive messages, inspect fan-out
    ├── dynamodb-demo.sh            # CRUD, GSI queries, scans with filters
    ├── athena-demo.sh              # SQL queries over S3 data via DuckDB
    ├── postgres-demo.sh            # Relational queries (fetches RDS endpoint)
    ├── elasticache-demo.sh         # String, Hash, List, Set, Sorted Set patterns
    ├── lambda-demo.sh              # Invoke Python Lambda function
    └── run-all-demos.sh            # Run every demo in sequence
```

## SNS / SQS Architecture

```
                     ┌─────────────────────┐
  Publish ──────────►│  mini-stack-topic   │ (SNS)
                     └──────────┬──────────┘
                                │ automatic fan-out
                     ┌──────────▼──────────┐
                     │ mini-stack-orders-  │ (SQS – subscribed to SNS)
                     │      queue          │
                     │  └─ orders-dlq      │ (DLQ, maxReceiveCount=3)
                     └─────────────────────┘

  mini-stack-events-queue  →  standalone queue for generic events
```

## Prerequisites

- Docker and Docker Compose
- AWS CLI (any fake credentials work)
- `psql` — for the PostgreSQL/RDS demo
- `redis-cli` — for the ElastiCache demo
- `python3` — JSON parsing in sqs-demo and lambda-demo

## Getting Started

```bash
# Make scripts executable
chmod +x startup.sh down.sh scripts/*.sh init/aws/*.sh

# Start MiniStack and bootstrap all AWS resources in one step
bash startup.sh
```

`startup.sh` performs the following automatically:
1. Runs `docker compose up -d`
2. Waits for MiniStack to become healthy
3. Executes all `init/aws/` scripts in order (S3 → SNS → SQS → DynamoDB → Athena → RDS → ElastiCache → Lambda)

## Running the Demos

```bash
# Individual demos
bash scripts/s3-demo.sh
bash scripts/sns-demo.sh
bash scripts/sqs-demo.sh
bash scripts/dynamodb-demo.sh
bash scripts/athena-demo.sh
bash scripts/postgres-demo.sh
bash scripts/elasticache-demo.sh
bash scripts/lambda-demo.sh

# All at once
bash scripts/run-all-demos.sh
```

## AWS CLI Configuration

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

# Verify connectivity
curl http://localhost:4566/_ministack/health

# Quick smoke tests
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
aws --endpoint-url=http://localhost:4566 sns list-topics
```

## Stop and Clean Up

```bash
# Stop MiniStack, its child containers (RDS, ElastiCache), and remove volumes
bash down.sh
```

`down.sh` stops any Docker containers spawned by MiniStack (RDS, ElastiCache) before tearing down the compose stack, ensuring a fully clean state on the next `startup.sh`.
