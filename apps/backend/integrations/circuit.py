"""Circuit breaker for outbound integration calls."""
from __future__ import annotations

import threading
import time
from dataclasses import dataclass


class CircuitOpen(Exception):
    """Raised when the circuit is open and calls are short-circuited."""

    def __init__(self, name: str, retry_after_s: float):
        self.name = name
        self.retry_after_s = retry_after_s
        super().__init__(f"circuit open for {name}; retry after {retry_after_s:.1f}s")


@dataclass
class _State:
    failures: int = 0
    opened_at: float = 0.0
    state: str = "closed"  # closed | open | half_open


class CircuitBreaker:
    """Per-integration circuit breaker (process-local; Redis optional later)."""

    def __init__(
        self,
        *,
        name: str,
        failure_threshold: int = 5,
        recovery_timeout_s: float = 30.0,
    ):
        self.name = name
        self.failure_threshold = failure_threshold
        self.recovery_timeout_s = recovery_timeout_s
        self._state = _State()
        self._lock = threading.Lock()

    def before_call(self) -> None:
        with self._lock:
            if self._state.state == "open":
                elapsed = time.monotonic() - self._state.opened_at
                if elapsed < self.recovery_timeout_s:
                    raise CircuitOpen(self.name, self.recovery_timeout_s - elapsed)
                self._state.state = "half_open"

    def record_success(self) -> None:
        with self._lock:
            self._state = _State()

    def record_failure(self) -> None:
        with self._lock:
            self._state.failures += 1
            if self._state.state == "half_open" or self._state.failures >= self.failure_threshold:
                self._state.state = "open"
                self._state.opened_at = time.monotonic()

    @property
    def status(self) -> dict:
        with self._lock:
            return {
                "name": self.name,
                "state": self._state.state,
                "failures": self._state.failures,
            }


_BREAKERS: dict[str, CircuitBreaker] = {}
_BREAKERS_LOCK = threading.Lock()


def get_breaker(name: str, **kwargs) -> CircuitBreaker:
    with _BREAKERS_LOCK:
        if name not in _BREAKERS:
            _BREAKERS[name] = CircuitBreaker(name=name, **kwargs)
        return _BREAKERS[name]
