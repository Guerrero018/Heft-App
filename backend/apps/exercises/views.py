from django.db.models import Count, Q
from rest_framework import viewsets, permissions, filters
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

from .models import Exercise
from .serializers import ExerciseSerializer


class ExercisePagination(PageNumberPagination):
    page_size = 40
    page_size_query_param = 'page_size'
    max_page_size = 100


class ExerciseViewSet(viewsets.ModelViewSet):
    """
    API endpoint for exercises.
    Supports server-side search, muscle_group, and exercise_type filters with pagination.
    """
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = ExercisePagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'muscle_group', 'exercise_type']
    ordering_fields = ['name', 'muscle_group', 'exercise_type']
    ordering = ['name']

    def get_queryset(self):
        user = self.request.user
        queryset = Exercise.objects.filter(
            Q(user__isnull=True) | Q(user=user)
        )

        muscle_group = self.request.query_params.get('muscle_group')
        if muscle_group:
            queryset = queryset.filter(muscle_group__iexact=muscle_group)

        exercise_type = self.request.query_params.get('exercise_type')
        if exercise_type:
            queryset = queryset.filter(exercise_type__iexact=exercise_type)

        return queryset

    @action(detail=False, methods=['get'], pagination_class=None)
    def popular(self, request):
        """
        Returns exercises ranked by how often they appear in the user's completed sets.
        Falls back to global catalog exercises when the user has no history.
        """
        user = request.user
        limit = min(int(request.query_params.get('limit', 10)), 30)

        usage_qs = (
            Exercise.objects.filter(
                Q(user__isnull=True) | Q(user=user),
                sets__workout_session__user=user,
            )
            .annotate(usage_count=Count('sets', distinct=True))
            .filter(usage_count__gt=0)
            .order_by('-usage_count', 'name')[:limit]
        )

        if usage_qs.exists():
            serializer = self.get_serializer(usage_qs, many=True)
            return Response(serializer.data)

        fallback = self.get_queryset().order_by('name')[:limit]
        serializer = self.get_serializer(fallback, many=True)
        return Response(serializer.data)
