from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.exercises.models import Exercise
from apps.routines.models import Routine
from apps.users.models import BodyMeasures, User
from apps.workouts.models import WorkoutSession

from .services import sync_user_achievements


@receiver(post_save, sender=WorkoutSession)
def sync_achievements_on_workout(sender, instance, **kwargs):
    if instance.is_completed and instance.user_id:
        sync_user_achievements(instance.user)


@receiver(post_save, sender=BodyMeasures)
def sync_achievements_on_body_measure(sender, instance, **kwargs):
    if instance.user_id:
        sync_user_achievements(instance.user)


@receiver(post_save, sender=Routine)
def sync_achievements_on_routine(sender, instance, **kwargs):
    if instance.user_id:
        sync_user_achievements(instance.user)


@receiver(post_save, sender=Exercise)
def sync_achievements_on_custom_exercise(sender, instance, **kwargs):
    if not instance.is_global and instance.user_id:
        sync_user_achievements(instance.user)


@receiver(post_save, sender=User)
def sync_achievements_on_user_profile(sender, instance, created, **kwargs):
    if kwargs.get("raw"):
        return
    if created:
        sync_user_achievements(instance)
        return
    update_fields = kwargs.get("update_fields")
    if update_fields is None:
        return
    relevant = {"is_onboarded", "profile_picture"}
    if relevant.intersection(set(update_fields)):
        sync_user_achievements(instance)
