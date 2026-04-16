from django.db import migrations, models

class Migration(migrations.Migration):

    dependencies = [
        ('users', '0002_user_equipment_user_experience_level_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='user',
            name='email',
            field=models.EmailField(max_length=254, unique=True),
        ),
    ]
