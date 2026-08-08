from __future__ import annotations

from typing import Callable, TypeVar

from taifa_merchant.domain.events import DomainEvent

_handlers: list[Callable[[DomainEvent], None]] = []

T = TypeVar("T", bound=DomainEvent)


def register_handler(handler: Callable[[DomainEvent], None]) -> None:
    _handlers.append(handler)


def dispatch(event: DomainEvent) -> None:
    for handler in _handlers:
        handler(event)
