# Service-by-Service Notes

This document explains the main AWS services used in the project and how each one contributed to the final data flow.

## Service Summary

| Service | Role in This Project |
|---|---|
| Amazon RDS for MySQL | Source relational database |
| AWS DMS | Migrated full-load and CDC data from MySQL to S3 |
| Amazon S3 | Stored source DMS output files and target replicated files |
| Amazon SNS | Published S3 object-created event notifications |
| Amazon SQS | Buffered event messages before Lambda processing |
| AWS Lambda | Copied new S3 objects from the source bucket to the target bucket |
| IAM | Controlled permissions between services |
| CloudWatch Logs | Supported troubleshooting and runtime visibility |

---

## Amazon RDS for MySQL

Amazon RDS for MySQL was used as the source database.

The source database represented a small transactional retail system with three tables:

- `customers`
- `products`
- `orders`

The database schema used for the working project was:

```text
dms_source_db
```

This schema name mattered because AWS DMS table mappings had to match the actual MySQL database/schema name.

## AWS Database Migration Service

AWS Database Migration Service, or AWS DMS, was used to move data from RDS MySQL into Amazon S3.

The DMS setup included:

- DMS replication instance
- DMS source endpoint for MySQL
- DMS target endpoint for S3
- DMS migration task

The migration task performed:

- Full load of existing source data
- Ongoing CDC replication for new changes

The DMS task reached:

```text
Load complete, replication ongoing
```

That confirmed the initial load completed and the task was still running for ongoing changes.

## DMS Replication Instance

The DMS replication instance provided the compute resources needed to run the migration task.

It connected to:

1. The RDS MySQL source endpoint
2. The S3 target endpoint

The replication instance had to be able to reach the RDS database over MySQL port `3306`.

## DMS Source Endpoint

The DMS source endpoint defined how DMS connected to the RDS MySQL database.

The successful source endpoint proved that DMS could reach and authenticate to the MySQL source.

## DMS Target S3 Endpoint

The DMS target endpoint defined where DMS wrote migrated data in Amazon S3.

DMS wrote files into the source-region S3 bucket under:

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

## Amazon S3

Amazon S3 was used in two places.

### Source S3 Bucket

The source bucket received files written by AWS DMS.

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

This bucket was in:

```text
us-east-2
```

### Target S3 Bucket

The target bucket received replicated copies of new files.

```text
s3://dms-target-retail-jenny-us-west-1/replicated-output/
```

This bucket was in:

```text
us-west-1
```

The target bucket used a different prefix so replicated files were easy to identify.

## Amazon SNS

Amazon SNS was used to publish S3 object-created notifications.

When a new object was created under the source S3 prefix, the S3 bucket sent an event notification to the SNS topic.

The SNS topic used in the project was:

```text
s3-s3-cross-region-migration
```

SNS was useful because it allowed the source bucket event to be published to a subscriber instead of tying the event directly to one consumer.

## Amazon SQS

Amazon SQS was used as the message buffer between SNS and Lambda.

The SQS queue used in the project was:

```text
s3-s3-migration-queue
```

The queue received messages from SNS and then triggered Lambda.

This helped decouple the event publisher from the processing function. If Lambda was not able to process immediately, the message could wait in the queue.

## AWS Lambda

AWS Lambda performed the cross-region copy logic.

The Lambda function was triggered by SQS.

The event path was:

```text
S3 object-created event
    ↓
SNS topic
    ↓
SQS queue
    ↓
Lambda function
```

The Lambda function received the message in nested form:

```text
SQS message
    contains SNS message
        contains S3 object-created event
```

The function parsed the message, found the source bucket and object key, then copied the object into the target bucket.

The Lambda also rewrote the prefix:

```text
dms-output/ → replicated-output/
```

This prevented replicated files from landing under the original source prefix in the target bucket.

## IAM

IAM roles and permissions allowed AWS services to interact with each other.

The project used IAM for:

- DMS access to RDS and S3
- Lambda access to SQS and S3
- S3 event notification access to SNS
- SNS delivery to SQS
- CloudWatch logging

For the project build, broad managed policies were used for speed. In a production environment, these permissions should be narrowed to specific resources and actions.

## CloudWatch Logs

CloudWatch Logs were used for visibility and troubleshooting.

CloudWatch helped confirm:

- Lambda received the event
- Lambda parsed the message
- Lambda attempted the copy
- Lambda completed the copy successfully

CloudWatch logs are especially useful in event-driven systems because several services are passing messages to each other behind the scenes.

## How the Services Work Together

The services work together in this order:

```text
RDS MySQL
    ↓
AWS DMS
    ↓
Source S3 bucket
    ↓
SNS
    ↓
SQS
    ↓
Lambda
    ↓
Target S3 bucket
```

Each service has a specific job:

| Layer | Service | Responsibility |
|---|---|---|
| Source | RDS MySQL | Stores source transactional data |
| Migration | AWS DMS | Extracts full-load and CDC data |
| Landing | S3 | Stores DMS output files |
| Notification | SNS | Publishes object-created events |
| Buffering | SQS | Holds messages for Lambda |
| Processing | Lambda | Copies objects across regions |
| Target | S3 | Stores replicated output files |

## Main Takeaway

This project shows how managed AWS services can be combined into a practical data movement pattern.

AWS DMS handled the database migration work.

S3, SNS, SQS, and Lambda handled the event-driven file replication work.

Together, they created a simple pipeline for moving database output files into S3 and copying them into another AWS region.
