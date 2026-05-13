#!/bin/bash
set -e

# Mantener el arranque ligero evita que Render marque la instancia
# como no saludable durante un cold start o un reinicio.
if [ "${RUN_MIGRATIONS_ON_START:-0}" = "1" ]; then
  echo "Running database migrations on startup..."
  python manage.py migrate --noinput
fi

if [ "${RUN_COLLECTSTATIC_ON_START:-0}" = "1" ]; then
  echo "Collecting static files on startup..."
  python manage.py collectstatic --noinput
fi

exec gunicorn heft_core.wsgi:application --bind 0.0.0.0:8000
