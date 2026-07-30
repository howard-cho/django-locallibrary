# syntax=docker/dockerfile:1

# Create builder image
FROM dhi.io/python:3.12-dev AS builder

WORKDIR /app

RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy source code into the container.
COPY . .

RUN python3 manage.py collectstatic --no-input

# Create runtime image
FROM dhi.io/python:3.12 AS runtime
USER 1001:1001
ENV HOME=/app
WORKDIR /app
COPY --from=builder --chown=1001:1001 /venv /venv
COPY --from=builder --chown=1001:1001 /app /app
ENV PATH="/venv/bin:$PATH"

# Expose the port that the application listens on.
EXPOSE 8000

# Run the application
# --no-control-socket since we are not using gunicornc admin tool
CMD ["gunicorn", "locallibrary.wsgi:application", "--bind", "0.0.0.0:8000", "--no-control-socket"]
