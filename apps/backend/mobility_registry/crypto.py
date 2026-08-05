"""Application-layer encryption and blind indexes for registry PII/documents."""
from __future__ import annotations

import base64
import hashlib
import hmac
import os
from dataclasses import dataclass

from django.conf import settings
from cryptography.hazmat.primitives.ciphers.aead import AESGCM


class RegistryCryptoError(Exception):
    pass


@dataclass(frozen=True)
class CipherValue:
    ciphertext: bytes
    nonce: bytes
    key_version: str


def _keys() -> dict[str, bytes]:
    configured = getattr(settings, "MOBILITY_DOCUMENT_KEYS", {})
    keys: dict[str, bytes] = {}
    for version, encoded in configured.items():
        try:
            value = base64.b64decode(encoded, validate=True)
        except Exception as exc:
            raise RegistryCryptoError(f"invalid registry key encoding: {version}") from exc
        if len(value) not in {16, 24, 32}:
            raise RegistryCryptoError(f"invalid registry AES key length: {version}")
        keys[str(version)] = value
    if not keys:
        raise RegistryCryptoError("no mobility registry encryption keys configured")
    return keys


def active_key_version() -> str:
    version = str(getattr(settings, "MOBILITY_ACTIVE_DOCUMENT_KEY_VERSION", ""))
    if version not in _keys():
        raise RegistryCryptoError("active mobility registry key is unavailable")
    return version


def encrypt_bytes(value: bytes, *, context: str) -> CipherValue:
    version = active_key_version()
    nonce = os.urandom(12)
    ciphertext = AESGCM(_keys()[version]).encrypt(nonce, value, context.encode())
    return CipherValue(ciphertext=ciphertext, nonce=nonce, key_version=version)


def decrypt_bytes(value: bytes, nonce: bytes, *, key_version: str, context: str) -> bytes:
    try:
        key = _keys()[key_version]
        return AESGCM(key).decrypt(bytes(nonce), bytes(value), context.encode())
    except Exception as exc:
        raise RegistryCryptoError("registry payload authentication failed") from exc


def encrypt_text(value: str, *, context: str) -> CipherValue:
    return encrypt_bytes(value.strip().encode("utf-8"), context=context)


def blind_index(value: str) -> str:
    key = getattr(settings, "MOBILITY_PII_INDEX_KEY", "").encode()
    if len(key) < 32:
        raise RegistryCryptoError("MOBILITY_PII_INDEX_KEY must contain at least 32 bytes")
    normalized = "".join(value.strip().upper().split())
    return hmac.new(key, normalized.encode(), hashlib.sha256).hexdigest()


def mask(value: str, *, visible: int = 4) -> str:
    compact = value.strip()
    if len(compact) <= visible:
        return "*" * len(compact)
    return "*" * (len(compact) - visible) + compact[-visible:]
