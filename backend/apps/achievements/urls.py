from django.urls import path

from .views import UserAchievementsView

urlpatterns = [
    path("achievements/", UserAchievementsView.as_view(), name="user-achievements"),
]
