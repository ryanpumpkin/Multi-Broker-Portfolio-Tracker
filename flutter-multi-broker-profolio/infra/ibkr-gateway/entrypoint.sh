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

# Resolve the IB Gateway version. The installer creates a numeric
# directory like /root/Jts/1019/ — we pass that version number to
# IBC's gatewaystart.sh via the TWS_MAJOR_VRSN env var.
TWS_VERSION=$(ls /root/Jts | grep -E '^[0-9]+$' | head -1)
if [[ -z "$TWS_VERSION" ]]; then
  echo "IB Gateway install not found under /root/Jts" >&2
  ls /root/Jts >&2
  exit 1
fi
echo "Using IB Gateway version: $TWS_VERSION"
export TWS_MAJOR_VRSN="$TWS_VERSION"
export TWS_PATH=/root/Jts
export IBC_PATH=/opt/ibc
export IBC_INI=/root/ibc/config.ini
export TWS_SETTINGS_PATH=/root/Jts/settings
export LOG_PATH=/root/ibc/logs
# IBC's launcher reads TRADING_MODE (not IBKR_TRADING_MODE). Map it.
export TRADING_MODE="$IBKR_TRADING_MODE"
# Also pass user/password directly — belt-and-suspenders with the
# templated config.ini values.
export TWSUSERID="$IBKR_USERNAME"
export TWSPASSWORD="$IBKR_PASSWORD"
mkdir -p "$LOG_PATH" "$TWS_SETTINGS_PATH"

# Start virtual display so the Swing GUI has somewhere to draw.
Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
sleep 2

# Hand off to IBC's gatewaystart.sh. `-inline` keeps logs on stdout
# so docker logs captures everything.
exec /opt/ibc/gatewaystart.sh -inline
