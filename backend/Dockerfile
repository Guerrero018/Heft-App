# Usar una imagen oficial de Python ligera
FROM python:3.12-slim

# Establecer variables de entorno
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Establacer el directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema necesarias para PostgreSQL y otras
RUN apt-get update && apt-get install -y \
    postgresql-client \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Instalar las dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código del proyecto
COPY . .

# Exponer el puerto que usará Django
EXPOSE 8000

# Comando por defecto para correr el servidor (usaremos gunicorn para producción pero esto es personalizable)
# Para desarrollo lo podemos sobreescribir con docker-compose
CMD ["gunicorn", "heft_core.wsgi:application", "--bind", "0.0.0.0:8000"]
