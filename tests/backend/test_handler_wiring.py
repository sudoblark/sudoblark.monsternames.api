"""End-to-end tests of the backend Lambda over mocked DynamoDB tables.

These pass no repository double, so the handler builds its repository from
MONSTER_TABLES through the mixin, as it does in Lambda, and reads moto's
tables through the mapper and domain layers.
"""

import json
from collections.abc import Callable
from typing import Any

import pytest

from handler import MonsterNamesHandler

MONSTERS_WITH_LAST_NAMES = ["goblin", "orc", "skeleton", "troll"]
MONSTERS_WITH_FIRST_NAMES_ONLY = ["goatmen", "ogre"]


def invoke(event: dict[str, Any], context: Any) -> tuple[int, Any]:
    """Call a fresh handler and decode its response body."""
    response = MonsterNamesHandler().handle(event, context)
    return response["statusCode"], json.loads(response["body"])


@pytest.mark.parametrize("monster", MONSTERS_WITH_LAST_NAMES)
def test_get_reads_a_first_and_last_name_from_the_tables(
    monster: str,
    monster_tables: dict,
    seed_table: Callable,
    api_event: Callable,
    lambda_context: Any,
) -> None:
    first_names = {"Reginald", "Mortimer"}
    last_names = {"Montgomery", "Gongleson"}
    seed_table(monster_tables[monster]["first_name"], first_names)
    seed_table(monster_tables[monster]["last_name"], last_names)

    status, body = invoke(api_event(f"/{monster}"), lambda_context)

    assert status == 200
    assert body["first_name"] in first_names
    assert body["last_name"] in last_names
    assert body["full_name"] == f"{body['first_name']} {body['last_name']}"


@pytest.mark.parametrize("monster", MONSTERS_WITH_FIRST_NAMES_ONLY)
def test_get_reads_a_first_name_only_for_monsters_without_last_names(
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


def test_get_without_tables_returns_500_and_creates_none(
    dynamodb: Any, api_event: Callable, lambda_context: Any
) -> None:
    status, body = invoke(api_event("/skeleton"), lambda_context)

    assert status == 500
    assert body == {"error": "Unable to find name entries in database"}
    assert list(dynamodb.tables.all()) == [], "the Lambda must never create tables"
