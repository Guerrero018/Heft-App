from django.core.management.base import BaseCommand

from apps.achievements.catalog import load_achievement_catalog


class Command(BaseCommand):
    help = "Carga o actualiza el catálogo de 75 logros en la base de datos."

    def handle(self, *args, **options):
        count = load_achievement_catalog()
        self.stdout.write(self.style.SUCCESS(f"Catálogo actualizado: {count} logros."))
