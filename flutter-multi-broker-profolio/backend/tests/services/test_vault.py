"""Tests for vault service and credential mode flows."""

from __future__ import annotations

import json
from typing import Any

import pytest

from app.services.vault import (
    FAILED_DECRYPT_COUNTER,
    ConnectionMetadata,
    CreateConnectionInput,
    CredentialMode,
    CredentialVaultService,
    E2ECredentialCodec,
    InMemoryConnectionVaultStore,
    InMemoryKmsProvider,
    SwitchModeInput,
    VaultValidationError,
)


class _Recorder:
    def __init__(self) -> None:
        self.events: list[tuple[str, dict[str, Any]]] = []

    def info(self, event: str, **kwargs: Any) -> None:
        self.events.append((event, kwargs))


def _failed_counter_value(*, mode: str, reason: str) -> float:
    for metric in FAILED_DECRYPT_COUNTER.collect():
        for sample in metric.samples:
            if sample.name == "mbp_vault_failed_decrypt_total" and sample.labels == {
                "mode": mode,
                "reason": reason,
            }:
                return float(sample.value)
    return 0.0


@pytest.mark.asyncio
async def test_round_trip_encrypt_decrypt_for_both_modes() -> None:
    service = CredentialVaultService(
        store=InMemoryConnectionVaultStore(),
        kms=InMemoryKmsProvider(),
    )

    user_id = "user-1"
    token = "short-lived-token"
    secret = "binance-read-only-secret"
    blob = E2ECredentialCodec.encrypt(secret, client_token=token)

    meta_e2e = await service.create_connection(
        user_id,
        CreateConnectionInput(
            source="binance",
            display_name="Binance",
            connection_id="conn-e2e",
            credential_mode=CredentialMode.E2E,
            encrypted_blob=blob,
        ),
    )
    roundtrip_e2e = await service.use_credential(
        user_id=user_id,
        connection_id="conn-e2e",
        purpose="list_positions",
        client_token=token,
        fn=lambda plaintext: plaintext,
    )

    meta_server = await service.create_connection(
        user_id,
        CreateConnectionInput(
            source="ibkr",
            display_name="IBKR",
            connection_id="conn-server",
            credential_mode=CredentialMode.SERVER_KEY,
            plaintext_for_server_mode=secret,
        ),
    )
    roundtrip_server = await service.use_credential(
        user_id=user_id,
        connection_id="conn-server",
        purpose="list_positions",
        client_token=None,
        fn=lambda plaintext: plaintext,
    )

    assert isinstance(meta_e2e, ConnectionMetadata)
    assert meta_e2e.credential_mode is CredentialMode.E2E
    assert roundtrip_e2e == secret
    assert meta_server.credential_mode is CredentialMode.SERVER_KEY
    assert roundtrip_server == secret


@pytest.mark.asyncio
async def test_mode_switch_reencrypts_blob_correctly() -> None:
    service = CredentialVaultService(
        store=InMemoryConnectionVaultStore(),
        kms=InMemoryKmsProvider(),
    )

    user_id = "user-2"
    token = "token-2"
    secret = "longbridge-token"
    blob = E2ECredentialCodec.encrypt(secret, client_token=token)

    await service.create_connection(
        user_id,
        CreateConnectionInput(
            source="longbridge",
            display_name="LongBridge",
            connection_id="conn-1",
            credential_mode=CredentialMode.E2E,
            encrypted_blob=blob,
        ),
    )

    to_server = await service.switch_mode(
        user_id,
        "conn-1",
        SwitchModeInput(
            credential_mode=CredentialMode.SERVER_KEY,
            client_token=token,
        ),
    )
    assert to_server.credential_mode is CredentialMode.SERVER_KEY

    via_server = await service.use_credential(
        user_id=user_id,
        connection_id="conn-1",
        purpose="list_balances",
        client_token=None,
        fn=lambda plaintext: plaintext,
    )
    assert via_server == secret

    to_e2e = await service.switch_mode(
        user_id,
        "conn-1",
        SwitchModeInput(
            credential_mode=CredentialMode.E2E,
            client_token=token,
        ),
    )
    assert to_e2e.credential_mode is CredentialMode.E2E

    via_e2e = await service.use_credential(
        user_id=user_id,
        connection_id="conn-1",
        purpose="list_transactions",
        client_token=token,
        fn=lambda plaintext: plaintext,
    )
    assert via_e2e == secret


@pytest.mark.asyncio
async def test_negative_server_cannot_decrypt_e2e_without_token() -> None:
    service = CredentialVaultService(
        store=InMemoryConnectionVaultStore(),
        kms=InMemoryKmsProvider(),
    )

    user_id = "user-3"
    token = "token-3"
    blob = E2ECredentialCodec.encrypt("futu-secret", client_token=token)

    await service.create_connection(
        user_id,
        CreateConnectionInput(
            source="futu",
            display_name="Futu",
            connection_id="conn-1",
            credential_mode=CredentialMode.E2E,
            encrypted_blob=blob,
        ),
    )

    before = _failed_counter_value(mode="e2e", reason="missing_token")
    with pytest.raises(VaultValidationError, match="client_token"):
        await service.use_credential(
            user_id=user_id,
            connection_id="conn-1",
            purpose="list_positions",
            client_token=None,
            fn=lambda plaintext: plaintext,
        )
    after = _failed_counter_value(mode="e2e", reason="missing_token")

    assert after >= before + 1.0


@pytest.mark.asyncio
async def test_credential_use_audit_log_omits_plaintext() -> None:
    recorder = _Recorder()
    service = CredentialVaultService(
        store=InMemoryConnectionVaultStore(),
        kms=InMemoryKmsProvider(),
        logger=recorder,
    )

    user_id = "user-4"
    secret = "super-secret-value"
    await service.create_connection(
        user_id,
        CreateConnectionInput(
            source="ibkr",
            display_name="IBKR",
            connection_id="conn-1",
            credential_mode=CredentialMode.SERVER_KEY,
            plaintext_for_server_mode=secret,
        ),
    )

    _ = await service.use_credential(
        user_id=user_id,
        connection_id="conn-1",
        purpose="healthcheck",
        client_token=None,
        fn=lambda plaintext: plaintext,
    )

    assert recorder.events
    event, payload = recorder.events[-1]
    assert event == "credential_use"
    assert payload["user_id"] == user_id
    assert payload["connection_id"] == "conn-1"
    assert payload["mode"] == CredentialMode.SERVER_KEY.value
    assert payload["purpose"] == "healthcheck"
    assert secret not in json.dumps(payload)
