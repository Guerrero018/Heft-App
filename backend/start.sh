#!/bin/bash

# 1. Ejecutar las migraciones (crear tablas en Neon)
python manage.py migrate --noinput

# 2. Recolectar archivos estáticos (para el Admin de Django)
python manage.py collectstatic --noinput

# 3. (Opcional) Sembrar ejercicios si la base está vacía
# python seed_exercises.py

# 4. Iniciar Gunicorn
gunicorn heft_core.wsgi:application --bind 0.0.0.0:8000
