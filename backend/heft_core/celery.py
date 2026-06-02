"""Celery application for Heft backend.

Workers: celery -A heft_core worker -l info
Beat:    celery -A heft_core beat   -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
"""

import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "heft_core.settings")

app = Celery("heft_core")

# Load config from Django settings, namespace CELERY_*
app.config_from_object("django.conf:settings", namespace="CELERY")

# Auto-discover tasks in all installed apps
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f"Request: {self.request!r}")
