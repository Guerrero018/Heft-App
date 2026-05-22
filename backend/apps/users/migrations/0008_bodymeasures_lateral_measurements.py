from django.db import migrations, models


def copy_legacy_lateral_fields(apps, schema_editor):
    BodyMeasures = apps.get_model("users", "BodyMeasures")
    for entry in BodyMeasures.objects.all():
        updated = []
        if entry.bicep_cm is not None:
            if entry.bicep_left_cm is None:
                entry.bicep_left_cm = entry.bicep_cm
                updated.append("bicep_left_cm")
            if entry.bicep_right_cm is None:
                entry.bicep_right_cm = entry.bicep_cm
                updated.append("bicep_right_cm")
        if entry.thigh_cm is not None:
            if entry.thigh_left_cm is None:
                entry.thigh_left_cm = entry.thigh_cm
                updated.append("thigh_left_cm")
            if entry.thigh_right_cm is None:
                entry.thigh_right_cm = entry.thigh_cm
                updated.append("thigh_right_cm")
        if updated:
            entry.save(update_fields=updated)


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0007_bodymeasures_measurements"),
    ]

    operations = [
        migrations.AddField(
            model_name="bodymeasures",
            name="shoulders_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="bodymeasures",
            name="bicep_left_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="bodymeasures",
            name="bicep_right_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="bodymeasures",
            name="thigh_left_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="bodymeasures",
            name="thigh_right_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.RunPython(copy_legacy_lateral_fields, migrations.RunPython.noop),
        migrations.RemoveField(
            model_name="bodymeasures",
            name="bicep_cm",
        ),
        migrations.RemoveField(
            model_name="bodymeasures",
            name="thigh_cm",
        ),
    ]
