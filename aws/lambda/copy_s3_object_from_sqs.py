"""
Lambda function for event-driven S3 object replication.

This function is triggered by SQS messages that contain SNS-wrapped
S3 object-created events. It copies new objects from the source DMS
output prefix into a target S3 bucket/prefix in another AWS region.
"""

import json
import urllib.parse

import boto3


s3 = boto3.client("s3")

TARGET_BUCKET = "dms-target-retail-jenny-us-west-1"
SOURCE_PREFIX = "dms-output/"
TARGET_PREFIX = "replicated-output/"


def lambda_handler(event, context):
    """
    Copy new S3 objects from the source-region bucket to the target-region bucket.

    Event path:
    S3 event notification -> SNS topic -> SQS queue -> Lambda

    The SQS message body contains an SNS message.
    The SNS message contains the original S3 event.

    Source example:
    s3://dms-source-retail-jenny-us-east-2/dms-output/file.csv

    Target example:
    s3://dms-target-retail-jenny-us-west-1/replicated-output/file.csv
    """

    print("Received event:")
    print(json.dumps(event))

    for record in event.get("Records", []):
        # SQS body is a JSON string containing the SNS message.
        sqs_body = json.loads(record["body"])

        # SNS Message is another JSON string containing the original S3 event.
        s3_event = json.loads(sqs_body["Message"])

        for s3_record in s3_event.get("Records", []):
            source_bucket = s3_record["s3"]["bucket"]["name"]

            # S3 event keys can be URL encoded, so decode before copying.
            source_key = urllib.parse.unquote_plus(
                s3_record["s3"]["object"]["key"]
            )

            # Keep the file name/path, but move it from dms-output/ to replicated-output/.
            if source_key.startswith(SOURCE_PREFIX):
                target_key = source_key.replace(SOURCE_PREFIX, TARGET_PREFIX, 1)
            else:
                target_key = f"{TARGET_PREFIX}{source_key}"

            print(f"Copying from: s3://{source_bucket}/{source_key}")
            print(f"Copying to:   s3://{TARGET_BUCKET}/{target_key}")

            copy_source = {
                "Bucket": source_bucket,
                "Key": source_key,
            }

            s3.copy_object(
                Bucket=TARGET_BUCKET,
                CopySource=copy_source,
                Key=target_key,
            )

            print(f"Copied file successfully to: {target_key}")

    return {
        "statusCode": 200,
        "body": "S3 object copy process completed successfully."
    }