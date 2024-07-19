# Standard libraries
from dataclasses import dataclass
import configparser
import logging
import os
from typing import Union

# Third-party libraries
import boto3
from botocore.exceptions import ClientError

# Uses the default lambda logger
LOGGER = logging.getLogger()
FORMAT = "%(asctime)s - %(module)s - %(levelname)s - %(message)s"
logging.basicConfig(format=FORMAT, level=logging.DEBUG)

LOGGER.debug("Attempting to find LOG_LEVEL environment variable to set logging level.")
if "LOG_LEVEL" in os.environ.keys():
    logging_level = os.environ.get("LOG_LEVEL").upper()
    LOGGER.debug(
        "Found LOG_LEVEL %s in environment variables, attempting to set log level."
        % logging_level
    )
    try:
        logging.basicConfig(level=logging.getLevelName(logging_level), format=FORMAT)
        LOGGER.setLevel(logging.getLevelName(logging_level))
    except ValueError:
        LOGGER.error(
            "Unknown logging level %s provided, defaulting to INFO." % logging_level
        )
        LOGGER.setLevel(logging.getLevelName("INFO"))
else:
    LOGGER.setLevel(logging.getLevelName("INFO"))


@dataclass
class ConfigParser:
    config_path: str
    config = configparser.ConfigParser()

    def __post_init__(self):
        """
        Magic method to perform logic after we initialise our dataclass
        :return:
        """
        try:
            self.config.read(self.config_path)
        except IOError as e:
            LOGGER.warning("Unable to read config_file at path %s" % self.config_path)
            LOGGER.error(str(e))
            raise


@dataclass
class Monstername:
    first_name_table: str
    last_name_table: str
    table_attributes = [
        {
            "AttributeName": "value",
            "AttributeType": "S"
        }
    ]
    table_schema = [
        {
            "AttributeName": "value",
            "KeyType": "HASH"
        }
    ]
    billing_mode = "PAY_PER_REQUEST"

    def __post_init__(self):
        dynamodb_endpoint = os.environ.get("DYNAMODB_ENDPOINT") if "DYNAMODB_ENDPOINT" in os.environ.keys() else None
        self.dynamo_db_client = boto3.resource('dynamodb', endpoint_url=dynamodb_endpoint)
        LOGGER.debug("First name table: %s" % self.first_name_table)
        LOGGER.debug("Last name table: %s" % self.last_name_table)

    def post(self, payload: dict) -> [int, dict]:
        """
        Method to create new content in respective first_name/last_name tables

        :param payload: The payload passed through to our lambda
        :return: Response code and message denoting status of our post request
        """
        response_dict = {}
        LOGGER.debug("Payload as follows: %s" % payload)
        if ("first_name" in payload.keys()) & (self.first_name_table != "none"):
            table = self._get_or_create_table(self.first_name_table)
            if table is not None:
                response_dict["first_name"] = payload.get("first_name")
        if ("last_name" in payload.keys()) & (self.last_name_table != "none"):
            table = self._get_or_create_table(self.last_name_table)
            if table is not None:
                response_dict["last_name"] = payload.get("last_name")

        if len(response_dict.keys()) > 0:
            return 200, response_dict
        else:
            return 400, {"error": "Unable to create table"}

    def _get_or_create_table(self, table_name: str) -> Union[any, None]:
        """
        Method to either retrieve given table name, or if it does not exist create it.

        :param table_name: Name of table to get or create
        :return: Reference to the table object, or None if errors were encountered
        """
        existing_tables = list(self.dynamo_db_client.tables.all())
        table_exists = False
        for table in existing_tables:
            if table.name == table_name:
                table_exists = True
                break
        if table_exists:
            table = self.dynamo_db_client.Table(table_name)
        else:
            table = self._create_table(table_name)
        return table

    def _create_table(self, table_name: str) -> Union[any, None]:
        """
        Helper method to create a table in DynamoDB if it does not exist

        :param table_name: The name of the table to create
        :return: The newly created table, or None if we encountered errors
        """
        table = None
        try:
            new_table = self.dynamo_db_client.create_table(
                TableName=table_name,
                KeySchema=self.table_schema,
                AttributeDefinitions=self.table_attributes,
                BillingMode=self.billing_mode
            )
            new_table.wait_until_exists()
            table = new_table
        except ClientError as err:
            LOGGER.error("Unable to create new table: %s", table_name)
            LOGGER.error("%s: %s", err.response["Error"]["Code"], err.response["Error"]["Message"])
        return table
