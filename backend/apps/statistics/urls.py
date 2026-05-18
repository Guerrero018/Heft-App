from django.urls import path

from .views import UserStatisticsView

urlpatterns = [
    path("statistics/", UserStatisticsView.as_view(), name="user-statistics"),
]
