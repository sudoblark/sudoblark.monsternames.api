"""
Business logic for MonsterNames API.

This module provides the core service layer for monster name operations:
retrieving random names from the Terraform-managed DynamoDB tables.
"""

import logging
import os
import random
from typing import Any

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


class MonsternameService:
    """
    Service class for monster name operations.

    Reads random names from a monster's DynamoDB tables. The tables and their
    names are managed by Terraform, so the service only ever reads.

    Attributes:
        first_name_table: DynamoDB table name for first names
        last_name_table: DynamoDB table name for last names, or None
        dynamo_db_client: Boto3 DynamoDB resource client

    Example:
        >>> service = MonsternameService(
        ...     first_name_table="aws-sudoblark-production-monsternames-api-skeleton-first-name",
        ...     last_name_table="aws-sudoblark-production-monsternames-api-skeleton-last-name"
        ... )
        >>> status, response = service.get_random_name()
        >>> print(response)
        {'first_name': 'Reginald', 'last_name': 'Montgomery', 'full_name': 'Reginald Montgomery'}
    """

    def __init__(self, first_name_table: str, last_name_table: str | None = None):
        """
        Initialize MonsternameService.

        Args:
            first_name_table: DynamoDB table name for first names
            last_name_table: DynamoDB table name for last names, or None for
                monsters with first names only

        Raises:
            ValueError: If first_name_table is empty
        """
        if not first_name_table:
            raise ValueError("first_name_table must not be empty")

        self.first_name_table: str = first_name_table
        self.last_name_table: str | None = last_name_table

        # Initialize DynamoDB client (supports local endpoint for testing)
        dynamodb_endpoint: str | None = os.environ.get("DYNAMODB_ENDPOINT")
        self.dynamo_db_client = boto3.resource("dynamodb", endpoint_url=dynamodb_endpoint)

        logger.debug(f"Initialized service with tables: {first_name_table}, {last_name_table}")

    def get_random_name(self) -> tuple[int, dict[str, Any]]:
        """
        Retrieve random name components from DynamoDB tables.

        Scans the configured DynamoDB tables and returns randomly selected
        first name and/or last name values. Constructs a full name if both
        components are available. A missing or unreadable table is logged
        and skipped.

        Returns:
            Tuple of (status_code, response_body):
            - status_code: HTTP status code (200 for success, 500 for error)
            - response_body: Dictionary with name components and/or error message

        Example:
            >>> status, response = service.get_random_name()
            >>> print(status)
            200
            >>> print(response)
            {'first_name': 'Sven', 'last_name': 'Gongleson', 'full_name': 'Sven Gongleson'}
        """
        response: dict[str, str] = {}
        full_name_parts: list[str] = []

        # Process both first and last name tables
        tables_config: list[dict[str, str | None]] = [
            {"field": "first_name", "table": self.first_name_table},
            {"field": "last_name", "table": self.last_name_table},
        ]

        for config in tables_config:
            if config["table"] is None:
                logger.debug(f"Skipping {config['field']} - table not configured")
                continue

            try:
                table = self.dynamo_db_client.Table(config["table"])
                scan_result = table.scan()
                items: list[dict[str, Any]] = scan_result.get("Items", [])

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
                    exc_info=True,
                )

        # Build response
        if full_name_parts:
            response["full_name"] = " ".join(full_name_parts)
            return 200, response
        else:
            return 500, {"error": "Unable to find name entries in database"}
