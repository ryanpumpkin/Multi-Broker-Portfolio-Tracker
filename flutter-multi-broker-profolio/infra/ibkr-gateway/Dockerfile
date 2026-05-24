# IBKR Gateway sidecar — runs IB's official Java Gateway under IBC.
#
# Two manual downloads required at build time (gitignored):
#   infra/ibkr-gateway/ibgateway.sh  ← from https://www.interactivebrokers.com/en/index.php?f=16454
#                                       (Linux x64 64-bit IB Gateway installer)
#   infra/ibkr-gateway/IBC.zip       ← from https://github.com/IbcAlpha/IBC/releases/latest
#
# Why IBC: IB Gateway is a Swing GUI app. IBC drives the login dialog
# headlessly so we never need a real display. Source on GitHub —
# auditable.
#
# Credentials come from env vars at runtime:
#   IBKR_USERNAME, IBKR_PASSWORD, IBKR_TRADING_MODE=live|paper

FROM eclipse-temurin:17-jre-jammy

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    DISPLAY=:0 \
    IBC_DIR=/opt/ibc \
    TWS_INSTALL_DIR=/root/Jts \
    IBC_INI=/root/ibc/config.ini

# Runtime deps:
#   xvfb         — virtual framebuffer (IB Gateway needs a display)
#   x11-utils    — xdpyinfo for IBC display checks
#   libxext6/libxrender1/libxtst6/libxi6 — Swing X11 deps
#   xterm        — IB Gateway sometimes spawns an xterm
#   unzip        — extract IBC
#   socat        — TCP proxy (forward 0.0.0.0:4001 -> 127.0.0.1:4001 inside IB Gateway)
#   gettext-base — envsubst for templating config.ini
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        xvfb \
        x11-utils \
        libxext6 libxrender1 libxtst6 libxi6 \
        xterm \
        unzip \
        socat \
        gettext-base \
        ca-certificates \
        procps \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Install IB Gateway in unattended mode. The installer drops files
# directly under the -dir path (no version subdir), so we install to
# a temp location, parse the version out of "IB Gateway X.YZ.desktop",
# then move the install into /root/Jts/<version> which is what IBC's
# gatewaystart.sh expects.
COPY ibgateway.sh /tmp/ibgateway.sh
RUN chmod +x /tmp/ibgateway.sh \
 && /tmp/ibgateway.sh -q -dir /root/install \
 && VRSN=$(ls /root/install | sed -n 's/^IB Gateway \([0-9]*\)\.\([0-9]*\)\.desktop$/\1\2/p' | head -1) \
 && if [ -z "$VRSN" ]; then \
        echo "Could not parse IB Gateway version from install dir" >&2; \
        ls /root/install >&2; \
        exit 1; \
    fi \
 && mkdir -p /root/Jts \
 && mv /root/install "/root/Jts/${VRSN}" \
 && rm /tmp/ibgateway.sh \
 && echo "Installed IB Gateway version ${VRSN}" \
 && ls /root/Jts

# Install IBC.
COPY IBC.zip /tmp/IBC.zip
RUN mkdir -p /opt/ibc \
 && unzip -q /tmp/IBC.zip -d /opt/ibc \
 && find /opt/ibc -name '*.sh' -exec chmod +x {} + \
 && rm /tmp/IBC.zip \
 # gatewaystart.sh has `TWS_MAJOR_VRSN=1019` near the top which
 # clobbers any inherited env. Comment that line out so our
 # entrypoint's exported value takes effect.
 && sed -i 's|^TWS_MAJOR_VRSN=|# patched out: TWS_MAJOR_VRSN=|' /opt/ibc/gatewaystart.sh \
 && grep -n TWS_MAJOR_VRSN /opt/ibc/gatewaystart.sh | head -3

COPY config.ini.template /root/ibc/config.ini.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 4001 — live trading socket (paper uses 4002)
# Internally IB Gateway binds to 127.0.0.1 only; entrypoint.sh runs
# socat to expose it on 0.0.0.0 inside the container so other
# containers / docker network can reach it.
EXPOSE 4001 4002

ENTRYPOINT ["/entrypoint.sh"]
