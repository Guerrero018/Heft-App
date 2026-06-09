# Generated manually for routine templates feature

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('routines', '0003_routineexercise_rest_time_seconds'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='routine',
            name='is_public',
            field=models.BooleanField(
                default=False,
                help_text='Visible en la biblioteca pública de plantillas.',
            ),
        ),
        migrations.AddField(
            model_name='routine',
            name='is_official',
            field=models.BooleanField(
                default=False,
                help_text='Plantilla curada por Heft (staff).',
            ),
        ),
        migrations.AddField(
            model_name='routine',
            name='source_routine',
            field=models.ForeignKey(
                blank=True,
                help_text='Rutina de la que se importó esta copia.',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='forks',
                to='routines.routine',
            ),
        ),
        migrations.AddField(
            model_name='routine',
            name='share_code',
            field=models.CharField(
                blank=True,
                db_index=True,
                help_text='Código para compartir entre usuarios.',
                max_length=12,
                null=True,
                unique=True,
            ),
        ),
        migrations.AddField(
            model_name='routine',
            name='published_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='routine',
            name='times_imported',
            field=models.PositiveIntegerField(default=0),
        ),
        migrations.AddIndex(
            model_name='routine',
            index=models.Index(
                fields=['is_public', '-published_at'],
                name='routines_ro_is_publ_0a8f2d_idx',
            ),
        ),
        migrations.AddIndex(
            model_name='routine',
            index=models.Index(
                fields=['is_official', '-times_imported'],
                name='routines_ro_is_offi_7c4e91_idx',
            ),
        ),
    ]
