# How to Explain This Project

These notes break down the project architecture, service flow, and key AWS concepts in a more detailed study format. As I build projects to strengthen my data engineering skills, I like to keep notes on architecture decisions, troubleshooting issues, syntax, terminology, and how the different pieces connect.

The main README gives the project summary and implementation evidence. This file is a follow-along explanation of the workflow, why each service was used, and how the project fits into common data engineering patterns.

## One-Sentence Explanation

This project uses AWS DMS to move data from a MySQL database into S3, then uses SNS, SQS, and Lambda to copy new S3 files into another AWS region.

## Simplified Project Walkthrough

Think of the project in two halves.

First, AWS DMS reads data from a MySQL database and writes output files into an S3 bucket.

Second, when a new file appears in that source S3 bucket, AWS sends a message through SNS and SQS. Lambda reads that message and copies the file into a target S3 bucket in another region.

The basic idea is:

```text
Database data becomes S3 files.
New S3 files create messages.
Messages trigger Lambda.
Lambda copies the files to another region.
```

## The Full Flow

```text
RDS MySQL
    ↓
AWS DMS
    ↓
Source S3 bucket
    ↓
S3 event notification
    ↓
SNS topic
    ↓
SQS queue
    ↓
Lambda function
    ↓
Target S3 bucket
```

## What Each Part Means

### RDS MySQL

RDS is AWS-managed database hosting.

In this project, RDS MySQL was the source database. It represented a small retail system with three tables:

```text
customers
products
orders
```

This was the source system for the project.

### AWS DMS

AWS DMS means AWS Database Migration Service.

DMS is used to move data from one data store to another, especially when the source is a database.

In this project, DMS read from MySQL and wrote files into S3.

It handled two types of movement:

| DMS Mode | Meaning |
|---|---|
| Full load | Copies the existing rows that are already in the database |
| CDC | Continues watching for new changes after the first load |

CDC means change data capture.

That means after the first copy is complete, DMS can continue tracking inserts, updates, and deletes from the source database.

### Source S3 Bucket

The source S3 bucket is where DMS wrote its output files.

In this project:

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

DMS wrote database output files under this prefix:

```text
dms-output/
```

An S3 prefix is basically the folder-like part of an S3 object path.

### S3 Event Notification

S3 can send a notification when something happens in a bucket.

In this project, the important event was:

```text
Object created
```

That means a new file landed in the bucket.

So when DMS wrote a new file into S3, the bucket could send an event notification saying, essentially:

```text
A new object was created.
```

### SNS

SNS is a notification service.

In this project, SNS received the object-created event from the source S3 bucket and published it to its subscriber.

The subscriber was the SQS queue.

A useful way to think about SNS:

```text
Something happened. Send the message to whoever is subscribed.
```

### SQS

SQS is a queue.

A queue holds messages until something is ready to process them.

This matters because Lambda does not have to process the event at the exact second the file lands in S3. The message can wait in SQS until Lambda receives it.

A useful way to think about SQS:

```text
Hold this message until the worker is ready.
```

### Lambda

Lambda is serverless code that runs when triggered.

In this project, Lambda was triggered by SQS.

Lambda’s job was to read the event message, find the new S3 object, and copy that object into the target bucket in another region.

## Architecture Flow vs. Lambda Parsing Flow

This part is easy to mix up, so it helps to separate the two views.

### Architecture Flow

The real event flow happened in this order:

```text
S3 event → SNS → SQS → Lambda
```

That means:

1. S3 created the event.
2. SNS published the event.
3. SQS received and held the message.
4. Lambda processed the message.

### Lambda Parsing Flow

From inside the Lambda code, the order looks reversed because Lambda receives the final wrapped message from SQS.

Lambda receives:

```text
SQS message
    contains SNS message
        contains S3 event
```

So the Lambda code has to parse:

```text
SQS → SNS → S3 event
```

Both views are accurate.

The architecture flow shows how the message travels through AWS.

The parsing flow shows how Lambda unwraps the message after it receives it.

## What Lambda Actually Does

The Lambda function:

1. Receives an event from SQS.
2. Opens the SQS message body.
3. Reads the SNS message inside it.
4. Reads the original S3 event inside the SNS message.
5. Finds the source bucket name.
6. Finds the new S3 object key.
7. Copies the object into the target bucket.
8. Changes the prefix from `dms-output/` to `replicated-output/`.

Source example:

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/file.csv
```

Target example:

```text
s3://dms-target-retail-jenny-us-west-1/replicated-output/file.csv
```

## Why the Bucket Copy Needed a Workflow

The source bucket does not automatically copy new files into the target bucket just because both buckets exist.

Something has to notice the new file, send a message, and run the copy logic.

That is why this project uses this chain:

```text
S3 notices the file
SNS publishes the notification
SQS holds the message
Lambda reads the message
Lambda copies the file
```

Each service has a specific job.

## Why Use SNS and SQS?

SNS and SQS can feel like extra steps at first, but they solve different problems.

### SNS Publishes

SNS is good for publishing notifications.

It answers:

```text
What happened, and who needs to know?
```

### SQS Buffers

SQS is good for holding messages until they are processed.

It answers:

```text
Where can this message wait safely until the worker is ready?
```

### Lambda Processes

Lambda is the worker.

It answers:

```text
What should happen when this message is received?
```

Together:

```text
SNS publishes.
SQS waits.
Lambda works.
```

## What Went Wrong and What Was Fixed

### DMS Could Not Find Tables

DMS connected to the database, but the task could not find the expected tables.

The issue was the schema name.

The actual schema was:

```text
dms_source_db
```

The DMS table mapping had to match that name exactly.

Once the mapping was fixed, the task worked.

### Lambda Timeout Issue

The Lambda timeout was longer than the SQS visibility timeout.

That can cause a problem because SQS might make the message visible again while Lambda is still working on it.

Fix:

```text
Lambda timeout: 30 seconds
```

This matched the SQS visibility timeout used in the project.

### Wrong Target Prefix

At first, copied files landed under the wrong folder path in the target bucket.

The Lambda needed to change:

```text
dms-output/
```

to:

```text
replicated-output/
```

That made the target bucket easier to understand because replicated files were grouped under the target prefix.

## How to Describe This Project

This project built an AWS data replication pipeline using RDS MySQL, AWS DMS, S3, SNS, SQS, and Lambda.

The source was a MySQL database with retail tables. AWS DMS performed a full load and ongoing CDC into an S3 bucket. When DMS created new files in S3, the source bucket sent object-created events to SNS. SNS delivered those messages to SQS, and Lambda was triggered from the queue. The Lambda function parsed the SQS message, unpacked the SNS message inside it, found the original S3 event, and copied the new object into a target S3 bucket in another AWS region.

A key troubleshooting issue was the DMS table mapping. The task initially could not find tables because the mapping referenced the wrong schema. Updating the mapping to the actual schema name, `dms_source_db`, allowed the DMS task to run successfully and reach `Load complete, replication ongoing`.

## Short Project Explanation

This project used AWS DMS to replicate data from RDS MySQL into S3, then used an event-driven AWS flow to copy new DMS output files into another region. S3 sent object-created events to SNS, SNS delivered them to SQS, and Lambda consumed the queue messages to copy files into the target bucket. The project also included troubleshooting around DMS schema mapping, Lambda/SQS timeout settings, and target prefix handling.

## Vocabulary

| Term | Meaning |
|---|---|
| RDS | AWS-managed database service |
| MySQL | Relational database engine |
| DMS | AWS service for moving database data |
| Full load | Initial copy of existing data |
| CDC | Change data capture; keeps tracking new source changes |
| S3 bucket | Cloud object storage container |
| Prefix | Folder-like path inside S3 |
| SNS | Publishes event notifications |
| SQS | Queue that stores messages until processed |
| Lambda | Serverless function that runs code |
| IAM | Permissions system in AWS |
| Endpoint | Connection configuration for a service |
| Replication instance | DMS compute resource that runs the migration |

## Main Takeaway

This project connects two important AWS data engineering patterns.

DMS handled the database-to-S3 migration.

S3, SNS, SQS, and Lambda handled the event-driven file replication.

The most important design idea is that each service has one clear responsibility, and the complete workflow is created by connecting those responsibilities together.
