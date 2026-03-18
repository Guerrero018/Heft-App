.PHONY: build up up-build down restart logs logs-backend logs-db shell dbshell migrate makemigrations \
       createsuperuser collectstatic test flush clean rebuild ps \
       seed-exercises help bash psql pip-install check showmigrations

# --- Docker Compose ---
COMPOSE = docker-compose -f ../docker-compose.yml

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d

up-build:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

rebuild: down up-build

clean:
	$(COMPOSE) down -v --rmi local --remove-orphans

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

logs-backend:
	$(COMPOSE) logs -f backend

logs-db:
	$(COMPOSE) logs -f db

# --- Django (dentro del contenedor backend) ---

shell:
	$(COMPOSE) exec backend python manage.py shell

dbshell:
	$(COMPOSE) exec backend python manage.py dbshell

migrate:
	$(COMPOSE) exec backend python manage.py migrate

makemigrations:
	$(COMPOSE) exec backend python manage.py makemigrations

createsuperuser:
	$(COMPOSE) exec backend python manage.py createsuperuser

collectstatic:
	$(COMPOSE) exec backend python manage.py collectstatic --noinput

test:
	$(COMPOSE) exec backend python manage.py test

flush:
	$(COMPOSE) exec backend python manage.py flush --noinput

# --- Sembrado de datos (Heft) ---

seed-exercises:
	$(COMPOSE) exec backend python seed_exercises.py

# --- Utilidades ---

bash:
	$(COMPOSE) exec backend bash

psql:
	$(COMPOSE) exec db psql -U heft_user -d heft_db

pip-install:
	$(COMPOSE) exec backend pip install -r requirements.txt

check:
	$(COMPOSE) exec backend python manage.py check

showmigrations:
	$(COMPOSE) exec backend python manage.py showmigrations

help:
	@echo ""
	@echo "  Comandos disponibles para Heft:"
	@echo "  ─────────────────────────────────────────────"
	@echo "  make build            Construir imagenes"
	@echo "  make up               Levantar contenedores"
	@echo "  make up-build         Levantar y reconstruir"
	@echo "  make down             Parar contenedores"
	@echo "  make restart          Reiniciar contenedores"
	@echo "  make rebuild          Parar, reconstruir y levantar"
	@echo "  make clean            Parar y eliminar volumenes e imagenes"
	@echo "  make ps               Estado de los contenedores"
	@echo "  make logs             Ver logs (todos)"
	@echo "  make logs-backend     Ver logs del backend"
	@echo "  make logs-db          Ver logs de db"
	@echo "  ─────────────────────────────────────────────"
	@echo "  make shell            Shell de Django"
	@echo "  make dbshell          Shell de la base de datos"
	@echo "  make migrate          Ejecutar migraciones"
	@echo "  make makemigrations   Crear migraciones"
	@echo "  make createsuperuser  Crear superusuario"
	@echo "  make seed-exercises   Ejecutar sembrado de ejercicios"
	@echo "  make test             Ejecutar tests"
	@echo "  make flush            Vaciar base de datos"
	@echo "  make showmigrations   Mostrar estado de migraciones"
	@echo "  make check            Verificar configuracion de Django"
	@echo "  ─────────────────────────────────────────────"
	@echo "  make bash             Bash en contenedor backend"
	@echo "  make psql             Conectar a PostgreSQL"
	@echo "  make pip-install      Instalar dependencias"
	@echo "  make help             Mostrar esta ayuda"
	@echo ""
