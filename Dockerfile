# ─── Build stage ──────────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# System deps: ffmpeg + build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies to an isolated prefix (CPU-only version for smaller size)
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cpu

# ─── Final image ──────────────────────────────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Copy system libraries needed at runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY . .

# Create a non-root user and ensure the data directory exists
RUN useradd -m deepshield && \
    mkdir -p /app/data && \
    chown -R deepshield:deepshield /app
USER deepshield

ENV DB_PATH=/app/data/deepshield.db

EXPOSE ${PORT:-8000}

CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1
