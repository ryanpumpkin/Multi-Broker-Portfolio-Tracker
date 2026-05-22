#!/usr/bin/env bash
# Send the SMS verification code to a running futu-opend container via
# its Telnet console.
#
# Usage:
#   infra/futu-opend/verify-sms.sh <6-digit-code>
#
# Run this *after* `docker compose up futu-opend` has logged
# "SMS verification code requested successfully". Futu sends the code
# to the phone on file. Type it into the script as the only argument.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <sms-code>" >&2
  exit 1
fi

CODE="$1"
HOST="${FUTU_OPEND_TELNET_HOST:-127.0.0.1}"
PORT="${FUTU_OPEND_TELNET_PORT:-22222}"

# OpenD's telnet protocol expects CRLF line endings. Send the verify
# code, give it a beat to process, then disconnect.
{
  printf 'input_phone_verify_code -code=%s\r\n' "$CODE"
  sleep 2
  printf 'exit\r\n'
} | nc -w 5 "$HOST" "$PORT"
