from django.db import migrations


def load_catalog(apps, schema_editor):
    from apps.achievements.catalog import load_achievement_catalog

    load_achievement_catalog()


def unload_catalog(apps, schema_editor):
    Achievement = apps.get_model("achievements", "Achievement")
    Achievement.objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [
        ("achievements", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(load_catalog, unload_catalog),
    ]
