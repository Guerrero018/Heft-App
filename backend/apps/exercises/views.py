from rest_framework import viewsets, permissions
from django.db import models
from .models import Exercise
from .serializers import ExerciseSerializer

class ExerciseViewSet(viewsets.ModelViewSet):
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # A user can see global exercises AND their own custom exercises
        user = self.request.user
        return Exercise.objects.filter(models.Q(is_global=True) | models.Q(user=user))
