"""Unit tests for the MonsterName domain object. Pure, so no AWS mocks."""

import dataclasses

import pytest

from common.domain.monster_name import MonsterName, MonsterNameError


def test_full_name_joins_the_first_and_last_names() -> None:
    name = MonsterName(first_name="Reginald", last_name="Montgomery")

    assert name.full_name == "Reginald Montgomery"


def test_full_name_is_the_first_name_for_a_monster_without_last_names() -> None:
    assert MonsterName(first_name="Fluffy").full_name == "Fluffy"


def test_full_name_is_the_last_name_when_no_first_name_was_found() -> None:
    assert MonsterName(last_name="Montgomery").full_name == "Montgomery"


@pytest.mark.parametrize("first_name", [None, ""])
def test_a_name_needs_a_first_or_last_name(first_name: str | None) -> None:
    with pytest.raises(MonsterNameError):
        MonsterName(first_name=first_name)


def test_a_name_cannot_be_changed() -> None:
    name = MonsterName(first_name="Reginald")

    with pytest.raises(dataclasses.FrozenInstanceError):
        name.first_name = "Mortimer"  # type: ignore[misc]
