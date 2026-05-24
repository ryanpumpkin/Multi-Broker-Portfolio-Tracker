#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${IBKR_USERNAME:-}" ]]; then
  echo "IBKR_USERNAME is required" >&2; exit 1
fi
if [[ -z "${IBKR_PASSWORD:-}" ]]; then
  echo "IBKR_PASSWORD is required" >&2; exit 1
fi
export IBKR_TRADING_MODE="${IBKR_TRADING_MODE:-paper}"
export IBKR_API_PORT="${IBKR_API_PORT:-4001}"

# Template the IBC config with credentials from env.
envsubst < /root/ibc/config.ini.template > /root/ibc/config.ini
chmod 600 /root/ibc/config.ini

# Resolve the IB Gateway install dir (its name embeds the version).
TWS_VERSION=$(ls /root/Jts/ibgateway | head -1)
if [[ -z "$TWS_VERSION" ]]; then
  echo "IB Gateway install not found under /root/Jts/ibgateway" >&2
  exit 1
fi
echo "Using IB Gateway version: $TWS_VERSION"

# Start virtual display so the Swing GUI has somewhere to draw.
Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
sleep 2

# Hand off to IBC. It will launch IB Gateway, drive the login GUI,
# and keep restarting if the gateway exits.
exec /opt/ibc/scripts/ibcstart.sh "$TWS_VERSION" \
  -g \
  --tws-path=/root/Jts/ibgateway \
  --ibc-path=/opt/ibc \
  --ibc-ini=/root/ibc/config.ini \
  --mode="$IBKR_TRADING_MODE"
