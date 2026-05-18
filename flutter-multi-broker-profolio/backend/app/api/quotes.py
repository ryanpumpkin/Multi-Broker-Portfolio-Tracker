"""Quote stream WebSocket endpoint."""

from __future__ import annotations

import asyncio
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect

from app.services.dependencies import get_quote_hub
from app.services.quote_hub import QuoteHub

router = APIRouter(tags=["quotes"])


async def _sender(websocket: WebSocket, queue: asyncio.Queue[dict[str, object]]) -> None:
    while True:
        payload = await queue.get()
        await websocket.send_json(payload)


@router.websocket("/quotes/stream")
async def quote_stream(
    websocket: WebSocket,
    hub: Annotated[QuoteHub, Depends(get_quote_hub)],
) -> None:
    await websocket.accept()
    client_id = str(uuid4())
    queue = await hub.register_client(client_id)
    sender_task = asyncio.create_task(_sender(websocket, queue))

    try:
        while True:
            frame = await websocket.receive_json()
            if not isinstance(frame, dict):
                await websocket.send_json({"type": "error", "message": "Frame must be an object"})
                continue

            kind = str(frame.get("type", "")).lower()
            source = str(frame.get("source", "")).strip().lower()
            symbols_raw = frame.get("symbols", [])
            symbols = [str(item) for item in symbols_raw] if isinstance(symbols_raw, list) else []

            if kind == "subscribe":
                await hub.subscribe(client_id, source=source, symbols=symbols)
                await websocket.send_json({"type": "ack", "action": "subscribe", "source": source})
            elif kind == "unsubscribe":
                await hub.unsubscribe(client_id, source=source, symbols=symbols)
                await websocket.send_json({"type": "ack", "action": "unsubscribe", "source": source})
            elif kind == "ping":
                await websocket.send_json({"type": "pong"})
            else:
                await websocket.send_json({"type": "error", "message": f"Unsupported frame type '{kind}'"})
    except WebSocketDisconnect:
        pass
    finally:
        sender_task.cancel()
        await asyncio.gather(sender_task, return_exceptions=True)
        await hub.unregister_client(client_id)
