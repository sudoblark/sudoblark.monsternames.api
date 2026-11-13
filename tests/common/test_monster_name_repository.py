"""Unit tests for MonsterNameRepository, over mocked DynamoDB tables."""

from collections.abc import Callable
from typing import Any

import pytest

from common.domain.monster_name import MonsterName
from common.repositories.monster_name_repository import (
    MonsterNameRepository,
    MonsterNameTables,
)

FIRST_NAMES = "skeleton-first-name"
LAST_NAMES = "skeleton-last-name"


class PagedTable:
    """A table double whose scan returns one page per call, as DynamoDB pages."""

    name = "paged"

    def __init__(self, pages: list[list[str]]) -> None:
        self._pages = pages

    def scan(self, **kwargs: Any) -> dict[str, Any]:
        page = kwargs.get("ExclusiveStartKey", {}).get("page", 0)
        response: dict[str, Any] = {"Items": [{"value": name} for name in self._pages[page]]}
        if page + 1 < len(self._pages):
            response["LastEvaluatedKey"] = {"page": page + 1}
        return response


def skeleton(tables: MonsterNameTables) -> MonsterNameRepository:
    """A repository holding the skeleton's tables."""
    return MonsterNameRepository({"skeleton": tables})


def test_monsters_are_those_the_repository_holds_tables_for(dynamodb: Any) -> None:
    repo = MonsterNameRepository(
        {
            "goatmen": MonsterNameTables(dynamodb.Table("goatmen-first-name")),
            "skeleton": MonsterNameTables(dynamodb.Table(FIRST_NAMES)),
        }
    )

    assert repo.monsters == {"goatmen", "skeleton"}


def test_get_random_name_picks_a_first_and_last_name(dynamodb: Any, seed_table: Callable) -> None:
    seed_table(FIRST_NAMES, ["Reginald"])
    seed_table(LAST_NAMES, ["Montgomery"])
    repo = skeleton(MonsterNameTables(dynamodb.Table(FIRST_NAMES), dynamodb.Table(LAST_NAMES)))

    name = repo.get_random_name("skeleton")

    assert name == MonsterName(first_name="Reginald", last_name="Montgomery")


def test_get_random_name_reads_only_first_names_without_a_last_name_table(
    dynamodb: Any, seed_table: Callable
) -> None:
    seed_table(FIRST_NAMES, ["Fluffy"])
    repo = skeleton(MonsterNameTables(dynamodb.Table(FIRST_NAMES)))

    assert repo.get_random_name("skeleton") == MonsterName(first_name="Fluffy")


def test_get_random_name_skips_a_missing_table(dynamodb: Any, seed_table: Callable) -> None:
    seed_table(FIRST_NAMES, ["Reginald"])
    repo = skeleton(MonsterNameTables(dynamodb.Table(FIRST_NAMES), dynamodb.Table(LAST_NAMES)))

    assert repo.get_random_name("skeleton") == MonsterName(first_name="Reginald")


def test_get_random_name_skips_an_empty_table(dynamodb: Any, seed_table: Callable) -> None:
    seed_table(FIRST_NAMES, ["Reginald"])
    seed_table(LAST_NAMES, [])
    repo = skeleton(MonsterNameTables(dynamodb.Table(FIRST_NAMES), dynamodb.Table(LAST_NAMES)))

    assert repo.get_random_name("skeleton") == MonsterName(first_name="Reginald")


def test_get_random_name_is_none_when_the_tables_hold_no_names(dynamodb: Any) -> None:
    repo = skeleton(MonsterNameTables(dynamodb.Table(FIRST_NAMES), dynamodb.Table(LAST_NAMES)))

    assert repo.get_random_name("skeleton") is None


def test_get_random_name_pages_through_the_scan() -> None:
    repo = skeleton(MonsterNameTables(PagedTable([[], ["Reginald"]])))

    assert repo.get_random_name("skeleton") == MonsterName(first_name="Reginald")


def test_get_random_name_rejects_a_monster_it_holds_no_tables_for() -> None:
    repo = skeleton(MonsterNameTables(PagedTable([["Reginald"]])))

    with pytest.raises(KeyError):
        repo.get_random_name("dragon")
