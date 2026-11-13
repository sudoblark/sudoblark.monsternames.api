"""
Main Lambda handler for MonsterNames API.

This module provides the entry point for the Lambda function that serves as the
backend for the MonsterNames REST API. It handles API Gateway events and reads
monster names from DynamoDB tables. The API is read-only: only GET is served.

Environment Variables:
    MONSTER_TABLES (str): JSON map of each monster to its first_name and
        last_name table names, generated from modules/data/monsters.tf
    LOG_LEVEL (str): Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    DYNAMODB_ENDPOINT (str, optional): Custom DynamoDB endpoint for local testing
"""

import json
import logging
import os
from typing import Any, TypedDict

import boto3
from aws_lambda_powertools.utilities.data_classes import (
    APIGatewayProxyEvent,
    event_source,
)
from aws_lambda_powertools.utilities.typing import LambdaContext

from common.domain.monster_name import MonsterName
from common.repositories.monster_name_repository import (
    MonsterNameRepository,
    MonsterNameTables,
)

# Configure logging
LOG_LEVEL: str = os.environ.get("LOG_LEVEL", "INFO").upper()
logger = logging.getLogger()
logger.setLevel(LOG_LEVEL)


class MonsterTables(TypedDict):
    """A monster's table names, as MONSTER_TABLES gives them."""

    first_name: str
    last_name: str | None


def load_monster_tables() -> dict[str, MonsterTables]:
    """
    Load each monster's table names from the MONSTER_TABLES environment variable.

    Returns:
        Map of monster name to its "first_name" and "last_name" table names,
        where "last_name" is None for monsters with first names only

    Raises:
        ValueError: If MONSTER_TABLES is not set or is not valid JSON
    """
    raw: str = os.environ.get("MONSTER_TABLES", "")
    if not raw:
        raise ValueError("MONSTER_TABLES environment variable is required")

    try:
        return json.loads(raw)
    except json.JSONDecodeError as e:
        raise ValueError(f"MONSTER_TABLES is not valid JSON: {e}") from e


def to_response(name: MonsterName) -> dict[str, Any]:
    """The response body: each part the name has, and its full name."""
    response: dict[str, Any] = {}
    if name.first_name:
        response["first_name"] = name.first_name
    if name.last_name:
        response["last_name"] = name.last_name
    response["full_name"] = name.full_name
    return response


@event_source(data_class=APIGatewayProxyEvent)
def handler(event: APIGatewayProxyEvent, context: LambdaContext) -> dict[str, Any]:
    """
    Lambda handler for MonsterNames API requests.

    Maps the request path to a monster, reads a random name from that monster's
    tables and returns a properly formatted HTTP response.

    Args:
        event: API Gateway proxy event containing request data
        context: Lambda context object with runtime information

    Returns:
        Dictionary containing HTTP status code and JSON response body

    Raises:
        ValueError: If MONSTER_TABLES is missing or invalid
        Exception: For unexpected errors during request processing
    """
    try:
        monster_tables = load_monster_tables()

        # DYNAMODB_ENDPOINT points boto3 at a local DynamoDB for testing
        dynamodb = boto3.resource("dynamodb", endpoint_url=os.environ.get("DYNAMODB_ENDPOINT"))
        repository = MonsterNameRepository(
            {
                monster: MonsterNameTables(
                    first_names=dynamodb.Table(tables["first_name"]),
                    last_names=dynamodb.Table(tables["last_name"]) if tables["last_name"] else None,
                )
                for monster, tables in monster_tables.items()
            }
        )

        # Parse request
        endpoint: str = event.path
        http_method: str = event.http_method.lower()

        logger.info(f"Processing {http_method.upper()} request for {endpoint}")

        # Each monster is served at /<name>
        monster = endpoint.strip("/")
        if monster not in repository.monsters:
            logger.warning(f"Endpoint not found: {endpoint}")
            return {"statusCode": 404, "body": json.dumps({"error": "Endpoint does not exist"})}

        # The API is read-only, so GET is the only method served
        if http_method != "get":
            logger.warning(f"Unsupported HTTP method: {http_method}")
            error = f"'{http_method.upper()}' method not supported for endpoint '{endpoint}'"
            return {"statusCode": 405, "body": json.dumps({"error": error})}

        name = repository.get_random_name(monster)

        if name is None:
            status_code = 500
            response_body: dict[str, Any] = {"error": "Unable to find name entries in database"}
        else:
            status_code = 200
            response_body = to_response(name)

        logger.info(f"Request completed with status {status_code}")
        logger.debug(f"Response body: {response_body}")

        return {"statusCode": status_code, "body": json.dumps(response_body)}

    except ValueError as e:
        logger.error(f"Configuration error: {str(e)}", exc_info=True)
        return {"statusCode": 500, "body": json.dumps({"error": "Configuration error"})}

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return {"statusCode": 500, "body": json.dumps({"error": "Internal server error"})}
