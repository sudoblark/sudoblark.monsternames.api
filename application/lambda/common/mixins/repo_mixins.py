"""Repository mixins: lazy repository accessors for handlers.

Each mixin builds its repository from the environment on first use, and gives
tests a property setter to pass a double instead.
"""

import json
import os

import boto3

from common.repositories.monster_name_repository import (
    MonsterNameRepository,
    MonsterNameTables,
)


class MonsterNameRepoMixin:
    """Provides a lazy ``_monster_name_repo`` over ``MONSTER_TABLES``.

    ``MONSTER_TABLES`` is a JSON map of each monster to its ``first_name`` and
    ``last_name`` table names, with ``last_name`` null for monsters with first
    names only, which Terraform generates from modules/data/monsters.tf.
    ``DYNAMODB_ENDPOINT``, when set, points boto3 at a local DynamoDB.
    """

    _monster_name_repo_instance: MonsterNameRepository | None = None

    @property
    def _monster_name_repo(self) -> MonsterNameRepository:
        """The repository, built from the environment on first use.

        Raises:
            ValueError: If MONSTER_TABLES is not set or is not valid JSON.
        """
        if self._monster_name_repo_instance is None:
            self._monster_name_repo_instance = self._build_monster_name_repo()
        return self._monster_name_repo_instance

    @_monster_name_repo.setter
    def _monster_name_repo(self, repo: MonsterNameRepository) -> None:
        self._monster_name_repo_instance = repo

    @staticmethod
    def _build_monster_name_repo() -> MonsterNameRepository:
        """A repository over the tables MONSTER_TABLES names."""
        raw = os.environ.get("MONSTER_TABLES", "")
        if not raw:
            raise ValueError("MONSTER_TABLES environment variable is required")
        try:
            monster_tables = json.loads(raw)
        except json.JSONDecodeError as e:
            raise ValueError(f"MONSTER_TABLES is not valid JSON: {e}") from e

        dynamodb = boto3.resource("dynamodb", endpoint_url=os.environ.get("DYNAMODB_ENDPOINT"))
        return MonsterNameRepository(
            {
                monster: MonsterNameTables(
                    first_names=dynamodb.Table(tables["first_name"]),
                    last_names=dynamodb.Table(tables["last_name"]) if tables["last_name"] else None,
                )
                for monster, tables in monster_tables.items()
            }
        )
