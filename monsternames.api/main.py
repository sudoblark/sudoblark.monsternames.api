import os
from utilities import ConfigParser


# Required as entrypoint for lambda container
def handler(event, context):
    config_path = os.environ.get("config_file")
    endpoint = event["path"]

    config_parser = ConfigParser(config_path)

    if endpoint in config_parser.config.sections():
        return "Hello World!"
    else:
        return "Goodbye World!"
