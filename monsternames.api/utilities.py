# Standard libraries
from dataclasses import dataclass
import configparser
import logging

LOGGER = logging.getLogger(__name__)
logging.basicConfig(format="%(asctime)s %(filename)s: %(levelname)s: %(message)s")


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