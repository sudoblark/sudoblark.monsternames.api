"""
Main sync lambda for Monsternames API

Requires the following environment variables:
- CONFIG_FILE: Location to config file to use for interaction with DynamoDB tables.

The following environment variables are optional:
- DYNAMO_DB_CONNECTION_STRING: URL to connect to DynamoDB, only required when running PyTest locally
- LOG_LEVEL: sets logging level for the entire application
"""

# Standard libraries
import json
import os
from typing import Dict
from typing import Union

# Third-party libraries
from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.data_classes import (
    event_source,
    APIGatewayProxyEvent,
)

# Our libraries
from backend_lambda.utilities import ConfigParser
from backend_lambda.utilities import Monstername
from backend_lambda.utilities import LOGGER

BASE_LAMBDA_RESPONSE = {
    "statusCode": 200,
    "body": {"pipeline": {}, "build": {}},
    "headers": {"content-Type": "application/json"},
}


@event_source(data_class=APIGatewayProxyEvent)
def handler(event: APIGatewayProxyEvent, context: LambdaContext) -> Dict:
    """
    The entrypoint for the lambda at large, simply takes the event and context
    and feeds to appropriate classes in order to populate/retrieve into/from DynamoDB.

    :param event: Event passed through to the lambda from the API Gateway.
    :param context: Context passed through to the lambda from the API Gateway.
    :return: JSON string signifying a HTTP Status Code and body.
    """
    config_path: str = os.environ.get("CONFIG_FILE")
    LOGGER.info("config_path set to %s" % config_path)

    if isinstance(event, str):
        event: dict = json.loads(event)

    endpoint: str = event["path"]
    LOGGER.debug("Raw event: %s" % event)
    payload_event: Union[str, None] = event.get("body", None)
    payload_dictionary: dict = json.loads(payload_event) if payload_event is not None else {}
    LOGGER.debug("Payload dictionary: %s" % payload_dictionary)

    config_parser: ConfigParser = ConfigParser(config_path)

    status_code: str = "404"
    response: dict = {"error": "Endpoint does not exist"}

    if endpoint in config_parser.config.sections():
        first_name_table: str = config_parser.config[endpoint]["first_name_table"]
        last_name_table: str = config_parser.config[endpoint]["last_name_table"]

        monstername_api: Monstername = Monstername(first_name_table, last_name_table)

        dispatcher: dict = {"post": monstername_api.post, "get": monstername_api.get}

        http_method: str = event.get("httpMethod").lower()

        if http_method not in dispatcher.keys():
            status_code: str = "404"
            response: dict = {
                "error": f"'{http_method}' method not supported for endpoint '{endpoint}'"
            }
        else:
            status_code, response = dispatcher[http_method](payload_dictionary)

    LOGGER.debug("Return status code: %s" % status_code)
    LOGGER.debug("Return body: %s" % json.dumps(response))

    return {"statusCode": status_code, "body": json.dumps(response)}
