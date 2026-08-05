"""Fail-closed document type and malware scanning boundary."""
from __future__ import annotations

from importlib import import_module
from typing import Protocol

from django.conf import settings


class DocumentScanner(Protocol):
    def scan(self, *, payload: bytes, filename: str, content_type: str) -> bool: ...


class DocumentSecurityError(Exception):
    pass


def validate_magic(payload: bytes, content_type: str) -> None:
    signatures = {
        "application/pdf": lambda value: value.startswith(b"%PDF-"),
        "image/jpeg": lambda value: value.startswith(b"\xff\xd8\xff"),
        "image/png": lambda value: value.startswith(b"\x89PNG\r\n\x1a\n"),
        "image/webp": lambda value: (
            len(value) >= 12 and value.startswith(b"RIFF") and value[8:12] == b"WEBP"
        ),
    }
    validator = signatures.get(content_type)
    if validator is None or not validator(payload):
        raise DocumentSecurityError("document content does not match declared type")


def scan_document(*, payload: bytes, filename: str, content_type: str) -> None:
    validate_magic(payload, content_type)
    path = getattr(settings, "MOBILITY_DOCUMENT_SCANNER", "")
    if not path:
        if settings.DEBUG or getattr(settings, "RUNNING_TESTS", False):
            return
        raise DocumentSecurityError("document malware scanner is not configured")
    module_name, class_name = path.rsplit(".", 1)
    scanner: DocumentScanner = getattr(import_module(module_name), class_name)()
    if not scanner.scan(payload=payload, filename=filename, content_type=content_type):
        raise DocumentSecurityError("document failed malware scanning")
