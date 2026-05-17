"""Tests for the Settings loader."""

from __future__ import annotations

from app.core.settings import Settings, get_settings


def test_defaults() -> None:
    s = Settings(_env_file=None)  # type: ignore[call-arg]
    assert s.app_name == "mbp-backend"
    assert s.fx_provider == "exchangerate.host"
    assert s.cors_origins == ["*"]
    assert s.auth_disabled is False


def test_get_settings_cached() -> None:
    a = get_settings()
    b = get_settings()
    assert a is b
