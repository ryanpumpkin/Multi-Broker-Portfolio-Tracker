"""Unit tests for the pure helpers in `app.adapters.futu.client`.

`FutuOpenDClient` itself is SDK-bound and is only exercised via the
env-gated integration test against a real OpenD. These helpers are
pure and worth covering directly.
"""

from __future__ import annotations

import sys
import types
from typing import Any

import pytest

from app.adapters._common import PermanentError, TransientError
from app.adapters.futu.client import (
    _ensure_ok,
    _extract_error_message,
    _rows_from_payload,
)


@pytest.fixture
def stub_futu(monkeypatch: pytest.MonkeyPatch) -> types.ModuleType:
    """Inject a minimal fake `futu` module exposing the constants the
    helpers need (RET_OK)."""
    module = types.ModuleType("futu")
    module.RET_OK = 0  # type: ignore[attr-defined]
    monkeypatch.setitem(sys.modules, "futu", module)
    return module


# ---------------------------------------------------------------------------
# _rows_from_payload
# ---------------------------------------------------------------------------


def test_rows_from_payload_none() -> None:
    assert _rows_from_payload(None) == []


def test_rows_from_payload_list_of_dicts_filters_non_dicts() -> None:
    rows = _rows_from_payload([{"a": 1}, "junk", {"b": 2}, 99])
    assert rows == [{"a": 1}, {"b": 2}]


def test_rows_from_payload_dataframe_like() -> None:
    class _DF:
        def to_dict(self, orient: str) -> list[dict[str, Any]]:
            assert orient == "records"
            return [{"x": 1}, "junk", {"y": 2}]  # type: ignore[list-item]

    assert _rows_from_payload(_DF()) == [{"x": 1}, {"y": 2}]


def test_rows_from_payload_dataframe_non_list_falls_through_to_error() -> None:
    class _DF:
        def to_dict(self, _orient: str) -> Any:
            return {"not": "a list"}

    with pytest.raises(RuntimeError):
        _rows_from_payload(_DF())


def test_rows_from_payload_single_dict_wrapped() -> None:
    assert _rows_from_payload({"a": 1}) == [{"a": 1}]


def test_rows_from_payload_unsupported_raises() -> None:
    with pytest.raises(RuntimeError):
        _rows_from_payload(42)


# ---------------------------------------------------------------------------
# _extract_error_message
# ---------------------------------------------------------------------------


def test_extract_error_string() -> None:
    assert _extract_error_message("boom") == "boom"


@pytest.mark.parametrize(
    "field",
    ["msg", "message", "err_msg"],
)
def test_extract_error_dict_known_fields(field: str) -> None:
    assert _extract_error_message({field: "denied"}) == "denied"


def test_extract_error_dict_unknown_field_falls_back_to_str() -> None:
    payload = {"unknown": "value"}
    assert _extract_error_message(payload) == str(payload)


def test_extract_error_other_object_falls_back_to_str() -> None:
    assert _extract_error_message(42) == "42"


# ---------------------------------------------------------------------------
# _ensure_ok
# ---------------------------------------------------------------------------


def test_ensure_ok_returns_silently_on_success(stub_futu: types.ModuleType) -> None:
    # Should not raise.
    _ensure_ok(stub_futu.RET_OK, [], operation="position_list_query")


@pytest.mark.parametrize(
    "message",
    [
        "rate limit exceeded",
        "Too Many Requests",
        "quota exhausted",
        "throttle hit",
        "Service temporarily unavailable",
        "timeout reading",
    ],
)
def test_ensure_ok_transient_markers(
    stub_futu: types.ModuleType, message: str,
) -> None:
    with pytest.raises(TransientError):
        _ensure_ok(-1, {"err_msg": message}, operation="x")


@pytest.mark.parametrize(
    "message",
    [
        "unlock first",
        "password required",
        "invalid pwd",
        "missing credential",
        "permission denied",
        "Unauthorized",
        "Forbidden",
        "auth failure",
    ],
)
def test_ensure_ok_credential_markers(
    stub_futu: types.ModuleType, message: str,
) -> None:
    with pytest.raises(PermanentError):
        _ensure_ok(-1, {"err_msg": message}, operation="x")


def test_ensure_ok_unclassified_raises_runtimeerror(
    stub_futu: types.ModuleType,
) -> None:
    with pytest.raises(RuntimeError) as exc_info:
        _ensure_ok(-1, {"err_msg": "weird"}, operation="op_x")
    assert "op_x" in str(exc_info.value)
