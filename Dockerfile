# syntax=docker/dockerfile:1

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

RUN python3 manage.py migrate && python3 manage.py collectstatic --no-input

# FROM dhi.io/python:3.12 AS runtime
# WORKDIR /app
# COPY --from=builder /venv /venv
# COPY --from=builder /app /app
# ENV PATH="/venv/bin:$PATH"
# RUN useradd -m appuser
# USER appuser

# Expose the port that the application listens on.
EXPOSE 8000

# Run the application
CMD ["gunicorn", "locallibrary.wsgi:application", "--bind", "0.0.0.0:8000"]
