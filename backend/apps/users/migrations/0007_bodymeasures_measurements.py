from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0006_passwordresetcode"),
    ]

    operations = [
        migrations.AddField(
            model_name="bodymeasures",
            name="neck_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="bodymeasures",
            name="chest_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="bodymeasures",
            name="waist_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="bodymeasures",
            name="hips_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="bodymeasures",
            name="bicep_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="bodymeasures",
            name="thigh_cm",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AlterModelOptions(
            name="bodymeasures",
            options={"ordering": ["-date", "-id"]},
        ),
        migrations.AddIndex(
            model_name="bodymeasures",
            index=models.Index(fields=["user", "-date"], name="users_bodym_user_id_8a0f0d_idx"),
        ),
    ]
