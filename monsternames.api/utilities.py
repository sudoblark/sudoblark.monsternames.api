# Standard libraries
from dataclasses import dataclass
import configparser
import logging

# Third-party libraries
import boto3
from botocore.exceptions import ClientError

LOGGER = logging.getLogger(__name__)
logging.basicConfig(format="%(asctime)s %(filename)s: %(levelname)s: %(message)s", level="INFO")


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
    first_name_table: str = None
    last_name_table: str = None
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
        self.dynamo_db_client = boto3.client('dynamodb')

    def post(self, payload: dict) -> [int, dict]:
        """
        Method to create new content in respective first_name/last_name tables

        :param payload: The payload passed through to our lambda
        :return: Response code and message denoting status of our post request
        """
        response_dict = {}
        if "first_name" in payload.keys():
            self._create_table(self.first_name_table)
            response_dict["first_name"] = payload
        if "last_name" in payload.keys():
            self._create_table(self.last_name_table)
            response_dict["last_name"] = payload

        if len(response_dict) > 0:
            return 200, response_dict
        else:
            return 400, {"error": "Unable to create table"}

    def _create_table(self, table_name: str) -> None:
        """
        Helper method to create a table in DynamoDB if it does not exist

        :param table_name: The name of the table to create
        :return: The newly created table
        """
        try:
            new_table = self.dynamo_db_client.create_table(
                TableName=table_name,
                KeySchema=self.table_schema,
                AttributeDefinitions=self.table_attributes,
                BillingMode=self.billing_mode
            )
            new_table.wait_until_exists()

        except self.dynamo_db_client.exceptions.ResourceInUseException:
            LOGGER.debug("'%s' DynamoDB table already exists, skipping creation." % table_name)
            self.dynamo_db_client.describe_table(TableName=table_name)
        except ClientError as err:
            LOGGER.error("Unable to create new table: %s", table_name)
            LOGGER.error("%s: %s", err.response["Error"]["Code"], err.response["Error"]["Message"])
