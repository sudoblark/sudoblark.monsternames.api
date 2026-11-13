"""
Backend Lambda handler for the MonsterNames API.

``MonsterNamesHandler`` sits at the edge of the layers in common/: it maps each
request's path to a monster, reads a random name through the monster name
repository and shapes the response. The API is read-only: only GET is served.
Lambda calls the module-level ``handler``.

Environment Variables:
    MONSTER_TABLES (str): JSON map of each monster to its first_name and
        last_name table names, generated from modules/data/monsters.tf
    LOG_LEVEL (str): Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    DYNAMODB_ENDPOINT (str, optional): Custom DynamoDB endpoint for local testing
"""

import json
import logging
import os
from typing import Any

from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEvent
from aws_lambda_powertools.utilities.typing import LambdaContext

from common.domain.monster_name import MonsterName
from common.mixins.repo_mixins import MonsterNameRepoMixin

# Configure logging
LOG_LEVEL: str = os.environ.get("LOG_LEVEL", "INFO").upper()
logger = logging.getLogger()
logger.setLevel(LOG_LEVEL)


class MonsterNamesHandler(MonsterNameRepoMixin):
    """Serves a random name for the monster a GET request's path names."""

    def handle(self, event: dict[str, Any], context: LambdaContext | None = None) -> dict[str, Any]:
        """Handle one API Gateway proxy event.

        Args:
            event: API Gateway proxy event containing request data
            context: Lambda context object with runtime information

        Returns:
            The name with a 200, or an error with a 404 for an unknown monster,
            a 405 for any method but GET, or a 500
        """
        request = APIGatewayProxyEvent(event)
        try:
            return self._serve(request)

        except ValueError as e:
            logger.error(f"Configuration error: {str(e)}", exc_info=True)
            return self._response(500, {"error": "Configuration error"})

        except Exception as e:
            logger.error(f"Unexpected error: {str(e)}", exc_info=True)
            return self._response(500, {"error": "Internal server error"})

    def _serve(self, request: APIGatewayProxyEvent) -> dict[str, Any]:
        """Route the request to its monster and read the monster's name."""
        endpoint: str = request.path
        http_method: str = request.http_method.lower()

        logger.info(f"Processing {http_method.upper()} request for {endpoint}")

        # Each monster is served at /<name>
        monster = endpoint.strip("/")
        if monster not in self._monster_name_repo.monsters:
            logger.warning(f"Endpoint not found: {endpoint}")
            return self._response(404, {"error": "Endpoint does not exist"})

        # The API is read-only, so GET is the only method served
        if http_method != "get":
            logger.warning(f"Unsupported HTTP method: {http_method}")
            error = f"'{http_method.upper()}' method not supported for endpoint '{endpoint}'"
            return self._response(405, {"error": error})

        name = self._monster_name_repo.get_random_name(monster)
        if name is None:
            return self._response(500, {"error": "Unable to find name entries in database"})
        return self._response(200, self._to_body(name))

    @staticmethod
    def _to_body(name: MonsterName) -> dict[str, Any]:
        """The response body: each part the name has, and its full name."""
        body: dict[str, Any] = {}
        if name.first_name:
            body["first_name"] = name.first_name
        if name.last_name:
            body["last_name"] = name.last_name
        body["full_name"] = name.full_name
        return body

    @staticmethod
    def _response(status_code: int, body: dict[str, Any]) -> dict[str, Any]:
        """An API Gateway proxy response with a JSON body."""
        logger.info(f"Request completed with status {status_code}")
        return {"statusCode": status_code, "body": json.dumps(body)}


handler = MonsterNamesHandler().handle
