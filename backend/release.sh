#!/bin/bash
set -e

# Ejecuta estas tareas durante el despliegue o manualmente,
# no en cada arranque normal del contenedor.
python manage.py migrate --noinput
python manage.py collectstatic --noinput
