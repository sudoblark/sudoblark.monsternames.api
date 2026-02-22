"""
Configuration management for MonsterNames API.

This module handles loading and parsing the INI configuration file that maps
API endpoints to their corresponding DynamoDB table names.
"""

import configparser
import logging
from typing import Optional

logger = logging.getLogger(__name__)


class ConfigParser:
    """
    Configuration parser for endpoint-to-table mappings.

    Loads and parses an INI configuration file that maps API endpoints to
    their corresponding DynamoDB tables for first names and last names.

    Attributes:
        config_path: Path to the INI configuration file
        config: ConfigParser instance containing parsed configuration

    Example:
        >>> parser = ConfigParser("/path/to/config.ini")
        >>> first_table = parser.get_first_name_table("/skeleton")
        >>> print(first_table)
        'monsternames.skeleton.first_name'
    """

    def __init__(self, config_path: str):
        """
        Initialize configuration parser.

        Args:
            config_path: Path to the INI configuration file

        Raises:
            IOError: If configuration file cannot be read
            ValueError: If config_path is empty
        """
        if not config_path:
            raise ValueError("config_path must not be empty")

        self.config_path: str = config_path
        self.config: configparser.ConfigParser = configparser.ConfigParser()

        try:
            files_read = self.config.read(self.config_path)
            if not files_read:
                raise IOError(f"No configuration file found at: {self.config_path}")
            logger.info(f"Successfully loaded configuration from {self.config_path}")
        except IOError as e:
            logger.error(f"Failed to read configuration file: {str(e)}")
            raise

    def endpoint_exists(self, endpoint: str) -> bool:
        """
        Check if an endpoint exists in the configuration.

        Args:
            endpoint: API endpoint path (e.g., "/skeleton")

        Returns:
            True if endpoint is configured, False otherwise
        """
        return endpoint in self.config.sections()

    def get_first_name_table(self, endpoint: str) -> str:
        """
        Get first name table for an endpoint.

        Args:
            endpoint: API endpoint path (e.g., "/skeleton")

        Returns:
            DynamoDB table name for first names, or "none" if not configured

        Raises:
            ValueError: If endpoint does not exist in configuration
        """
        if not self.endpoint_exists(endpoint):
            raise ValueError(f"Endpoint '{endpoint}' not found in configuration")

        return self.config[endpoint].get("first_name_table", "none")

    def get_last_name_table(self, endpoint: str) -> str:
        """
        Get last name table for an endpoint.

        Args:
            endpoint: API endpoint path (e.g., "/skeleton")

        Returns:
            DynamoDB table name for last names, or "none" if not configured

        Raises:
            ValueError: If endpoint does not exist in configuration
        """
        if not self.endpoint_exists(endpoint):
            raise ValueError(f"Endpoint '{endpoint}' not found in configuration")

        return self.config[endpoint].get("last_name_table", "none")
