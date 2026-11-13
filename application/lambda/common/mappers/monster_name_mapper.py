"""Data Mapper: a ``MonsterName`` ⇄ its items in a monster's name tables.

A monster's name is stored across up to two tables, one of first names and one
of last names. Each holds one item per name, keyed by ``value`` (hash only), as
Terraform writes them from application/seed_data/. The repository picks an
item from each table, and the mapper turns them into the name. The API is
read-only, so the mapper only reads.
"""

from typing import Any

from common.domain.monster_name import MonsterName


class MonsterNameMapper:
    """Translate a monster's name-table items into its ``MonsterName``."""

    @staticmethod
    def to_domain(
        first_name_item: dict[str, Any] | None, last_name_item: dict[str, Any] | None = None
    ) -> MonsterName:
        """Map the items picked from a monster's tables into its name.

        Args:
            first_name_item: An item from the first-name table, or None if none
                was picked.
            last_name_item:  An item from the last-name table, or None for
                monsters with first names only, or if none was picked.

        Raises:
            MonsterNameError: If neither item is given.
        """
        return MonsterName(
            first_name=str(first_name_item["value"]) if first_name_item else None,
            last_name=str(last_name_item["value"]) if last_name_item else None,
        )
