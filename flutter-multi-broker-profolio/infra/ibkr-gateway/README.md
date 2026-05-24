# IBKR Gateway sidecar

Self-built Docker image — IBKR's official IB Gateway driven headlessly
by [IBC](https://github.com/IbcAlpha/IBC). Avoids trusting a
pre-built third-party image with your live trading credentials.

## One-time setup

Two large files must be downloaded manually before building:

```bash
cd infra/ibkr-gateway
# IB Gateway (signed Linux installer from IBKR)
wget -O ibgateway.sh \
  https://download2.interactivebrokers.com/installers/ibgateway/stable-standalone/ibgateway-stable-standalone-linux-x64.sh
# IBC (community Java automation — open source, audit before you trust)
wget -O IBC.zip \
  https://github.com/IbcAlpha/IBC/releases/download/3.20.0/IBCLinux-3.20.0.zip
```

Both files are gitignored. ~335 MB total.

## Credentials (in `.env`)

```
IBKR_USERNAME=<your IB live username>
IBKR_PASSWORD=<your IB password>
IBKR_TRADING_MODE=live      # or "paper"
```

## Build + run

```bash
docker compose build ibkr-gateway
docker compose up ibkr-gateway -d
docker compose logs ibkr-gateway -f
```

First boot takes 30–60 s. IBC drives the login dialog automatically
using the env-templated `config.ini`. If 2FA is required, IBC sends
the standard push notification to your **IBKR Mobile** app — approve
the push and the gateway finishes coming up.

## Verify

From the backend container:

```bash
docker compose exec backend python -c "
from ib_insync import IB
ib = IB()
ib.connect('ibkr-gateway', 4001, clientId=999)
print('connected, accounts =', ib.managedAccounts())
ib.disconnect()
"
```

A list of account ids → live API session is working.

## Daily auth

IBKR forces a session reset around 03:00 New York time. Our `config.ini`
sets `AutoRestartTime=03:00 AM` so IBC handles it automatically — the
gateway restarts, logs back in, and (if 2FA-required) sends a fresh
push to your phone for approval.

If you ever change your IB password, update `.env` and
`docker compose restart ibkr-gateway`.
