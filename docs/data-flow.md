# Data Flow

This project moves data from a source MySQL database into Amazon S3, then copies new S3 output files into a target bucket in another AWS region.

The flow has two major parts:

1. Database migration into S3 using AWS DMS
2. Event-driven cross-region file copy using S3, SNS, SQS, and Lambda

## High-Level Flow

```text
Amazon RDS MySQL
    ↓
AWS DMS full load + CDC task
    ↓
Source S3 bucket: dms-output/
    ↓
S3 object-created event
    ↓
Amazon SNS topic
    ↓
Amazon SQS queue
    ↓
AWS Lambda copy function
    ↓
Target S3 bucket: replicated-output/
```

## Part 1: RDS MySQL to S3 with AWS DMS

The source system is an Amazon RDS for MySQL database in `us-east-2`.

The source database contains three retail-style tables:

- `customers`
- `products`
- `orders`

AWS DMS connects to the MySQL database through a source endpoint. It also connects to Amazon S3 through a target endpoint.

The DMS task performs:

- Full load of existing source data
- Ongoing CDC replication for new source changes

DMS writes output files into the source S3 bucket:

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

## Part 2: S3 Event to SNS

When AWS DMS writes a new file into the source S3 bucket, the bucket creates an object-created event.

That event is sent to an SNS topic in the source region.

```text
Source S3 bucket
    ↓
S3 object-created event
    ↓
SNS topic
```

The SNS topic used for the project was:

```text
s3-s3-cross-region-migration
```

## Part 3: SNS to SQS

The SNS topic sends the event message to an SQS queue.

The SQS queue gives the pipeline a buffer between the event notification and the Lambda function.

This is useful because Lambda does not need to process the event at the exact moment it is created. The message can wait safely in the queue until Lambda receives it.

```text
SNS topic
    ↓
SQS queue
```

The SQS queue used for the project was:

```text
s3-s3-migration-queue
```

## Part 4: SQS to Lambda

The Lambda function is triggered by the SQS queue.

The Lambda function receives an SQS event. Inside that SQS message is an SNS message. Inside the SNS message is the original S3 object-created event.

The message nesting looks like this:

```text
SQS message
    contains SNS message
        contains S3 object-created event
```

The Lambda function parses through those layers to find:

- Source S3 bucket name
- Source S3 object key

## Part 5: Lambda Copies the File

After Lambda finds the source bucket and source object key, it copies the object to the target-region S3 bucket.

Source path:

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

Target path:

```text
s3://dms-target-retail-jenny-us-west-1/replicated-output/
```

The Lambda function rewrites the prefix:

```text
dms-output/ → replicated-output/
```

This keeps the target bucket organized and makes it clear that the files are replicated output files.

## Why SNS and SQS Are Both Used

This project uses both SNS and SQS because they do different jobs.

| Service | Job |
|---|---|
| SNS | Publishes the S3 event notification |
| SQS | Holds the message until Lambda processes it |
| Lambda | Reads the queued message and copies the S3 object |

SNS is good for publishing an event to one or more subscribers.

SQS is good for buffering work so the consumer does not have to process everything immediately.

Together, they create a more reliable event-driven flow than calling Lambda directly from every source event.

## Final Output

The final output of the pipeline is a replicated S3 object in the target AWS region.

```text
s3://dms-target-retail-jenny-us-west-1/replicated-output/
```

## What This Proves

This data flow proves that:

1. AWS DMS can migrate data from RDS MySQL into S3.
2. DMS can continue running for CDC after the initial full load.
3. S3 object-created events can start an event-driven workflow.
4. SNS can publish the event notification.
5. SQS can buffer the message for Lambda.
6. Lambda can parse the event and copy the new file.
7. The final file can land in a separate AWS region.
