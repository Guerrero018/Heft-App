from django.apps import AppConfig


class AchievementsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.achievements"
    verbose_name = "Logros"

    def ready(self):
        from . import signals  # noqa: F401
