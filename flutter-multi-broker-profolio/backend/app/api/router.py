"""Top-level /v1 router. Feature routers are mounted by their owning modules."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from app.middleware.auth import AuthenticatedUser, current_user

api_router = APIRouter(prefix="/v1")


@api_router.get("/whoami", summary="Echo the authenticated user (smoke test)")
def whoami(user: Annotated[AuthenticatedUser, Depends(current_user)]) -> dict[str, str | None]:
    """Return the authenticated user; used by integration tests and uptime probes."""
    return {"user_id": user.user_id, "email": user.email}
