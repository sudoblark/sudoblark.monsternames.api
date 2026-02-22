"""
Main Lambda handler for MonsterNames API.

This module provides the entry point for the Lambda function that serves as the
backend for the MonsterNames REST API. It handles API Gateway events and performs
GET/POST operations against DynamoDB tables for monster name data.

Environment Variables:
    CONFIG_FILE (str): Path to configuration file for DynamoDB table mapping
    LOG_LEVEL (str): Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    DYNAMODB_ENDPOINT (str, optional): Custom DynamoDB endpoint for local testing
"""

import json
import logging
import os
from typing import Any, Dict

from aws_lambda_powertools.utilities.data_classes import (
    APIGatewayProxyEvent,
    event_source,
)
from aws_lambda_powertools.utilities.typing import LambdaContext

from backend_lambda.config import ConfigParser
from backend_lambda.service import MonsternameService

# Configure logging
LOG_LEVEL: str = os.environ.get("LOG_LEVEL", "INFO").upper()
logger = logging.getLogger()
logger.setLevel(LOG_LEVEL)


@event_source(data_class=APIGatewayProxyEvent)
def handler(event: APIGatewayProxyEvent, context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler for MonsterNames API requests.

    Processes API Gateway events, routes requests to appropriate service methods,
    and returns properly formatted HTTP responses.

    Args:
        event: API Gateway proxy event containing request data
        context: Lambda context object with runtime information

    Returns:
        Dictionary containing HTTP status code and JSON response body

    Raises:
        ValueError: If CONFIG_FILE environment variable is not set
        Exception: For unexpected errors during request processing
    """
    try:
        # Load configuration
        config_path: str = os.environ.get("CONFIG_FILE", "")
        if not config_path:
            raise ValueError("CONFIG_FILE environment variable is required")

        logger.info(f"Using configuration file: {config_path}")

        # Parse request
        endpoint: str = event.path
        http_method: str = event.http_method.lower()
        
        logger.info(f"Processing {http_method.upper()} request for {endpoint}")
        logger.debug(f"Raw event: {event.raw_event}")

        # Parse request body
        payload: Dict[str, Any] = {}
        if event.body:
            try:
                payload = json.loads(event.body) if isinstance(event.body, str) else event.body
            except json.JSONDecodeError as e:
                logger.error(f"Invalid JSON in request body: {str(e)}")
                return {
                    "statusCode": 400,
                    "body": json.dumps({"error": "Invalid JSON in request body"})
                }

        logger.debug(f"Parsed payload: {payload}")

        # Load configuration and check endpoint exists
        config_parser: ConfigParser = ConfigParser(config_path)
        
        if not config_parser.endpoint_exists(endpoint):
            logger.warning(f"Endpoint not found: {endpoint}")
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "Endpoint does not exist"})
            }

        # Get table configuration for endpoint
        first_name_table: str = config_parser.get_first_name_table(endpoint)
        last_name_table: str = config_parser.get_last_name_table(endpoint)

        logger.debug(f"Tables - first_name: {first_name_table}, last_name: {last_name_table}")

        # Initialize service
        service: MonsternameService = MonsternameService(
            first_name_table=first_name_table,
            last_name_table=last_name_table
        )

        # Route to appropriate method
        if http_method == "get":
            status_code, response_body = service.get_random_name()
        elif http_method == "post":
            status_code, response_body = service.create_name(payload)
        else:
            logger.warning(f"Unsupported HTTP method: {http_method}")
            return {
                "statusCode": 405,
                "body": json.dumps({
                    "error": f"'{http_method.upper()}' method not supported for endpoint '{endpoint}'"
                })
            }

        logger.info(f"Request completed with status {status_code}")
        logger.debug(f"Response body: {response_body}")

        return {
            "statusCode": status_code,
            "body": json.dumps(response_body)
        }

    except ValueError as e:
        logger.error(f"Configuration error: {str(e)}", exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Configuration error"})
        }

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal server error"})
        }
