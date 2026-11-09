"""Shared pytest fixtures for the backend Lambda tests."""

import json
import os
from collections.abc import Callable, Iterable, Iterator
from typing import Any
from unittest.mock import MagicMock

import boto3
import pytest
from moto import mock_aws

CONFIG_FILE = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../lambda-packages/backend/config.ini")
)


@pytest.fixture(autouse=True)
def aws_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    """Point boto3 at fake credentials and the Lambda at its packaged config."""
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_SECURITY_TOKEN", "testing")
    monkeypatch.setenv("AWS_SESSION_TOKEN", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "eu-west-2")
    monkeypatch.setenv("CONFIG_FILE", CONFIG_FILE)
    monkeypatch.delenv("DYNAMODB_ENDPOINT", raising=False)


@pytest.fixture
def dynamodb() -> Iterator[Any]:
    """Mocked DynamoDB resource with no tables."""
    with mock_aws():
        yield boto3.resource("dynamodb", region_name="eu-west-2")


@pytest.fixture
def seed_table(dynamodb: Any) -> Callable[[str, Iterable[str]], None]:
    """Create a name table with the Lambda's schema and fill it with names."""

    def seed(table_name: str, names: Iterable[str]) -> None:
        table = dynamodb.create_table(
            TableName=table_name,
            KeySchema=[{"AttributeName": "value", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "value", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        for name in names:
            table.put_item(Item={"value": name})

    return seed


@pytest.fixture
def api_event() -> Callable[..., dict[str, Any]]:
    """Build an API Gateway proxy event for a path and method."""

    def build(path: str, method: str = "GET", body: Any | None = None) -> dict[str, Any]:
        return {
            "resource": path,
            "path": path,
            "httpMethod": method,
            "headers": {"Content-Type": "application/json"},
            "queryStringParameters": None,
            "pathParameters": None,
            "requestContext": {"path": f"/production{path}", "stage": "production"},
            "body": body if body is None or isinstance(body, str) else json.dumps(body),
            "isBase64Encoded": False,
        }

    return build


@pytest.fixture
def lambda_context() -> MagicMock:
    """Mock Lambda context."""
    context = MagicMock()
    context.function_name = "aws-sudoblark-production-monsternames-api-backend"
    context.aws_request_id = "test-request-id"
    return context
