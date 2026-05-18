from rest_framework import viewsets, permissions, filters
from .models import WorkoutSession
from .serializers import WorkoutSessionSerializer

class WorkoutSessionViewSet(viewsets.ModelViewSet):
    serializer_class = WorkoutSessionSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['start_time', 'date']
    ordering = ['-start_time'] # Orden por defecto: más reciente primero

    def get_queryset(self):
        return (
            WorkoutSession.objects.filter(user=self.request.user)
            .prefetch_related("sets", "sets__exercise", "routine")
        )
