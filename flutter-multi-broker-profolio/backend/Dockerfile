# ─────────────────────────────────────────────────────────────────────────────
# Stage 1 — dependency builder
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Install build tooling
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy only the files needed to resolve/install dependencies first so Docker
# can cache this layer independently of application-code changes.
COPY pyproject.toml ./

# Create a minimal package structure so pip -e . / setuptools can discover the
# project without copying the full source tree into this stage.
RUN mkdir -p app && touch app/__init__.py

# Install runtime dependencies into an isolated prefix.
RUN pip install --no-cache-dir --prefix=/install ".[" 2>/dev/null || \
    pip install --no-cache-dir --prefix=/install .

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2 — runtime image
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

# ── Non-root user ────────────────────────────────────────────────────────────
RUN groupadd --gid 1001 mbp && \
    useradd --uid 1001 --gid mbp --no-create-home --shell /usr/sbin/nologin mbp

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application source
COPY --chown=mbp:mbp app/ ./app/
COPY --chown=mbp:mbp pyproject.toml ./

# Install the package itself in non-editable mode so Python picks up the
# entry-points and the `app` package is importable without /app on PYTHONPATH.
RUN pip install --no-cache-dir --no-deps .

USER mbp

EXPOSE 8000

# ── Health check ─────────────────────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python - <<'EOF'
import urllib.request, sys
try:
    urllib.request.urlopen("http://localhost:8000/healthz", timeout=4)
    sys.exit(0)
except Exception:
    sys.exit(1)
EOF

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
