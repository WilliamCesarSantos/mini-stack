# Mini-Stack

Demonstration project for AWS services emulated locally with **[MiniStack](https://github.com/Nahuel990/ministack)** — a free, open-source, drop-in replacement for LocalStack, compatible with the AWS CLI, boto3, Terraform, and any AWS SDK.

> **Why MiniStack?** LocalStack moved its core services behind a paid plan. MiniStack emulates 38+ AWS services in a single container, free forever.

## Services

| Service           | How it is emulated                        | Port      |
|-------------------|-------------------------------------------|-----------|
| S3                | MiniStack (emulated)                      | 4566      |
| SNS               | MiniStack (emulated)                      | 4566      |
| SQS               | MiniStack (emulated)                      | 4566      |
| DynamoDB          | MiniStack (emulated)                      | 4566      |
| Athena + Glue     | MiniStack + **DuckDB** (real SQL engine)  | 4566      |
| Aurora PostgreSQL | MiniStack → real PostgreSQL container     | dynamic   |
| ElastiCache       | MiniStack → real Redis container          | dynamic   |
| Lambda            | MiniStack (emulated)                      | 4566      |

> RDS and ElastiCache spin up real Docker containers. The endpoint (host:port) is retrieved via `aws rds describe-db-instances` / `aws elasticache describe-cache-clusters`.

## Project Layout

```
mini-stack/
├── docker-compose.yml          # Single MiniStack service
├── .env
├── init/
│   ├── aws/                    # AWS resource initialization scripts
│   │   ├── 01-s3.sh            # Create buckets + upload CSV/TXT files
│   │   ├── 02-sns.sh           # Create mini-stack-topic
│   │   ├── 03-sqs.sh           # Create 2 queues + SNS subscription
│   │   ├── 04-dynamodb.sh      # Create tables + insert items
│   │   ├── 05-athena.sh        # Create Glue database + external tables
│   │   ├── 06-rds.sh           # Create RDS PostgreSQL + apply schema/seed
│   │   ├── 07-elasticache.sh   # Create ElastiCache Redis cluster
│   │   ├── 08-lambda.sh        # Package and deploy hello-world Python Lambda
│   │   └── lambda/
│   │       └── hello_world.py  # Python Lambda source
│   └── sql/                    # SQL applied by 06-rds.sh
│       ├── 01-schema.sql
│       └── 02-seed.sql
└── scripts/
    ├── setup.sh                # Bootstrap all services (run once)
    ├── s3-demo.sh
    ├── sns-demo.sh
    ├── sqs-demo.sh
    ├── dynamodb-demo.sh
    ├── athena-demo.sh
    ├── postgres-demo.sh        # Fetches RDS endpoint via AWS CLI
    ├── elasticache-demo.sh     # Fetches ElastiCache endpoint via AWS CLI
    ├── lambda-demo.sh          # Invokes the Python Lambda function
    └── run-all-demos.sh
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
- AWS CLI (`aws configure` with any fake credentials)
- `psql` (for the PostgreSQL/RDS demo)
- `redis-cli` (for the ElastiCache demo)
- `python3` (JSON parsing in sqs-demo)

## Getting Started

```bash
# 1. Start MiniStack
docker compose up -d

# 2. Bootstrap all AWS resources (run once)
chmod +x scripts/*.sh init/aws/*.sh
./scripts/setup.sh
```

## Running the Demos

```bash
# Individual demos
./scripts/s3-demo.sh
./scripts/sns-demo.sh
./scripts/sqs-demo.sh
./scripts/dynamodb-demo.sh
./scripts/athena-demo.sh
./scripts/postgres-demo.sh
./scripts/elasticache-demo.sh
./scripts/lambda-demo.sh

# All at once
./scripts/run-all-demos.sh
```

## AWS CLI Configuration

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

# Verify connectivity
curl http://localhost:4566/_ministack/health
aws --endpoint-url=http://localhost:4566 s3 ls
```

## Stop and Clean Up

```bash
# Stop services (keep volumes)
docker compose down

# Stop and remove all data
docker compose down -v
```
