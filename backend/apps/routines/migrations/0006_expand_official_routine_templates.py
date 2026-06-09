from django.db import migrations


def forwards(apps, schema_editor):
    from apps.routines.official_templates import seed_official_templates

    seed_official_templates(apps, rename_legacy=True)


class Migration(migrations.Migration):
    atomic = False

    dependencies = [
        ('routines', '0005_seed_official_routine_templates'),
    ]

    operations = [
        migrations.RunPython(forwards, migrations.RunPython.noop),
    ]
