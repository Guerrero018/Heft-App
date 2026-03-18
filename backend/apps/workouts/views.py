from rest_framework import viewsets, permissions
from .models import WorkoutSession
from .serializers import WorkoutSessionSerializer

class WorkoutSessionViewSet(viewsets.ModelViewSet):
    serializer_class = WorkoutSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Users can only see their own workouts
        return WorkoutSession.objects.filter(user=self.request.user)
