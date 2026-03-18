from rest_framework import viewsets, permissions
from .models import Routine
from .serializers import RoutineSerializer

class RoutineViewSet(viewsets.ModelViewSet):
    serializer_class = RoutineSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Users should only see their own routines
        return Routine.objects.filter(user=self.request.user)
