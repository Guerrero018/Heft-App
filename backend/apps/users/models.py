from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    height = models.FloatField(null=True, blank=True, help_text="Height in cm")
    units_preference = models.CharField(
        max_length=10,
        choices=[('kg', 'Kilograms'), ('lbs', 'Pounds')],
        default='kg'
    )
    birth_date = models.DateField(null=True, blank=True)

    def __str__(self):
        return self.username

class BodyMeasures(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="body_measures")
    weight = models.FloatField()
    date = models.DateField()
    notes = models.TextField(blank=True)
    photo = models.ImageField(upload_to="body_measures", blank=True, null=True)