# Cost Control Notes

This project used several AWS services that can create ongoing cost if they are left running.

The build was tested, screenshots were captured, and the AWS resources were destroyed afterward to avoid unnecessary charges.

## Highest Cost Risks

The main resources to clean up were:

| Resource | Why it matters |
|---|---|
| RDS MySQL instance | Can continue charging while running |
| DMS replication instance | Can continue charging while available/running |
| DMS migration task | Can keep using the replication instance |
| S3 buckets | Storage cost is usually small, but objects should still be removed |
| CloudWatch Logs | Logs can accumulate over time |
| NAT gateways, if used | Can be expensive if accidentally left running |
| Secrets Manager secret, if used | Can create a small recurring cost |

## Resources Deleted

The AWS resources for this project were removed after validation.

Cleanup included:

- DMS migration task
- DMS source endpoint
- DMS target S3 endpoint
- DMS replication instance
- RDS MySQL source database
- Lambda copy function
- SQS queue
- SNS topic
- Source S3 bucket
- Target S3 bucket
- IAM roles created for the project
- Custom RDS parameter group
- Security groups created only for this project
- Optional CloudWatch log groups

## Cleanup Order Used

A safe cleanup order is:

1. Stop or delete the DMS migration task.
2. Delete the DMS endpoints.
3. Delete the DMS replication instance.
4. Delete the RDS MySQL instance.
5. Delete the Lambda function.
6. Delete the SQS queue.
7. Delete the SNS topic.
8. Empty and delete the S3 buckets.
9. Delete IAM roles created only for this project.
10. Delete custom security groups.
11. Delete the custom RDS parameter group.
12. Review CloudWatch log groups and delete project-specific logs if they are no longer needed.

## DMS Cleanup

The DMS migration task used in this project was:

```text
rds-mysql-to-s3-cdc-task
```

The DMS endpoints were:

```text
dms-source-mysql-endpoint
dms-target-s3-endpoint
```

The DMS replication instance was:

```text
dms-s3-s3-replication-instance
```

The DMS replication instance was one of the most important resources to delete because it can continue creating cost while available.

## RDS Cleanup

The RDS MySQL instance used in this project was:

```text
dms-source-mysql
```

For this project, the database was temporary test data, so the instance was deleted after screenshots and validation were complete.

Cleanup choices:

```text
Final snapshot: no
Retain automated backups: no
```

This was appropriate because the source data was sample project data and did not need to be preserved.

## S3 Cleanup

The source bucket was:

```text
dms-source-retail-jenny-us-east-2
```

The target bucket was:

```text
dms-target-retail-jenny-us-west-1
```

The important prefixes were:

```text
dms-output/
replicated-output/
```

Before deleting an S3 bucket, the bucket must be emptied.

## Lambda, SQS, and SNS Cleanup

The event-driven replication resources were also removed:

```text
Lambda function: s3-s3-migration-copy-lambda
SQS queue: s3-s3-migration-queue
SNS topic: s3-s3-cross-region-migration
```

These services are usually low cost for small tests, but they should still be cleaned up when the project is finished.

## IAM Cleanup

Project-specific IAM roles were removed after the AWS services were deleted.

Roles included:

```text
dms-s3-s3-lab-role
s3-s3-migration-lambda-role
```

The project used broad permissions for speed while building and testing. In a production version, permissions should be narrowed to only the required actions and resources.

## CloudWatch Cleanup

CloudWatch Logs were useful for debugging Lambda and DMS behavior.

After the project was complete, project-specific log groups could be deleted if the logs were no longer needed.

Examples:

```text
/aws/lambda/s3-s3-migration-copy-lambda
DMS task or replication logs
```

## Cost-Control Checklist

Before considering the project fully cleaned up, confirm:

- [ ] DMS task deleted
- [ ] DMS endpoints deleted
- [ ] DMS replication instance deleted
- [ ] RDS MySQL instance deleted
- [ ] Lambda function deleted
- [ ] SQS queue deleted
- [ ] SNS topic deleted
- [ ] Source S3 bucket emptied and deleted
- [ ] Target S3 bucket emptied and deleted
- [ ] Project IAM roles deleted
- [ ] Project security groups deleted
- [ ] Custom RDS parameter group deleted
- [ ] CloudWatch logs reviewed or deleted
- [ ] AWS console checked for any remaining project resources

## Main Takeaway

For short-lived AWS learning projects, the safest pattern is:

```text
Build → test briefly → capture screenshots → document proof → destroy resources
```

That keeps the project useful for GitHub while avoiding ongoing AWS charges.
