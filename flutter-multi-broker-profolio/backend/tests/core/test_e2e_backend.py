"""Tests for backend-side E2E wrapped credential unwrapping."""

from __future__ import annotations

import base64
import json
from datetime import UTC, datetime, timedelta

import pytest
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from app.core.e2e_backend import (
    WrappedCredentialError,
    WrappedCredentialExpiredError,
    unwrap_from_backend,
)


def test_unwrap_from_dart_generated_fixture_roundtrip() -> None:
    fixture = {
        "keyB64": "AQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyA=",
        "token": "eyJ2IjoxLCJleHBpcmVzQXQiOjE3NjczMjMxNjUwMDAsImN0IjoiZXlKdUlqb2lhSGREZHpBek4wOHpOMEZOV1hOSVVTSXNJbU1pT2lJM2RHNTRNa1ZaV1cxc1MxZElVSGxIZGtwNGVUaEtlVXR5T1ZvM01WcFFSRVZRUnk4aUxDSnRJam9pVGpoV1JXbHZMM2cxV1dWVksyVktVRWh1VFdoTFFUMDlJbjA9In0=",
        "plaintext": '{"apiKey":"k","secret":"s"}',
    }
    key = base64.b64decode(fixture["keyB64"].encode("ascii"))
    now = datetime(2026, 1, 2, 3, 5, 0, tzinfo=UTC)

    plaintext = unwrap_from_backend(fixture["token"], key=key, now=now)

    assert plaintext == fixture["plaintext"]


def test_unwrap_accepts_ct_object_shape() -> None:
    key = bytes(range(1, 33))
    nonce = bytes(range(12))
    plaintext = b'{"appKey":"k","appSecret":"s","accessToken":"t"}'
    encrypted = AESGCM(key).encrypt(nonce, plaintext, None)
    cipher = encrypted[:-16]
    mac = encrypted[-16:]
    payload = {
        "v": 1,
        "expiresAt": int((datetime.now(UTC) + timedelta(minutes=2)).timestamp() * 1000),
        "ct": {
            "nonce": base64.b64encode(nonce).decode("ascii"),
            "cipherBytes": base64.b64encode(cipher).decode("ascii"),
            "mac": base64.b64encode(mac).decode("ascii"),
        },
    }
    token = base64.b64encode(json.dumps(payload, separators=(",", ":")).encode("utf-8")).decode(
        "ascii"
    )

    out = unwrap_from_backend(token, key=key)

    assert out == plaintext.decode("utf-8")


def test_unwrap_rejects_expired_token() -> None:
    key = bytes(range(1, 33))
    payload = {"v": 1, "expiresAt": 1, "ct": "e30="}
    token = base64.b64encode(json.dumps(payload).encode("utf-8")).decode("ascii")

    with pytest.raises(WrappedCredentialExpiredError):
        unwrap_from_backend(token, key=key, now=datetime.now(UTC))


def test_unwrap_rejects_malformed_token() -> None:
    with pytest.raises(WrappedCredentialError):
        unwrap_from_backend("not-base64!!", key=bytes(range(1, 33)))
