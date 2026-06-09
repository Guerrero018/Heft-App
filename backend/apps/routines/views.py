from rest_framework import viewsets, permissions
from .models import Routine
from .serializers import RoutineSerializer

class RoutineViewSet(viewsets.ModelViewSet):
    serializer_class = RoutineSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = Routine.objects.filter(user=self.request.user).prefetch_related(
            "exercises__exercise"
        )
        is_active = self.request.query_params.get("is_active")
        if is_active is not None:
            qs = qs.filter(is_active=is_active.lower() in ("true", "1"))
        return qs
