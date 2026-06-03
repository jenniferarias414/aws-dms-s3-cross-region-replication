# Project Status

## Current Status

Completed and cleaned up.

This project was built, tested, documented with screenshots, and destroyed in AWS to avoid ongoing cost.

## Final Working Architecture

The completed workflow used:

```text
Amazon RDS MySQL
    ↓
AWS DMS full load + CDC
    ↓
Source S3 bucket in us-east-2
    ↓
S3 object-created event
    ↓
SNS topic in us-east-2
    ↓
SQS queue in us-west-1
    ↓
Lambda function in us-west-1
    ↓
Target S3 bucket in us-west-1
```

## Final Resource Names

| Resource | Name |
|---|---|
| Source RDS MySQL instance | `dms-source-mysql` |
| Source database/schema | `dms_source_db` |
| Source tables | `customers`, `products`, `orders` |
| DMS migration task | `rds-mysql-to-s3-cdc-task` |
| DMS replication instance | `dms-s3-s3-replication-instance` |
| DMS source endpoint | `dms-source-mysql-endpoint` |
| DMS target endpoint | `dms-target-s3-endpoint` |
| Source S3 bucket | `dms-source-retail-jenny-us-east-2` |
| Source S3 prefix | `dms-output/` |
| SNS topic | `s3-s3-cross-region-migration` |
| SQS queue | `s3-s3-migration-queue` |
| Lambda function | `s3-s3-migration-copy-lambda` |
| Target S3 bucket | `dms-target-retail-jenny-us-west-1` |
| Target S3 prefix | `replicated-output/` |

## What Was Validated

The project was validated in several stages.

### 1. Source Database Setup

The RDS MySQL database was created and populated with retail test data.

DBeaver was used as the SQL client to connect to the RDS MySQL source, run SQL setup/validation queries, and confirm the source tables before DMS migration.

Tables used:

```text
customers
products
orders
```

The SQL seed file is stored at:

```text
aws/sql/seed_source_database.sql
```

### 2. DMS Endpoint Connectivity

Both DMS endpoint tests succeeded:

- Source endpoint to RDS MySQL
- Target endpoint to Amazon S3

This confirmed DMS could read from the source database and write output files to the source S3 bucket.

### 3. DMS Migration Task

The DMS migration task was created and fixed after a schema mapping issue.

The final task status reached:

```text
Load complete, replication ongoing
```

This confirmed that the full load completed and the task was still available for ongoing CDC changes.

### 4. Source S3 Output

AWS DMS wrote output files into:

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

Example output paths included:

```text
dms-output/dms_source_db/customers/LOAD00000001.csv
dms-output/dms_source_db/products/LOAD00000001.csv
dms-output/dms_source_db/orders/LOAD00000001.csv
```

### 5. Event-Driven Copy Flow

The source S3 bucket was configured to send object-created notifications to SNS.

The event path was:

```text
S3 event → SNS → SQS → Lambda
```

Lambda then copied new source objects into:

```text
s3://dms-target-retail-jenny-us-west-1/replicated-output/
```

### 6. Target S3 Output

The target bucket contained replicated output files under:

```text
replicated-output/
```

This validated that the cross-region copy flow worked.

## Main Issues Fixed

| Issue | Final Fix |
|---|---|
| DMS task found no tables | Updated DMS mapping to use `dms_source_db` |
| Lambda trigger failed | Set Lambda timeout to match SQS visibility timeout |
| Target objects landed under wrong prefix | Updated Lambda to rewrite `dms-output/` to `replicated-output/` |
| RDS security group rule issue | Used actual security group ID instead of friendly name |
| SNS/SQS cross-region setup confusion | Confirmed topic and queue subscription across regions |

More detail is available in:

```text
docs/troubleshooting.md
```

## Final Cleanup

AWS resources were destroyed after validation.

Deleted resources included:

- RDS MySQL instance
- DMS task
- DMS endpoints
- DMS replication instance
- Lambda function
- SQS queue
- SNS topic
- Source and target S3 buckets
- Project IAM roles
- Project security groups
- Custom RDS parameter group
- Optional CloudWatch logs

Cost cleanup notes are available in:

```text
docs/cost-control.md
```

## Repository Status

This repository documents the completed project with:

- Architecture diagram
- Source SQL
- Lambda copy code
- Data flow notes
- Service-by-service notes
- Troubleshooting notes
- Screenshot guide
- Cost cleanup notes
- Learning notes

## Final Takeaway

The project successfully demonstrated how AWS DMS can move relational database data into Amazon S3, and how event-driven AWS services can copy new S3 output files into another region.

