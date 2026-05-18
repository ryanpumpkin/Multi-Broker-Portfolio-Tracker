"""Service dependency factories for API routes."""

from __future__ import annotations

from functools import lru_cache

from app.adapters.base import SourceAdapter
from app.core.settings import Settings, get_settings
from app.models.domain import Connection
from app.services.aggregator import InMemoryConnectionRepository, PortfolioAggregator
from app.services.fx import (
    ExchangerateHostProvider,
    FxProvider,
    FxService,
    NullFxCacheStore,
    OpenExchangeRatesProvider,
)
from app.services.quote_hub import QuoteHub, QuoteSourceRegistry
from app.services.vault import (
    ConnectionVaultStore,
    CredentialVaultService,
    InMemoryConnectionVaultStore,
    KmsProvider,
    build_kms_provider,
)


class StaticAdapterRegistry(QuoteSourceRegistry):
    """Static mapping-based adapter registry used until vault/connection wiring lands."""

    def __init__(self, adapters: dict[str, SourceAdapter] | None = None) -> None:
        self._adapters = {k.lower(): v for k, v in (adapters or {}).items()}

    def for_connection(self, connection: Connection) -> SourceAdapter | None:
        return self.for_source(connection.source)

    def for_source(self, source: str) -> SourceAdapter | None:
        return self._adapters.get(source.lower())


@lru_cache(maxsize=1)
def get_adapter_registry() -> StaticAdapterRegistry:
    # Stub: backend-vault / backend-adapters wiring will inject real per-user adapters.
    return StaticAdapterRegistry()


@lru_cache(maxsize=1)
def get_connection_repository() -> InMemoryConnectionRepository:
    # Stub: backend-vault will replace this with Firestore-backed connection retrieval.
    return InMemoryConnectionRepository()


@lru_cache(maxsize=1)
def get_fx_service(settings: Settings | None = None) -> FxService:
    cfg = settings or get_settings()
    provider_name = cfg.fx_provider.strip().lower()
    provider: FxProvider
    if provider_name in {"openexchangerates", "openexchangerates.org"}:
        api_key = cfg.fx_provider_api_key
        if not api_key:
            msg = "fx_provider_api_key is required for openexchangerates"
            raise ValueError(msg)
        provider = OpenExchangeRatesProvider(api_key=api_key)
    else:
        provider = ExchangerateHostProvider(api_key=cfg.fx_provider_api_key)
    return FxService(provider=provider, firestore_cache=NullFxCacheStore())


@lru_cache(maxsize=1)
def get_portfolio_aggregator() -> PortfolioAggregator:
    return PortfolioAggregator(
        connections=get_connection_repository(),
        adapters=get_adapter_registry(),
        fx=get_fx_service(),
    )


@lru_cache(maxsize=1)
def get_quote_hub() -> QuoteHub:
    return QuoteHub(get_adapter_registry())


@lru_cache(maxsize=1)
def get_kms_provider(settings: Settings | None = None) -> KmsProvider:
    cfg = settings or get_settings()
    return build_kms_provider(provider_name=cfg.kms_provider, key_id=cfg.kms_key_id)


@lru_cache(maxsize=1)
def get_connection_vault_store() -> ConnectionVaultStore:
    # Stub: backend-vault interface is in place; Firestore wiring comes later.
    return InMemoryConnectionVaultStore()


@lru_cache(maxsize=1)
def get_vault_service() -> CredentialVaultService:
    return CredentialVaultService(
        store=get_connection_vault_store(),
        kms=get_kms_provider(),
    )


__all__ = [
    "StaticAdapterRegistry",
    "get_adapter_registry",
    "get_connection_repository",
    "get_fx_service",
    "get_kms_provider",
    "get_portfolio_aggregator",
    "get_quote_hub",
    "get_connection_vault_store",
    "get_vault_service",
]
