# Django Local Library
"Local Library" website written in Django.
This web application is following the [MDN tutorial home page](https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Server-side/Django/Tutorial_local_library_website).

## Prerequisites
`Django==5.1.15` is not supported with Python 3.14.5, therefore I downgraded to Python 3.12.9.

## Docker Image

The Docker image is using the Docker Hardened Images for Python. The two variants being used are:
- Build-time variant `dhi.io/python:3.12-dev` has root access and has a shell and package manager.
  - The Python modules are installed in a venv and Django static files are created in this stage.
- Runtime variant `dhi.io/python:3.12` runs as the nonroot user and does not include a shell or a package manager.
  - The venv and the app code including static files are copied from the build stage, and ownership set to nonroot.

## Building the Docker image
```
docker build --target runtime -t django-locallibrary .
```

## `settings.py`

If the `POSTGRES_SERVER` environment variable is set, `settings.py` will attempt to connect to the Postgres database you defined in your environment.

If `POSTGRES_SERVER` is not set, it will default back to the local sqlite database.

# Docker Compose
## Prerequisites
### Postgres DB Password
Your desired Postgres DB password must be set inside `db/password.txt`. This file is used by Docker Compose as a secret, located at `/run/secrets/db-password`. This path is used by env `POSTGRES_PASSWORD_FILE`.

### `.env`
Create a `.env` file at the root of the repo, with the following variable and values:
| Variable            | Values          |
| ------------------- | --------------- |
| `DJANGO_DEBUG`      | `False`         |
| `DJANGO_SECRET_KEY` | `<Your_Secret>` |
| `POSTGRES_SERVER`   | `db`            |
| `POSTGRES_DB`       | `library`       |
| `POSTGRES_PORT`     | `5432`          |
| `POSTGRES_USER`     | `postgres`      |

## Run and shutdown application

`docker compose up` to pull the image from Docker Hub.
`docker compose up --build` to build the local Dockerfile
`docker compose down --volumes` to shutdown the app

Access the app at http://localhost:8000/catalog/.