"""Unit tests for MonsterNameRepoMixin. Building tables makes no AWS calls."""

import pytest

from common.mixins.repo_mixins import MonsterNameRepoMixin
from common.repositories.monster_name_repository import MonsterNameRepository


class Host(MonsterNameRepoMixin):
    """A class composed with the mixin, as a handler is."""


def test_builds_the_repository_from_monster_tables(monster_tables: dict) -> None:
    repo = Host()._monster_name_repo

    assert isinstance(repo, MonsterNameRepository)
    assert repo.monsters == set(monster_tables)


def test_builds_the_repository_once() -> None:
    host = Host()

    assert host._monster_name_repo is host._monster_name_repo


def test_needs_monster_tables(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("MONSTER_TABLES")

    with pytest.raises(ValueError, match="MONSTER_TABLES"):
        _ = Host()._monster_name_repo


def test_needs_monster_tables_to_be_json(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("MONSTER_TABLES", "{not json")

    with pytest.raises(ValueError, match="not valid JSON"):
        _ = Host()._monster_name_repo


def test_setter_replaces_the_repository() -> None:
    host = Host()
    double = MonsterNameRepository({})

    host._monster_name_repo = double

    assert host._monster_name_repo is double
