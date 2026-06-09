from django.core.management.base import BaseCommand

from apps.routines.official_templates import seed_official_templates


class Command(BaseCommand):
    help = 'Crea o actualiza las plantillas oficiales de rutina en la biblioteca pública.'

    def handle(self, *args, **options):
        from django.apps import apps

        created = seed_official_templates(apps, rename_legacy=True)
        self.stdout.write(
            self.style.SUCCESS(f'Plantillas nuevas creadas: {created}'),
        )
