import os
import json
import logging
from typing import Any, Dict, Optional

import boto3
from botocore.exceptions import ClientError
from fastapi import FastAPI, Header, HTTPException, Request
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime


logger = logging.getLogger("producer-service")
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL", "")
SSM_TOKEN_PARAM_NAME = os.getenv("SSM_TOKEN_PARAM_NAME", "/devops-assignment/token")

if not SQS_QUEUE_URL:
    logger.error("SQS_QUEUE_URL is empty. The service will fail to publish until it is set.")

ssm = boto3.client("ssm", region_name=AWS_REGION)
sqs = boto3.client("sqs", region_name=AWS_REGION)

app = FastAPI(title="producer-service", version="1.0.0")


class IncomingPayload(BaseModel):
    model_config = ConfigDict(extra="allow")

    email_timestream: str = Field(..., description="Timestamp string (ISO8601 recommended)")


def get_expected_token() -> str:
    try:
        resp = ssm.get_parameter(Name=SSM_TOKEN_PARAM_NAME, WithDecryption=True)
        token = resp["Parameter"]["Value"]
        if not token:
            logger.exception("SSM token parameter is empty")
            raise RuntimeError("SSM token parameter is empty")
        return token
    except ClientError as e:
        logger.exception("Failed to read token from SSM")
        raise HTTPException(status_code=500, detail=f"SSM error: {e.response.get('Error', {}).get('Code', 'Unknown')}")
    except Exception:
        logger.exception("Unexpected error while reading token from SSM")
        raise HTTPException(status_code=500, detail="Failed to read token from SSM")


def validate_timestamp(email_timestream: str) -> str:
    try:
        dt_object = datetime.fromtimestamp(int(email_timestream) / 1000.0)
        return str(dt_object)
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Invalid email_timestream. Provide the timestamp as int",
        )


def publish_to_sqs(message: Dict[str, Any]) -> str:
    try:
        resp = sqs.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps(message),
        )
        return resp["MessageId"]
    except ClientError as e:
        logger.exception("Failed to publish message to SQS")
        raise HTTPException(status_code=502, detail=f"SQS error: {e.response.get('Error', {}).get('Code', 'Unknown')}")
    except Exception:
        logger.exception("Unexpected error while publishing to SQS")
        raise HTTPException(status_code=502, detail="Failed to publish to SQS")


@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/produce")
async def produce(
    payload: IncomingPayload,
    request: Request,
    x_api_token: str = Header(default=None, alias="X-API-Token"),
):
    expected = get_expected_token()
    if not x_api_token or x_api_token != expected:
        raise HTTPException(status_code=401, detail="Invalid token")

    normalized_ts = validate_timestamp(payload.email_timestream)

    body = payload.model_dump(mode="json")
    body["email_timestream"] = normalized_ts

    message = {
        "source": "producer-service",
        "path": str(request.url.path),
        "client": request.client.host if request.client else None,
        "payload": body,
    }

    message_id = publish_to_sqs(message)
    return {"status": "queued", "message_id": message_id}