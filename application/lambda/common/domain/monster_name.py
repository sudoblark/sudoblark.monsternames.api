"""Monster name domain model.

A ``MonsterName`` is the name the API serves for a monster: a first name, a
last name, or both, and the full name they make together. Picking the names
from their tables belongs to the repository; the domain stays I/O-free.
"""

from __future__ import annotations

from dataclasses import dataclass


class MonsterNameError(Exception):
    """A monster name invariant was violated."""


@dataclass(frozen=True)
class MonsterName:
    """A monster's name.

    Args:
        first_name: The first name, or None if none was found.
        last_name:  The last name, or None for monsters with first names only,
                    or if none was found.

    Raises:
        MonsterNameError: If neither part is given.
    """

    first_name: str | None = None
    last_name: str | None = None

    def __post_init__(self) -> None:
        if not self.first_name and not self.last_name:
            raise MonsterNameError("A monster name needs a first name or a last name")

    @property
    def full_name(self) -> str:
        """The parts the name has, in order, separated by a space."""
        return " ".join(part for part in (self.first_name, self.last_name) if part)
