FROM python:3.12.3-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir wheel \
    && pip install --no-cache-dir -r requirements.txt

COPY src /app

RUN useradd -m appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000
# Ensure no inherited HEALTHCHECK from a future base image breaks local compose.
HEALTHCHECK NONE
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
