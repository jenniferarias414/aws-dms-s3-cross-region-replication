# Troubleshooting Notes

This project included several real setup and configuration issues across AWS DMS, RDS, S3, SNS, SQS, and Lambda.

The notes below document what happened, what caused it, and how it was fixed.

## 1. DMS Task Found No Tables

### Symptom

The AWS DMS migration task failed during startup with an error similar to:

```text
No tables were found at task initialization
```

### Root Cause

The DMS table mapping was pointed at the wrong source schema.

The source database used by the working project was:

```text
dms_source_db
```

The original mapping referenced a different schema name, so AWS DMS could connect to the database but could not find the expected tables.

### Fix

Updated the DMS table mapping to use the actual MySQL schema name:

```text
dms_source_db
```

After the mapping was corrected, the DMS task was able to find the `customers`, `products`, and `orders` tables.

### Result

The DMS task reached:

```text
Load complete, replication ongoing
```

---

## 2. Lambda Trigger Failed Because of Timeout Settings

### Symptom

Adding the SQS queue as a Lambda trigger failed because the Lambda timeout was longer than the SQS visibility timeout.

### Root Cause

The Lambda function timeout had been set to 60 seconds, while the SQS visibility timeout was 30 seconds.

For SQS-triggered Lambda functions, the Lambda timeout should not be longer than the queue visibility timeout. Otherwise, the same message could become visible again while the function is still processing it.

### Fix

Changed the Lambda timeout back to:

```text
30 seconds
```

### Result

The SQS trigger was successfully added to the Lambda function.

---

## 3. Target Bucket Initially Used the Wrong Prefix

### Symptom

A test object copied successfully, but it landed in the target bucket under the same source prefix.

The source path was:

```text
dms-output/
```

The target path needed to be:

```text
replicated-output/
```

### Root Cause

The first Lambda copy logic reused the original source object key directly.

That meant the target bucket kept the `dms-output/` prefix instead of placing copied objects under the intended target prefix.

### Fix

Updated the Lambda code to rewrite the prefix:

```text
dms-output/ → replicated-output/
```

Relevant Lambda behavior:

```python
if source_key.startswith(SOURCE_PREFIX):
    target_key = source_key.replace(SOURCE_PREFIX, TARGET_PREFIX, 1)
else:
    target_key = f"{TARGET_PREFIX}{source_key}"
```

### Result

New source files copied into the target bucket under:

```text
replicated-output/
```

---

## 4. Security Group Source Field Rejected Friendly Name

### Symptom

While allowing the DMS replication instance to reach the RDS MySQL database, the security group rule did not accept the friendly security group name.

### Root Cause

The inbound rule needed a valid CIDR range or an actual security group ID.

A friendly name such as `dms-replication` was not enough.

### Fix

Used the actual DMS replication instance security group ID in the RDS security group inbound rule.

The rule allowed MySQL traffic:

```text
TCP 3306
```

### Result

AWS DMS could connect to the RDS MySQL source endpoint successfully.

---

## 5. SNS and SQS Cross-Region Setup Was Confusing

### Symptom

The SNS topic did not immediately appear as expected while configuring the SQS subscription.

### Root Cause

The project used two AWS regions:

| Service | Region |
|---|---|
| SNS topic | `us-east-2` |
| SQS queue | `us-west-1` |

Because the topic and queue were in different regions, the AWS console flow was less obvious than a same-region setup.

### Fix

Confirmed the SNS topic and SQS queue were connected correctly with an SNS subscription to the SQS queue.

### Result

The SQS subscription was confirmed, and S3 object-created events were able to flow through SNS into SQS.

---

## 6. DMS Console Navigation Was Different Than Expected

### Symptom

The AWS DMS console layout did not match some expected navigation steps.

For example, the console showed areas such as instance profiles instead of immediately showing the expected replication instance workflow.

### Root Cause

The AWS console UI had a newer layout than the instructions being followed.

### Fix

Used the DMS migration workflow directly:

```text
AWS DMS → Migrate data → Replication instances
```

### Result

The DMS replication instance was created successfully and became available.

---

## 7. DMS Endpoint Form Looked Different Than Expected

### Symptom

The DMS target endpoint setup did not show the expected field labels in the same order.

### Root Cause

The AWS DMS console UI displayed the S3 bucket selection first, then the IAM role selection.

### Fix

Selected the existing DMS IAM role used for S3 access:

```text
dms-s3-s3-lab-role
```

### Result

The DMS target S3 endpoint test succeeded.

---

## Final Working State

The final working state included:

- RDS MySQL source database created
- Source tables loaded and validated
- DMS source endpoint test successful
- DMS S3 target endpoint test successful
- DMS migration task running
- DMS task status reached `Load complete, replication ongoing`
- DMS output files landed in the source S3 bucket
- S3 object-created events flowed through SNS and SQS
- Lambda copied new files to the target-region S3 bucket

