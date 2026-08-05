"""Money & Currency — the server mirror of the Flutter client's value objects
(`apps/mobile/lib/features/wallet/domain/money.dart` + `currency.dart`).

Value is stored as an integer count of **minor units** in a single currency.
Arithmetic is exact; `float`/`Decimal` are never used for value so balances,
fees and ledger postings can never drift. Keeping this identical to the client
is what lets the two stay aligned by construction.
"""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from functools import total_ordering


class Currency(Enum):
    # code, symbol, name, minor_unit_digits, display_digits, is_crypto
    TZS = ("TZS", "TSh", "Tanzanian Shilling", 2, 0, False)
    USD = ("USD", "$", "US Dollar", 2, 2, False)
    EUR = ("EUR", "€", "Euro", 2, 2, False)
    KES = ("KES", "KSh", "Kenyan Shilling", 2, 0, False)
    UGX = ("UGX", "USh", "Ugandan Shilling", 0, 0, False)
    RWF = ("RWF", "FRw", "Rwandan Franc", 0, 0, False)
    BIF = ("BIF", "FBu", "Burundian Franc", 0, 0, False)
    ZMW = ("ZMW", "ZK", "Zambian Kwacha", 2, 2, False)
    MWK = ("MWK", "MK", "Malawian Kwacha", 2, 2, False)
    CDF = ("CDF", "FC", "Congolese Franc", 2, 2, False)
    BTC = ("BTC", "₿", "Bitcoin", 8, 6, True)

    def __init__(self, code, symbol, name, minor_unit_digits, display_digits, is_crypto):
        self.code = code
        self.symbol = symbol
        self.currency_name = name
        self.minor_unit_digits = minor_unit_digits
        self.display_digits = display_digits
        self.is_crypto = is_crypto

    @property
    def scale(self) -> int:
        return 10 ** self.minor_unit_digits

    @classmethod
    def from_code(cls, code: str) -> "Currency":
        for c in cls:
            if c.code == code.upper():
                return c
        raise ValueError(f"Unsupported currency: {code}")


@total_ordering
@dataclass(frozen=True)
class Money:
    """An immutable monetary amount in integer minor units."""

    minor_units: int
    currency: Currency

    @classmethod
    def major(cls, major: int, currency: Currency) -> "Money":
        return cls(int(major) * currency.scale, currency)

    @classmethod
    def from_decimal(cls, amount: float, currency: Currency) -> "Money":
        # Round half-up to the currency's minor-unit precision.
        return cls(int(round(amount * currency.scale)), currency)

    @classmethod
    def zero(cls, currency: Currency) -> "Money":
        return cls(0, currency)

    # --- properties ---
    @property
    def is_zero(self) -> bool:
        return self.minor_units == 0

    @property
    def is_positive(self) -> bool:
        return self.minor_units > 0

    @property
    def is_negative(self) -> bool:
        return self.minor_units < 0

    @property
    def as_decimal(self) -> float:
        return self.minor_units / self.currency.scale

    @property
    def abs(self) -> "Money":
        return Money(abs(self.minor_units), self.currency)

    # --- arithmetic (same-currency only) ---
    def _assert_same(self, other: "Money") -> None:
        if self.currency != other.currency:
            raise ValueError(
                f"Currency mismatch: {self.currency.code} vs {other.currency.code}. "
                "Convert via the currency engine before combining."
            )

    def __add__(self, other: "Money") -> "Money":
        self._assert_same(other)
        return Money(self.minor_units + other.minor_units, self.currency)

    def __sub__(self, other: "Money") -> "Money":
        self._assert_same(other)
        return Money(self.minor_units - other.minor_units, self.currency)

    def __neg__(self) -> "Money":
        return Money(-self.minor_units, self.currency)

    def __lt__(self, other: "Money") -> bool:
        self._assert_same(other)
        return self.minor_units < other.minor_units

    # __eq__ + frozen dataclass gives value equality; total_ordering fills the rest.

    def format(self, with_symbol: bool = True, with_sign: bool = False) -> str:
        negative = self.minor_units < 0
        scaled = abs(self.minor_units)
        major = scaled // self.currency.scale
        out = f"{major:,}"
        if self.currency.display_digits > 0:
            padded = str(scaled % self.currency.scale).rjust(self.currency.minor_unit_digits, "0")
            out += "." + padded[: self.currency.display_digits].ljust(self.currency.display_digits, "0")
        sign = "-" if negative else ("+" if with_sign and self.minor_units > 0 else "")
        symbol = f"{self.currency.symbol} " if with_symbol else ""
        return f"{sign}{symbol}{out}"

    def __str__(self) -> str:
        return f"{self.currency.code} {self.format(with_symbol=False)}"
