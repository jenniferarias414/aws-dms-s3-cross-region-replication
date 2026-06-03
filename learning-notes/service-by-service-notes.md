# Service-by-Service Study Notes

These notes explain the AWS services used in this project, what each service did, how the services connected, and why the setup required IAM permissions between them.

The project had two main sections:

1. Move database data from RDS MySQL into S3 using AWS DMS.
2. Copy new S3 output files into another AWS region using S3 events, SNS, SQS, and Lambda.

## Full Service Flow

```text
RDS MySQL
    ↓
AWS DMS
    ↓
Source S3 bucket
    ↓
S3 object-created event
    ↓
SNS topic
    ↓
SQS queue
    ↓
Lambda function
    ↓
Target S3 bucket
```

## Quick Responsibility Map

| Service | Main Job in This Project |
|---|---|
| RDS MySQL | Stored the source relational data |
| AWS DMS | Read database rows and changes, then wrote output files to S3 |
| DMS replication instance | Ran the DMS migration task |
| DMS source endpoint | Defined the connection to MySQL |
| DMS target endpoint | Defined the output location in S3 |
| Source S3 bucket | Stored DMS output files |
| S3 event notification | Started the event flow when new files landed |
| SNS | Published the S3 event message |
| SQS | Held the message until Lambda processed it |
| Lambda | Copied the new S3 object to the target bucket |
| Target S3 bucket | Stored the replicated output in another region |
| IAM | Controlled which services were allowed to access each other |
| CloudWatch Logs | Helped confirm what happened during runtime |

## Amazon RDS for MySQL

Amazon RDS is AWS-managed database hosting.

In this project, RDS MySQL was the source database. It represented a small transactional retail database.

Tables used:

```text
customers
products
orders
```

Source schema:

```text
dms_source_db
```

A source database is where the original data starts.

In real data engineering work, this could represent an application database, order system, customer database, inventory system, or any relational system that needs to feed analytics or storage downstream.

### Why RDS mattered in this project

DMS needed a real database source to read from.

The project was not just copying one file from one bucket to another. The first half of the project was about moving relational database data into object storage.

That is why RDS was the starting point.

```text
RDS = source system
DMS = service that extracts from the source system
S3 = landing zone for extracted output
```

## AWS DMS

AWS DMS means AWS Database Migration Service.

DMS is used to move data from one data store to another.

In this project, DMS moved data from:

```text
Amazon RDS for MySQL
```

to:

```text
Amazon S3
```

DMS handled the database migration part of the project.

### What DMS did

DMS performed:

| DMS Feature | Meaning |
|---|---|
| Full load | Copied the existing rows from the source tables |
| CDC | Continued capturing changes after the first load |

Full load means:

```text
Take the data that already exists and copy it.
```

CDC means change data capture.

CDC means:

```text
After the first copy, keep watching for inserts, updates, and deletes.
```

### Why DMS mattered

Without DMS, the project would need custom code to:

- Connect to MySQL
- Read table data
- Track new changes
- Write files to S3
- Handle ongoing source changes

DMS handles a lot of that database migration work as a managed AWS service.

## DMS Replication Instance

The DMS replication instance is the compute resource that runs the migration task.

A simple way to think about it:

```text
DMS replication instance = the worker machine behind the migration
```

It needs to reach both sides:

```text
Source: RDS MySQL
Target: S3
```

For the source database, it needed network access to MySQL on:

```text
Port 3306
```

### Why this got confusing

The DMS replication instance is not the same thing as the DMS task.

The replication instance is the worker.

The task is the job instructions.

```text
Replication instance = worker
Migration task = what the worker should do
Endpoints = where the worker connects
```

## DMS Source Endpoint

The DMS source endpoint tells DMS how to connect to the source database.

For this project, the source endpoint pointed to RDS MySQL.

The source endpoint included connection details like:

- Database engine
- Server/host
- Port
- Username
- Password or secret
- Database/schema information

A successful source endpoint test meant:

```text
DMS can connect to MySQL.
```

That does not automatically mean the task mappings are correct. It only proves the connection works.

This distinction mattered because the source endpoint test succeeded, but the DMS task still failed at first when the table mapping referenced the wrong schema.

## DMS Target Endpoint

The DMS target endpoint tells DMS where to write the migrated output.

For this project, the target endpoint was S3.

DMS wrote output files into:

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

A successful target endpoint test meant:

```text
DMS can write to the S3 landing bucket.
```

### Why this matters

DMS needs permission to write files into the bucket.

That is where IAM comes in. DMS cannot just write to S3 automatically. It needs an IAM role that allows the required S3 actions.

## Amazon S3

Amazon S3 is AWS object storage.

This project used two S3 buckets.

### Source S3 Bucket

The source bucket received DMS output files.

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

Region:

```text
us-east-2
```

This bucket was the landing zone for the database migration output.

Key idea:

```text
DMS wrote files here first.
```

### Target S3 Bucket

The target bucket received replicated copies of the source files.

```text
s3://dms-target-retail-jenny-us-west-1/replicated-output/
```

Region:

```text
us-west-1
```

Key idea:

```text
Lambda copied files here.
```

### Why use two buckets?

The project was designed to show cross-region replication behavior.

The source bucket and target bucket were in different AWS regions:

```text
Source: us-east-2
Target: us-west-1
```

That made the project more realistic for patterns like:

- Regional backup
- Disaster recovery
- Cross-region data availability
- Separating landing and replicated outputs

## S3 Event Notification

S3 event notifications let a bucket send a message when something happens.

In this project, the important event was:

```text
Object created
```

That means a new file landed in the source bucket.

When DMS wrote new files into the source bucket, S3 sent an event notification to SNS.

Key idea:

```text
S3 noticed the new file and started the downstream workflow.
```

### Important concept

S3 did not copy the file itself.

S3 only announced that a new file was created.

The copy work was done later by Lambda.

```text
S3 = detects event
SNS/SQS = message path
Lambda = does the copy
```

## Amazon SNS

SNS means Simple Notification Service.

SNS publishes messages to subscribers.

In this project:

```text
S3 sent an object-created event to SNS.
SNS published that message to SQS.
```

SNS topic:

```text
s3-s3-cross-region-migration
```

A useful way to think about SNS:

```text
Something happened. Send this notification to whoever subscribed.
```

### Why SNS was used

SNS is good for fan-out and event publishing.

Even though this project had one SQS subscriber, SNS makes the event flow more flexible. In a larger design, the same event could be sent to multiple subscribers.

For example:

```text
S3 event
    ↓
SNS
    ↓
SQS for Lambda copy
    ↓
Another subscriber for alerting
    ↓
Another subscriber for audit processing
```

## Amazon SQS

SQS means Simple Queue Service.

SQS holds messages until a consumer is ready to process them.

In this project:

```text
SNS delivered the event message to SQS.
Lambda was triggered by SQS.
```

SQS queue:

```text
s3-s3-migration-queue
```

A useful way to think about SQS:

```text
This message can wait here safely until the worker is ready.
```

### Why SQS was used

SQS creates a buffer between the event notification and the processing code.

That matters because Lambda does not have to process every event at the exact second it arrives.

SQS helps with:

- Message buffering
- Retry behavior
- Decoupling services
- Reducing tight dependency between publisher and worker

Key idea:

```text
SNS publishes.
SQS holds.
Lambda processes.
```

## AWS Lambda

Lambda runs code without managing a server.

In this project, Lambda was the worker that copied new S3 files from the source bucket to the target bucket.

Lambda function:

```text
s3-s3-migration-copy-lambda
```

Lambda was triggered by SQS.

### What Lambda received

Lambda did not receive the S3 event directly.

Lambda received an SQS event.

Inside the SQS message was an SNS message.

Inside the SNS message was the original S3 event.

That nesting looked like this:

```text
SQS message
    contains SNS message
        contains S3 object-created event
```

### Architecture flow vs. parsing flow

The AWS architecture flow was:

```text
S3 event → SNS → SQS → Lambda
```

The Lambda parsing flow was:

```text
SQS → SNS → S3 event
```

Both are correct.

The architecture flow explains how the message traveled.

The parsing flow explains how Lambda unpacked the message after receiving it.

### What Lambda did

Lambda performed these steps:

1. Read the SQS event.
2. Parsed the SQS message body.
3. Parsed the SNS message inside it.
4. Parsed the original S3 event.
5. Found the source bucket name.
6. Found the source object key.
7. Copied the object to the target bucket.
8. Rewrote the prefix.

Prefix rewrite:

```text
dms-output/ → replicated-output/
```

This kept the target bucket organized.

## IAM

IAM means Identity and Access Management.

IAM controls who or what is allowed to do things in AWS.

This was one of the more confusing parts because every service interaction needed permission.

The general idea:

```text
A service can only do what IAM allows it to do.
```

## Why IAM Was Needed

The services in this project had to interact with each other.

Examples:

- DMS needed to write to S3.
- S3 needed to publish an event to SNS.
- SNS needed to send a message to SQS.
- Lambda needed to read from SQS.
- Lambda needed to read from the source S3 bucket.
- Lambda needed to write to the target S3 bucket.
- Lambda needed to write logs to CloudWatch.

None of those permissions are automatic.

IAM is what allows the services to communicate safely.

## IAM Roles vs. IAM Policies

This is an important distinction.

### IAM Role

An IAM role is an identity that an AWS service can assume.

A simple way to think about it:

```text
Role = who the service is allowed to act as
```

Example:

```text
Lambda uses a Lambda execution role.
DMS uses a DMS service role.
```

### IAM Policy

An IAM policy defines what actions are allowed.

A simple way to think about it:

```text
Policy = what the role is allowed to do
```

Example permissions:

```text
s3:GetObject
s3:PutObject
sqs:ReceiveMessage
logs:CreateLogStream
logs:PutLogEvents
```

Together:

```text
Role = identity
Policy = permissions
```

## IAM in This Project

### DMS IAM Role

DMS needed an IAM role so it could write output files to S3.

Project role:

```text
dms-s3-s3-lab-role
```

DMS needed S3 permissions for the bucket/prefix where it wrote output files.

Conceptually, DMS needed permissions like:

```text
s3:PutObject
s3:ListBucket
s3:GetBucketLocation
```

### Lambda IAM Role

Lambda needed an execution role.

Project role:

```text
s3-s3-migration-lambda-role
```

Lambda needed permissions to:

- Read messages from SQS
- Read/copy objects from the source bucket
- Write objects to the target bucket
- Write logs to CloudWatch

Conceptually, Lambda needed permissions like:

```text
sqs:ReceiveMessage
sqs:DeleteMessage
sqs:GetQueueAttributes
s3:GetObject
s3:PutObject
logs:CreateLogGroup
logs:CreateLogStream
logs:PutLogEvents
```

### SNS to SQS Permission

The SQS queue also needed to allow SNS to send messages to it.

This is usually handled with an SQS access policy.

Conceptually:

```text
Allow this SNS topic to send messages to this SQS queue.
```

### S3 to SNS Permission

The S3 bucket needed to be able to publish event notifications to SNS.

Conceptually:

```text
Allow this S3 bucket to publish object-created events to this SNS topic.
```

## Why IAM Felt Confusing

IAM felt confusing because the project was not just one service calling one other service.

It was a chain of services:

```text
DMS → S3
S3 → SNS
SNS → SQS
SQS → Lambda
Lambda → S3
Lambda → CloudWatch
```

Each arrow required the right permissions.

If one permission was missing, the flow could break at that step.

A helpful way to debug IAM is to ask:

```text
Which service is trying to do what action on which resource?
```

Examples:

```text
DMS is trying to PutObject into the source S3 bucket.
Lambda is trying to ReceiveMessage from SQS.
Lambda is trying to PutObject into the target S3 bucket.
SNS is trying to SendMessage to SQS.
```

That question makes IAM less abstract.

## CloudWatch Logs

CloudWatch Logs stores logs from AWS services.

In this project, CloudWatch helped confirm Lambda behavior.

CloudWatch could show:

- Lambda received the event
- Lambda printed the incoming message
- Lambda parsed the bucket and object key
- Lambda attempted the copy
- Lambda completed successfully
- Lambda hit an error or timeout

Key idea:

```text
CloudWatch shows what happened after the service ran.
```

For event-driven systems, logs are especially important because the services pass messages in the background.

## How the Services Passed Work to Each Other

This project is a good example of services handing work from one step to the next.

```text
RDS stores the data.
DMS reads the data.
DMS writes files to S3.
S3 notices the new file.
SNS publishes the notification.
SQS holds the notification.
Lambda reads the notification.
Lambda copies the file.
Target S3 stores the copy.
```

## What Each Service Did Not Do

Sometimes it helps to understand the boundaries.

| Service | What it did | What it did not do |
|---|---|---|
| RDS | Stored source data | Did not write files to target S3 |
| DMS | Moved database data into source S3 | Did not manage the SNS/SQS/Lambda copy flow |
| S3 | Stored files and emitted events | Did not run custom copy logic |
| SNS | Published notifications | Did not store messages long-term |
| SQS | Held messages | Did not copy files |
| Lambda | Copied files | Did not migrate database rows |
| IAM | Controlled permissions | Did not process data |
| CloudWatch | Stored logs | Did not fix errors automatically |

## Quick Memory Version

```text
RDS = source database
DMS = database migration service
DMS replication instance = worker running the migration
DMS source endpoint = connection to MySQL
DMS target endpoint = connection to S3
Source S3 = landing zone for DMS files
S3 event = notification that a new file exists
SNS = event publisher
SQS = message buffer
Lambda = copy worker
Target S3 = replicated output
IAM = permissions
CloudWatch = logs
```

## Main Takeaway

This project worked because each service had one clear responsibility.

DMS handled the database migration into S3.

S3, SNS, SQS, and Lambda handled the event-driven cross-region file copy.

IAM connected the services safely by giving each part permission to do its job.

CloudWatch helped confirm what happened during runtime.

The biggest learning point is that the architecture is not one giant service doing everything. It is a chain of smaller AWS services, each responsible for one part of the workflow.
