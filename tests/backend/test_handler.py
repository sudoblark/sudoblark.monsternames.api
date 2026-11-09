"""Behaviour tests for the backend Lambda handler."""

import json
from collections.abc import Callable
from typing import Any

import pytest

from backend_lambda.main import handler

MONSTERS_WITH_LAST_NAMES = ["goblin", "orc", "skeleton", "troll"]
MONSTERS_WITH_FIRST_NAMES_ONLY = ["goatmen", "ogre"]


def invoke(event: dict[str, Any], context: Any) -> tuple:
    """Call the handler and decode its response body."""
    response = handler(event, context)
    return response["statusCode"], json.loads(response["body"])


@pytest.mark.parametrize("monster", MONSTERS_WITH_LAST_NAMES)
def test_get_returns_first_last_and_full_name(
    monster: str,
    monster_tables: dict,
    seed_table: Callable,
    api_event: Callable,
    lambda_context: Any,
) -> None:
    seed_table(monster_tables[monster]["first_name"], ["Reginald"])
    seed_table(monster_tables[monster]["last_name"], ["Montgomery"])

    status, body = invoke(api_event(f"/{monster}"), lambda_context)

    assert status == 200
    assert body == {
        "first_name": "Reginald",
        "last_name": "Montgomery",
        "full_name": "Reginald Montgomery",
    }


@pytest.mark.parametrize("monster", MONSTERS_WITH_FIRST_NAMES_ONLY)
def test_get_returns_first_name_only_for_monsters_without_last_names(
    monster: str,
    monster_tables: dict,
    seed_table: Callable,
    api_event: Callable,
    lambda_context: Any,
) -> None:
    seed_table(monster_tables[monster]["first_name"], ["Fluffy"])

    status, body = invoke(api_event(f"/{monster}"), lambda_context)

    assert status == 200
    assert body == {"first_name": "Fluffy", "full_name": "Fluffy"}


def test_get_picks_a_name_from_the_table(
    monster_tables: dict, seed_table: Callable, api_event: Callable, lambda_context: Any
) -> None:
    names = {"Bomp", "Gog", "Wob"}
    seed_table(monster_tables["ogre"]["first_name"], names)

    status, body = invoke(api_event("/ogre"), lambda_context)

    assert status == 200
    assert body["first_name"] in names


def test_get_without_tables_returns_500(
    dynamodb: Any, api_event: Callable, lambda_context: Any
) -> None:
    status, body = invoke(api_event("/skeleton"), lambda_context)

    assert status == 500
    assert body == {"error": "Unable to find name entries in database"}
    assert list(dynamodb.tables.all()) == [], "the Lambda must never create tables"


def test_unknown_monster_returns_404(
    dynamodb: Any, api_event: Callable, lambda_context: Any
) -> None:
    status, body = invoke(api_event("/dragon"), lambda_context)

    assert status == 404
    assert body == {"error": "Endpoint does not exist"}


def test_missing_monster_tables_returns_500(
    monkeypatch: pytest.MonkeyPatch, dynamodb: Any, api_event: Callable, lambda_context: Any
) -> None:
    monkeypatch.delenv("MONSTER_TABLES")

    status, body = invoke(api_event("/skeleton"), lambda_context)

    assert status == 500
    assert body == {"error": "Configuration error"}


@pytest.mark.parametrize("method", ["POST", "PUT", "DELETE"])
def test_write_methods_return_405(
    method: str,
    monster_tables: dict,
    seed_table: Callable,
    api_event: Callable,
    lambda_context: Any,
) -> None:
    seed_table(monster_tables["skeleton"]["first_name"], ["Reginald"])

    status, body = invoke(
        api_event("/skeleton", method, {"first_name": "Mortimer"}), lambda_context
    )

    assert status == 405
    assert body == {"error": f"'{method}' method not supported for endpoint '/skeleton'"}


def test_get_ignores_the_request_body(
    monster_tables: dict, seed_table: Callable, api_event: Callable, lambda_context: Any
) -> None:
    seed_table(monster_tables["goatmen"]["first_name"], ["Fluffy"])

    status, body = invoke(api_event("/goatmen", "GET", "{not json"), lambda_context)

    assert status == 200
    assert body == {"first_name": "Fluffy", "full_name": "Fluffy"}
