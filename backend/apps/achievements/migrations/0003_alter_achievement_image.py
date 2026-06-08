import apps.achievements.storage
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("achievements", "0002_load_achievement_catalog"),
    ]

    operations = [
        migrations.AlterField(
            model_name="achievement",
            name="image",
            field=models.ImageField(
                blank=True,
                help_text="Ilustración en Supabase Storage (o media local en desarrollo).",
                null=True,
                storage=apps.achievements.storage.select_achievement_storage(),
                upload_to=apps.achievements.storage.achievement_image_upload_to,
            ),
        ),
    ]
