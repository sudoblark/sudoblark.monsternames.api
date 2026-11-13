"""Tests for the backend Lambda handler, with a repository double.

The handler gets its repository through ``MonsterNameRepoMixin``, so each test
passes a double through the mixin's setter and makes no AWS calls.
"""

import json
from collections.abc import Callable
from typing import Any

import pytest

from common.domain.monster_name import MonsterName
from handler import MonsterNamesHandler, handler


class FakeMonsterNameRepository:
    """A repository double holding a fixed name for each monster it knows."""

    def __init__(self, names: dict[str, MonsterName | None]) -> None:
        self._names = names
        self.requested: list[str] = []

    @property
    def monsters(self) -> frozenset[str]:
        return frozenset(self._names)

    def get_random_name(self, monster: str) -> MonsterName | None:
        self.requested.append(monster)
        return self._names[monster]


def handle(
    repository: FakeMonsterNameRepository | None, event: dict[str, Any], context: Any
) -> tuple[int, Any]:
    """Call a handler over the repository and decode its response body."""
    monster_names_handler = MonsterNamesHandler()
    if repository is not None:
        monster_names_handler._monster_name_repo = repository
    response = monster_names_handler.handle(event, context)
    return response["statusCode"], json.loads(response["body"])


def test_get_returns_first_last_and_full_name(api_event: Callable, lambda_context: Any) -> None:
    repository = FakeMonsterNameRepository(
        {"skeleton": MonsterName(first_name="Reginald", last_name="Montgomery")}
    )

    status, body = handle(repository, api_event("/skeleton"), lambda_context)

    assert status == 200
    assert body == {
        "first_name": "Reginald",
        "last_name": "Montgomery",
        "full_name": "Reginald Montgomery",
    }
    assert repository.requested == ["skeleton"]


def test_get_returns_first_name_only_for_monsters_without_last_names(
    api_event: Callable, lambda_context: Any
) -> None:
    repository = FakeMonsterNameRepository({"goatmen": MonsterName(first_name="Fluffy")})

    status, body = handle(repository, api_event("/goatmen"), lambda_context)

    assert status == 200
    assert body == {"first_name": "Fluffy", "full_name": "Fluffy"}


def test_get_without_names_returns_500(api_event: Callable, lambda_context: Any) -> None:
    repository = FakeMonsterNameRepository({"skeleton": None})

    status, body = handle(repository, api_event("/skeleton"), lambda_context)

    assert status == 500
    assert body == {"error": "Unable to find name entries in database"}


def test_unknown_monster_returns_404(api_event: Callable, lambda_context: Any) -> None:
    repository = FakeMonsterNameRepository({"skeleton": MonsterName(first_name="Reginald")})

    status, body = handle(repository, api_event("/dragon"), lambda_context)

    assert status == 404
    assert body == {"error": "Endpoint does not exist"}
    assert repository.requested == []


def test_missing_monster_tables_returns_500(
    monkeypatch: pytest.MonkeyPatch, api_event: Callable, lambda_context: Any
) -> None:
    monkeypatch.delenv("MONSTER_TABLES")

    status, body = handle(None, api_event("/skeleton"), lambda_context)

    assert status == 500
    assert body == {"error": "Configuration error"}


@pytest.mark.parametrize("method", ["POST", "PUT", "DELETE"])
def test_write_methods_return_405(method: str, api_event: Callable, lambda_context: Any) -> None:
    repository = FakeMonsterNameRepository({"skeleton": MonsterName(first_name="Reginald")})

    status, body = handle(
        repository, api_event("/skeleton", method, {"first_name": "Mortimer"}), lambda_context
    )

    assert status == 405
    assert body == {"error": f"'{method}' method not supported for endpoint '/skeleton'"}
    assert repository.requested == []


def test_get_ignores_the_request_body(api_event: Callable, lambda_context: Any) -> None:
    repository = FakeMonsterNameRepository({"goatmen": MonsterName(first_name="Fluffy")})

    status, body = handle(repository, api_event("/goatmen", "GET", "{not json"), lambda_context)

    assert status == 200
    assert body == {"first_name": "Fluffy", "full_name": "Fluffy"}


def test_lambda_calls_a_monster_names_handler() -> None:
    assert isinstance(handler.__self__, MonsterNamesHandler)
