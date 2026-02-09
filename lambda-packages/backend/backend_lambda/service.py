"""
Business logic for MonsterNames API.

This module provides the core service layer for monster name operations,
including retrieving random names and creating new name entries in DynamoDB.
"""

import logging
import os
import random
from typing import Any, Dict, List, Optional, Tuple

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


class MonsternameService:
    """
    Service class for monster name operations.

    Handles GET and POST operations for monster names, interacting with
    DynamoDB tables to retrieve random names and insert new names.

    Attributes:
        first_name_table: DynamoDB table name for first names
        last_name_table: DynamoDB table name for last names
        dynamo_db_client: Boto3 DynamoDB resource client

    Example:
        >>> service = MonsternameService(
        ...     first_name_table="monsternames.skeleton.first_name",
        ...     last_name_table="monsternames.skeleton.last_name"
        ... )
        >>> status, response = service.get_random_name()
        >>> print(response)
        {'first_name': 'Reginald', 'last_name': 'Worthington', 'full_name': 'Reginald Worthington'}
    """

    # DynamoDB table schema configuration
    TABLE_ATTRIBUTES: List[Dict[str, str]] = [
        {"AttributeName": "value", "AttributeType": "S"}
    ]
    TABLE_SCHEMA: List[Dict[str, str]] = [
        {"AttributeName": "value", "KeyType": "HASH"}
    ]
    BILLING_MODE: str = "PAY_PER_REQUEST"

    def __init__(self, first_name_table: str, last_name_table: str):
        """
        Initialize MonsternameService.

        Args:
            first_name_table: DynamoDB table name for first names
            last_name_table: DynamoDB table name for last names

        Raises:
            ValueError: If table names are empty
        """
        if not first_name_table or not last_name_table:
            raise ValueError("first_name_table and last_name_table must not be empty")

        self.first_name_table: str = first_name_table
        self.last_name_table: str = last_name_table

        # Initialize DynamoDB client (supports local endpoint for testing)
        dynamodb_endpoint: Optional[str] = os.environ.get("DYNAMODB_ENDPOINT")
        self.dynamo_db_client = boto3.resource("dynamodb", endpoint_url=dynamodb_endpoint)

        logger.debug(f"Initialized service with tables: {first_name_table}, {last_name_table}")

    def get_random_name(self) -> Tuple[int, Dict[str, Any]]:
        """
        Retrieve random name components from DynamoDB tables.

        Scans the configured DynamoDB tables and returns randomly selected
        first name and/or last name values. Constructs a full name if both
        components are available.

        Returns:
            Tuple of (status_code, response_body):
            - status_code: HTTP status code (200 for success, 500 for error)
            - response_body: Dictionary with name components and/or error message

        Example:
            >>> status, response = service.get_random_name()
            >>> print(status)
            200
            >>> print(response)
            {'first_name': 'Bjorn', 'last_name': 'Ironforge', 'full_name': 'Bjorn Ironforge'}
        """
        response: Dict[str, str] = {}
        full_name_parts: List[str] = []

        # Process both first and last name tables
        tables_config: List[Dict[str, str]] = [
            {"field": "first_name", "table": self.first_name_table},
            {"field": "last_name", "table": self.last_name_table}
        ]

        for config in tables_config:
            if config["table"] == "none":
                logger.debug(f"Skipping {config['field']} - table not configured")
                continue

            if not self._table_exists(config["table"]):
                logger.warning(f"Table does not exist: {config['table']}")
                continue

            try:
                table = self.dynamo_db_client.Table(config["table"])
                scan_result = table.scan()
                items: List[Dict[str, Any]] = scan_result.get("Items", [])

                if items:
                    random_item: str = random.choice(items)["value"]
                    response[config["field"]] = random_item
                    full_name_parts.append(random_item)
                    logger.debug(f"Retrieved {config['field']}: {random_item}")
                else:
                    logger.warning(f"No items found in table: {config['table']}")

            except ClientError as e:
                logger.error(
                    f"Failed to scan table {config['table']}: {e.response['Error']['Code']}",
                    exc_info=True
                )

        # Build response
        if full_name_parts:
            response["full_name"] = " ".join(full_name_parts)
            return 200, response
        else:
            return 500, {"error": "Unable to find name entries in database"}

    def create_name(self, payload: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
        """
        Create new name entries in DynamoDB tables.

        Inserts first name and/or last name values into their respective
        DynamoDB tables. Creates tables if they don't exist.

        Args:
            payload: Dictionary containing name components:
                - first_name (str, optional): First name to insert
                - last_name (str, optional): Last name to insert

        Returns:
            Tuple of (status_code, response_body):
            - status_code: HTTP status code (200 for success, 400 for failure)
            - response_body: Dictionary with success/error messages

        Example:
            >>> payload = {"first_name": "Grug", "last_name": ""}
            >>> status, response = service.create_name(payload)
            >>> print(status)
            200
            >>> print(response)
            {'message': "Successfully inserted 'Grug' as valid 'first_name'."}
        """
        response: Dict[str, str] = {}
        messages: List[str] = []
        has_error: bool = False

        logger.debug(f"Processing create request with payload: {payload}")

        # Process both first and last name tables
        tables_config: List[Dict[str, str]] = [
            {"field": "first_name", "table": self.first_name_table},
            {"field": "last_name", "table": self.last_name_table}
        ]

        for config in tables_config:
            field: str = config["field"]
            table_name: str = config["table"]

            # Skip if field not in payload or table not configured
            if field not in payload or table_name == "none":
                continue

            value: str = payload[field]
            if not value:
                logger.debug(f"Skipping empty {field} value")
                continue

            # Get or create table
            table, error = self._get_or_create_table(table_name)

            if table is None:
                has_error = True
                error_msg = f"Unable to access table for '{field}': {error}"
                messages.append(error_msg)
                logger.error(error_msg)
                break

            # Insert item
            try:
                put_response = table.put_item(Item={"value": value})
                status_code: int = put_response["ResponseMetadata"]["HTTPStatusCode"]

                if status_code == 200:
                    success_msg = f"Successfully inserted '{value}' as valid '{field}'."
                    messages.append(success_msg)
                    logger.info(success_msg)
                else:
                    has_error = True
                    error_msg = f"Failed to insert '{value}' as valid '{field}'."
                    messages.append(error_msg)
                    logger.error(f"{error_msg} Status code: {status_code}")
                    break

            except ClientError as e:
                has_error = True
                error_msg = f"Unable to insert '{value}' as valid '{field}': {e.response['Error']['Code']}"
                messages.append(error_msg)
                logger.error(error_msg, exc_info=True)
                break

        # Build response
        if has_error:
            response["error"] = " ".join(messages)
            return 400, response
        else:
            response["message"] = " ".join(messages)
            return 200, response

    def _table_exists(self, table_name: str) -> bool:
        """
        Check if a DynamoDB table exists.

        Args:
            table_name: Name of the DynamoDB table

        Returns:
            True if table exists, False otherwise
        """
        try:
            existing_tables = list(self.dynamo_db_client.tables.all())
            return any(table.name == table_name for table in existing_tables)
        except ClientError as e:
            logger.error(f"Failed to list tables: {e.response['Error']['Code']}", exc_info=True)
            return False

    def _get_or_create_table(self, table_name: str) -> Tuple[Optional[Any], str]:
        """
        Get existing table or create if it doesn't exist.

        Args:
            table_name: Name of the DynamoDB table

        Returns:
            Tuple of (table, error):
            - table: DynamoDB table resource or None if error
            - error: Error message or empty string if successful
        """
        if self._table_exists(table_name):
            return self.dynamo_db_client.Table(table_name), ""
        else:
            return self._create_table(table_name)

    def _create_table(self, table_name: str) -> Tuple[Optional[Any], str]:
        """
        Create a new DynamoDB table.

        Args:
            table_name: Name of the DynamoDB table to create

        Returns:
            Tuple of (table, error):
            - table: DynamoDB table resource or None if error
            - error: Error message or empty string if successful
        """
        try:
            new_table = self.dynamo_db_client.create_table(
                TableName=table_name,
                KeySchema=self.TABLE_SCHEMA,
                AttributeDefinitions=self.TABLE_ATTRIBUTES,
                BillingMode=self.BILLING_MODE
            )
            new_table.wait_until_exists()
            logger.info(f"Successfully created table: {table_name}")
            return new_table, ""

        except ClientError as e:
            error_code: str = e.response["Error"]["Code"]
            error_message: str = e.response["Error"]["Message"]
            logger.error(f"Failed to create table {table_name}: {error_code} - {error_message}")
            return None, error_code
