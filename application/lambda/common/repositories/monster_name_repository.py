"""Monster name repository.

``MonsterNameRepository`` reads every monster's name from its name tables: one
of first names and, for most monsters, one of last names. It picks an item from
each at random and maps them into a ``MonsterName``. The API is read-only, so
there is no write.

Usage::

    from common.repositories.monster_name_repository import (
        MonsterNameRepository,
        MonsterNameTables,
    )

    repo = MonsterNameRepository(
        {"skeleton": MonsterNameTables(ddb.Table(first_names), ddb.Table(last_names))}
    )
    if "skeleton" in repo.monsters:
        name = repo.get_random_name("skeleton")
"""

import logging
import random
from collections.abc import Mapping
from typing import Any, NamedTuple

from botocore.exceptions import ClientError

from common.domain.monster_name import MonsterName
from common.mappers.monster_name_mapper import MonsterNameMapper

logger = logging.getLogger(__name__)


class MonsterNameTables(NamedTuple):
    """A monster's name tables, as boto3 DynamoDB ``Table`` resources (or mocks).

    Args:
        first_names: The table of the monster's first names.
        last_names:  The table of its last names, or None for monsters with
                     first names only.
    """

    first_names: Any
    last_names: Any | None = None


class MonsterNameRepository:
    """Read random names from every monster's name tables.

    Args:
        tables: Each monster's name tables, keyed by the monster's name.
    """

    def __init__(self, tables: Mapping[str, MonsterNameTables]) -> None:
        self._tables = dict(tables)

    @property
    def monsters(self) -> frozenset[str]:
        """The monsters the repository holds names for."""
        return frozenset(self._tables)

    def get_random_name(self, monster: str) -> MonsterName | None:
        """A random name for a monster, or None if its tables hold none.

        A table that is missing, unreadable or empty is logged and skipped, so a
        monster whose last-name table can't be read still gets its first name.

        Raises:
            KeyError: If the repository holds no tables for the monster.
        """
        tables = self._tables[monster]
        first_name_item = self._random_item(tables.first_names)
        last_name_item = self._random_item(tables.last_names)
        if first_name_item is None and last_name_item is None:
            return None
        return MonsterNameMapper.to_domain(first_name_item, last_name_item)

    def _random_item(self, table: Any | None) -> dict[str, Any] | None:
        """A random item from one table, or None if it can't give one."""
        if table is None:
            return None
        try:
            items = self._scan_items(table)
        except ClientError as exc:
            logger.error(
                f"Failed to scan table {table.name}: {exc.response['Error']['Code']}",
                exc_info=True,
            )
            return None
        if not items:
            logger.warning(f"No items found in table: {table.name}")
            return None
        return random.choice(items)

    def _scan_items(self, table: Any) -> list[dict[str, Any]]:
        """Every item in a table, paging through DynamoDB's scan."""
        items: list[dict[str, Any]] = []
        last_key = None
        while True:
            kwargs: dict[str, Any] = {}
            if last_key:
                kwargs["ExclusiveStartKey"] = last_key
            response = table.scan(**kwargs)
            items.extend(response.get("Items") or [])
            last_key = response.get("LastEvaluatedKey")
            if not last_key:
                return items
