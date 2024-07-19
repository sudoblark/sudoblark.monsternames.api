# Standard libraries
import json
import os
# Our libraries
from utilities import ConfigParser
from utilities import Monstername
from utilities import LOGGER


# Required as entrypoint for lambda container
def handler(event, context):
    config_path = os.environ.get("CONFIG_FILE")
    LOGGER.info("config_path set to %s" % config_path)
    endpoint = event["path"]

    config_parser = ConfigParser(config_path)

    status_code = "404"
    response = {
        "error": "Endpoint does not exist"
    }

    if endpoint in config_parser.config.sections():
        first_name_table = config_parser.config[endpoint]["first_name_table"]
        last_name_table = config_parser.config[endpoint]["last_name_table"]

        monstername_api = Monstername(first_name_table, last_name_table)

        dispatcher = {
            "post": monstername_api.post,
            "get": monstername_api.get
        }

        http_method = event.get("httpMethod").lower()
        payload_dictionary = json.loads(event.get("Body", "{}"))

        if http_method not in dispatcher.keys():
            status_code = "404"
            response = {
                "error": f"'{http_method}' method not supported for endpoint '{endpoint}'"
            }
        else:

            status_code, response = dispatcher[http_method](payload_dictionary)

    return {
        "statusCode": status_code,
        "body": json.dumps(response)
    }
