# Screenshot Guide

This folder contains proof screenshots from the AWS DMS S3 cross-region replication project.

The full walkthrough screenshots show the build from setup through validation. A smaller set of screenshots is copied into `screenshots/selected-for-readme/` for the main README.

## Screenshot Folders

| Folder | Purpose |
|---|---|
| `screenshots/full-walkthrough/` | Full project build evidence from start to finish |
| `screenshots/selected-for-readme/` | Smaller set of key screenshots used by the main README |

## Selected README Screenshots

These are the strongest screenshots for explaining the completed project.

| Screenshot | What it proves |
|---|---|
| `01-rds-mysql-instance-created.png` | Amazon RDS for MySQL source database was created in the source region |
| `02-rds-source-data-loaded.png` | Source database tables were loaded and validated with SQL |
| `03-source-and-target-s3-buckets-created.png` | Source and target S3 buckets existed in separate AWS regions |
| `07-lambda-sqs-trigger-created.png` | Lambda was connected to the SQS queue trigger |
| `08-s3-event-notification-configured.png` | Source S3 bucket was configured to send object-created events to SNS |
| `12-dms-source-endpoint-test-success.png` | AWS DMS successfully connected to the RDS MySQL source endpoint |
| `13-dms-target-s3-endpoint-test-success.png` | AWS DMS successfully connected to the S3 target endpoint |
| `18-dms-task-cdc-running.png` | AWS DMS task reached load complete with replication ongoing |
| `19-cdc-files-replicated-target-bucket.png` | New output files were copied into the target-region S3 bucket |

## Full Walkthrough Screenshot List

| Screenshot | What it shows |
|---|---|
| `01-rds-mysql-instance-created.png` | RDS MySQL instance was created and available |
| `02-rds-source-data-loaded.png` | Source tables and row counts were validated |
| `03-source-and-target-s3-buckets-created.png` | Source bucket in `us-east-2` and target bucket in `us-west-1` were created |
| `04-dms-s3-s3-iam-role-created.png` | IAM role for DMS/S3 access was created |
| `05-sns-topic-sqs-subscription-created.png` | SNS topic was subscribed to the SQS queue |
| `06-lambda-iam-role-created.png` | Lambda execution role was created |
| `07-lambda-sqs-trigger-created.png` | SQS trigger was added to the Lambda function |
| `08-s3-event-notification-configured.png` | S3 event notification was configured on the source bucket |
| `09-cross-region-lambda-copy-test-success.png` | Manual test file copied from source S3 to target S3 through Lambda |
| `10-dms-replication-instance-available.png` | DMS replication instance was created and available |
| `11-dms-replication-instance-and-rds-access-configured.png` | RDS security group access was configured for DMS |
| `12-dms-source-endpoint-test-success.png` | DMS source endpoint connection test succeeded |
| `13-dms-target-s3-endpoint-test-success.png` | DMS target S3 endpoint connection test succeeded |
| `14-dms-database-migration-task-created.png` | DMS migration task was created |
| `15-dms-task-fixed-and-running.png` | DMS task was fixed and running after table mapping changes |
| `15-source-s3-dms-output-files-created.png` | DMS wrote full-load output files into the source S3 bucket |
| `16-target-s3-replicated-output-files-created.png` | Lambda copied DMS output files into the target S3 bucket |
| `17-cdc-source-data-change-run.png` | Source database change was made for CDC validation |
| `18-dms-task-cdc-running.png` | DMS task continued running after CDC changes |
| `19-cdc-files-replicated-target-bucket.png` | CDC output files were replicated into the target-region bucket |

## Evidence Summary

The screenshots prove the project worked end-to-end:

1. A source RDS MySQL database was created and loaded with data.
2. AWS DMS connected successfully to the source database.
3. AWS DMS connected successfully to the S3 target endpoint.
4. DMS wrote database output files into the source S3 bucket.
5. S3 object-created events triggered the messaging flow.
6. SNS delivered events to SQS.
7. Lambda consumed the SQS messages.
8. Lambda copied files into the target-region S3 bucket.
9. Resources were tested, documented, and cleaned up for cost control.

