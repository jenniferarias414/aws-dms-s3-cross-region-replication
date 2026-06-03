# Learning Notes

This folder contains study-focused notes for the AWS DMS S3 cross-region replication project.

The main project README summarizes what was built, the architecture, evidence screenshots, and final outcome. These learning notes go deeper into the concepts behind the project: what each service does, how the services connect, what the important terms mean, and what troubleshooting lessons came up during the build.

## Notes in This Folder

| File | Purpose |
|---|---|
| `how-to-explain-this-project.md` | Follow-along explanation of the full project flow and how the pieces connect |
| `dms-notes.md` | Focused notes on AWS DMS, full load, CDC, endpoints, replication instances, and table mappings |
| `service-by-service-notes.md` | Deeper service notes for RDS, DMS, S3, SNS, SQS, Lambda, IAM, and CloudWatch |

## How These Notes Are Organized

The notes are written to support project review and concept reinforcement.

They cover:

- The overall architecture flow
- What each AWS service contributed
- Why the services were connected in this order
- Important AWS terms and definitions
- DMS full load and CDC behavior
- IAM roles, policies, and service permissions
- Lambda event parsing
- Troubleshooting issues and fixes
- Key lessons from the completed project

## Public Project Docs vs. Learning Notes

The repo has two documentation layers.

### Project Documentation

The `README.md` and `docs/` folder are the project-facing documentation.

They focus on:

- Architecture
- Implementation summary
- Validation evidence
- Troubleshooting
- Cost cleanup
- Final project status

### Learning Notes

The `learning-notes/` folder goes deeper into the concepts.

These notes are meant to explain:

- What the services do
- Why they were used
- How data and messages moved through the system
- What confusing parts were worth breaking down
- How the project connects to common data engineering patterns

## Main Concept Map

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
Lambda function
    ↓
Target S3 bucket
```

## Key Concepts Covered

| Concept | Where to Review |
|---|---|
| Full project flow | `how-to-explain-this-project.md` |
| AWS DMS full load and CDC | `dms-notes.md` |
| DMS endpoints and replication instance | `dms-notes.md` |
| S3 event notifications | `service-by-service-notes.md` |
| SNS and SQS message flow | `service-by-service-notes.md` |
| Lambda event parsing | `how-to-explain-this-project.md` |
| IAM roles and permissions | `service-by-service-notes.md` |
| Troubleshooting lessons | `how-to-explain-this-project.md` and `dms-notes.md` |

## Main Takeaway

This project combines two common AWS data engineering patterns:

1. Moving relational database data into S3 with AWS DMS.
2. Using event-driven AWS services to process and replicate new files.

The learning notes document how those pieces work individually and how they connect into one complete pipeline.
