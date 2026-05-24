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

# Resolve the IB Gateway install dir. The installer creates a
# `data/` sibling we have to skip; the real one is the numeric
# version directory.
TWS_VERSION=$(ls /root/Jts/ibgateway | grep -E '^[0-9]+' | head -1)
if [[ -z "$TWS_VERSION" ]]; then
  echo "IB Gateway install not found under /root/Jts/ibgateway" >&2
  ls /root/Jts/ibgateway >&2
  exit 1
fi
echo "Using IB Gateway version: $TWS_VERSION"

# Start virtual display so the Swing GUI has somewhere to draw.
Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
sleep 2

# Hand off to IBC's gatewaystart.sh — it sets up the classpath and
# environment IBC expects, then runs scripts/ibcstart.sh under the
# hood. Configuration is read from the templated config.ini.
exec /opt/ibc/gatewaystart.sh \
  -inline \
  --gateway \
  --tws-path=/root/Jts/ibgateway \
  --ibc-path=/opt/ibc \
  --ibc-ini=/root/ibc/config.ini \
  --tws-settings-path=/root/Jts/settings \
  --mode="$IBKR_TRADING_MODE"
