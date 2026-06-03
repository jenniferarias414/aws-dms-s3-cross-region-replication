# Source Material Handling

This repository documents a completed hands-on AWS data engineering study project.

The goal of the repo is to show the final architecture, implementation notes, validation evidence, troubleshooting, and cleanup steps without including private source material, credentials, or unnecessary setup details.

## What Is Included

This repository includes:

- Architecture diagram
- Lambda source code used for the S3 copy workflow
- SQL seed script for the source MySQL database
- Data flow documentation
- Service-by-service notes
- Troubleshooting notes
- Screenshot guide
- Cost cleanup notes
- Learning notes for reviewing the concepts later

## What Is Not Included

This repository does not include:

- AWS credentials
- Database passwords
- Private keys
- `.env` files
- Personal notes that are not useful to the project
- Private course or training content
- Long copied instructions from external materials

## Screenshots

Screenshots are included as evidence that the project was built and validated.

The screenshots show examples such as:

- RDS MySQL source database setup
- Source data loaded into MySQL
- Source and target S3 buckets
- SNS/SQS/Lambda event flow
- DMS endpoint test success
- DMS task running
- Source and target S3 output files

The screenshots are organized into:

```text
screenshots/full-walkthrough/
screenshots/selected-for-readme/
```

The selected screenshots are used by the main README. The full walkthrough screenshots provide a more complete build record.

## Resource Names

Some AWS resource names are included because they help explain the architecture and validate the screenshots.

These resources were created for the project and later destroyed for cost control.

Examples:

```text
dms-source-mysql
rds-mysql-to-s3-cdc-task
dms-source-retail-jenny-us-east-2
dms-target-retail-jenny-us-west-1
s3-s3-cross-region-migration
s3-s3-migration-queue
s3-s3-migration-copy-lambda
```

## Credentials and Secrets

No credentials or secrets should be committed to this repository.

Do not commit:

```text
.env
*.pem
*.key
AWS access keys
database passwords
connection strings with passwords
```

If credentials are needed to rebuild the project, they should be created locally or stored securely outside the repo.

## Learning Notes

The `learning-notes/` folder is included to break down the project concepts, service flow, and terminology in a more detailed study format.

These notes are meant for review and future learning. They are more beginner-friendly than the main README, but still focused on the same technical workflow.

## Main Takeaway

This repo is meant to document what was built, how the AWS services connected, what proof was captured, what problems were fixed, and how the resources were cleaned up.

It is not meant to store private materials or sensitive AWS configuration.
