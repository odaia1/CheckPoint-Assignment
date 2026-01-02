import os
import json
import time
from typing import Any, Dict
from datetime import datetime
import uuid
import boto3
from botocore.exceptions import ClientError
from dateutil import parser as date_parser



AWS_REGION = os.getenv("AWS_REGION", "eu-central-1")
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL", "")
S3_BUCKET = os.getenv("S3_BUCKET", "")
S3_PREFIX = os.getenv("S3_PREFIX", "events")
POLL_INTERVAL_SECONDS = int(os.getenv("POLL_INTERVAL_SECONDS", "5"))
MAX_MESSAGES_PER_POLL = int(os.getenv("MAX_MESSAGES_PER_POLL", "5"))
VISIBILITY_TIMEOUT = int(os.getenv("VISIBILITY_TIMEOUT", "30"))
WAIT_TIME_SECONDS = int(os.getenv("WAIT_TIME_SECONDS", "10"))

if not SQS_QUEUE_URL:
    raise SystemExit("SQS_QUEUE_URL is required")
if not S3_BUCKET:
    raise SystemExit("S3_BUCKET is required")

sqs = boto3.client("sqs", region_name=AWS_REGION)
s3 = boto3.client("s3", region_name=AWS_REGION)


def parse_message(body: str) -> Dict[str, Any]:
    data = json.loads(body)
    if not isinstance(data, dict):
        raise ValueError("Message body must be a JSON object")
    return data

def build_s3_key() -> str:
    today = datetime.utcnow().strftime("%Y-%m-%d")
    uid = uuid.uuid4().hex
    return f"{S3_PREFIX}/{today}/{uid}.json"

def upload_to_s3(msg: Dict[str, Any]) -> str:
    key = build_s3_key()
    body = json.dumps(msg)
    s3.put_object(
        Bucket=S3_BUCKET,
        Key=key,
        Body=body,
        ContentType="application/json",
    )
    return key


def poll_once() -> int:
    try:
        resp = sqs.receive_message(
            QueueUrl=SQS_QUEUE_URL,
            MaxNumberOfMessages=min(MAX_MESSAGES_PER_POLL, 10),
            WaitTimeSeconds=WAIT_TIME_SECONDS,
            VisibilityTimeout=VISIBILITY_TIMEOUT,
        )
    except ClientError as e:
        print(f"receive_message failed: {e}")
        return 0

    messages = resp.get("Messages", [])
    if not messages:
        return 0

    processed = 0

    for m in messages:
        receipt_handle = m.get("ReceiptHandle")
        body_str = m.get("Body", "")

        if not receipt_handle:
            continue

        try:
            msg = parse_message(body_str)
            s3_key = upload_to_s3(msg)

            sqs.delete_message(QueueUrl=SQS_QUEUE_URL, ReceiptHandle=receipt_handle)
            processed += 1
            print(f"processed -> s3://{S3_BUCKET}/{s3_key}")
        except Exception as e:
            print(f"failed processing message: {e}")

    return processed


def main() -> None:
    print(
        f"consumer-service started region={AWS_REGION} "
        f"poll_interval={POLL_INTERVAL_SECONDS}s max_per_poll={MAX_MESSAGES_PER_POLL}"
    )

    while True:
        count = poll_once()
        if count == 0:
            time.sleep(POLL_INTERVAL_SECONDS)


if __name__ == "__main__":
    main()