"""Unit tests for the MonsterNameMapper data mapper. Pure, so no AWS mocks."""

import pytest

from common.domain.monster_name import MonsterName, MonsterNameError
from common.mappers.monster_name_mapper import MonsterNameMapper


def test_to_domain_maps_a_first_and_last_name_item() -> None:
    name = MonsterNameMapper.to_domain({"value": "Reginald"}, {"value": "Montgomery"})

    assert name == MonsterName(first_name="Reginald", last_name="Montgomery")


def test_to_domain_maps_a_first_name_item_alone() -> None:
    assert MonsterNameMapper.to_domain({"value": "Fluffy"}) == MonsterName(first_name="Fluffy")


def test_to_domain_needs_an_item() -> None:
    with pytest.raises(MonsterNameError):
        MonsterNameMapper.to_domain(None, None)
