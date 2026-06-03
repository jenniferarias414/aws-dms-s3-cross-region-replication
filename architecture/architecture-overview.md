# Architecture Overview

This project demonstrates a database-to-S3 migration and cross-region file replication workflow using AWS managed services.

The architecture has two main parts:

1. AWS DMS moves data from RDS MySQL into a source S3 bucket.
2. S3 event notifications, SNS, SQS, and Lambda copy new output files into a target S3 bucket in another AWS region.

## Architecture Diagram

![AWS DMS S3 Cross-Region Replication Pipeline](architecture-diagram.png)

## High-Level Flow

```text
RDS MySQL
    ↓
AWS DMS full load + CDC
    ↓
Source S3 bucket
    ↓
S3 object-created event
    ↓
SNS topic
    ↓
SQS queue
    ↓
Lambda copy function
    ↓
Target S3 bucket
```

## Source Region: us-east-2

The source side of the architecture was built in `us-east-2`.

It included:

- Amazon RDS for MySQL
- AWS DMS replication instance
- DMS source endpoint
- DMS S3 target endpoint
- Source S3 bucket
- SNS topic

The source database contained a small retail dataset with:

```text
customers
products
orders
```

The source schema was:

```text
dms_source_db
```

AWS DMS read from this database and wrote output files into the source S3 bucket:

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

## Target Region: us-west-1

The target side of the architecture was built in `us-west-1`.

It included:

- SQS queue
- Lambda copy function
- Target S3 bucket

The Lambda function copied new source objects into:

```text
s3://dms-target-retail-jenny-us-west-1/replicated-output/
```

## Why DMS Was Used

AWS DMS was used to handle the database migration work.

The DMS task performed:

| DMS Mode | Purpose |
|---|---|
| Full load | Copy existing source data into S3 |
| CDC | Continue capturing ongoing source changes |

This allowed the project to model a common data engineering pattern: moving operational database data into object storage for downstream use.

## Why S3 Was Used

Amazon S3 acted as the storage layer for database migration output.

The source bucket was the landing zone for DMS output files.

The target bucket represented a replicated copy of the output in another AWS region.

## Why SNS and SQS Were Used

SNS and SQS were used to decouple the event notification from the processing logic.

The event path was:

```text
S3 object-created event → SNS → SQS → Lambda
```

SNS published the notification.

SQS held the message until Lambda processed it.

This pattern helps separate the producer of the event from the worker that handles the event.

## Why Lambda Was Used

Lambda handled the file copy logic.

The function received SQS messages that contained SNS-wrapped S3 events. It parsed the message, found the source bucket and object key, and copied the object into the target S3 bucket.

The function also rewrote the prefix:

```text
dms-output/ → replicated-output/
```

This kept the replicated files organized separately from the original DMS output prefix.

## Design Notes

| Design Choice | Reason |
|---|---|
| RDS MySQL source | Provides a realistic relational source system |
| AWS DMS full load + CDC | Demonstrates both initial migration and ongoing change capture |
| S3 landing bucket | Stores database output as files |
| SNS topic | Publishes object-created events from S3 |
| SQS queue | Buffers event messages before Lambda processing |
| Lambda copy function | Performs custom cross-region object copy logic |
| Separate target bucket | Demonstrates replicated output in another AWS region |

## Final Working State

The completed architecture validated that:

- RDS MySQL source data was loaded.
- DMS connected successfully to the MySQL source endpoint.
- DMS connected successfully to the S3 target endpoint.
- The DMS task reached `Load complete, replication ongoing`.
- DMS output files landed in the source S3 bucket.
- S3 object-created events flowed through SNS and SQS.
- Lambda copied files into the target-region S3 bucket.

## Main Takeaway

This architecture combines database migration and event-driven file processing.

AWS DMS handled the database-to-S3 movement.

S3, SNS, SQS, and Lambda handled the automated cross-region replication of new files.
