from django.db.models import Count, Q
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Routine
from .serializers import (
    PublicRoutineListSerializer,
    PublicRoutineSerializer,
    RoutineSerializer,
)
from .services import (
    clone_routine_for_user,
    ensure_share_code,
    publish_routine,
    unpublish_routine,
)


class RoutineViewSet(viewsets.ModelViewSet):
    serializer_class = RoutineSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = Routine.objects.filter(user=self.request.user).prefetch_related(
            'exercises__exercise',
        )
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            qs = qs.filter(is_active=is_active.lower() in ('true', '1'))
        return qs

    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        routine = self.get_object()
        try:
            publish_routine(routine)
        except ValueError as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(RoutineSerializer(routine, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def unpublish(self, request, pk=None):
        routine = self.get_object()
        if routine.is_official:
            return Response(
                {'detail': 'Las plantillas oficiales no se pueden despublicar.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        unpublish_routine(routine)
        return Response(RoutineSerializer(routine, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def share(self, request, pk=None):
        routine = self.get_object()
        code = ensure_share_code(routine)
        return Response({'share_code': code})

    @action(
        detail=False,
        methods=['get'],
        url_path=r'shared/(?P<share_code>[^/.]+)',
    )
    def shared_preview(self, request, share_code=None):
        routine = (
            Routine.objects.filter(share_code__iexact=share_code)
            .select_related('user')
            .prefetch_related('exercises__exercise')
            .first()
        )
        if routine is None:
            return Response({'detail': 'Código no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        if routine.user_id == request.user.id:
            return Response(
                {'detail': 'Esta rutina ya es tuya.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(PublicRoutineSerializer(routine).data)

    @action(
        detail=False,
        methods=['post'],
        url_path=r'shared/(?P<share_code>[^/.]+)/import',
    )
    def shared_import(self, request, share_code=None):
        routine = (
            Routine.objects.filter(share_code__iexact=share_code)
            .prefetch_related('exercises__exercise')
            .first()
        )
        if routine is None:
            return Response({'detail': 'Código no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        if routine.user_id == request.user.id:
            return Response(
                {'detail': 'Esta rutina ya es tuya.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        imported = clone_routine_for_user(routine, request.user)
        return Response(
            RoutineSerializer(imported, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )


class RoutineTemplateViewSet(viewsets.ReadOnlyModelViewSet):
    """Biblioteca pública de plantillas (oficiales + publicadas por usuarios)."""

    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'pk'

    def get_serializer_class(self):
        if self.action == 'list':
            return PublicRoutineListSerializer
        return PublicRoutineSerializer

    def get_queryset(self):
        qs = (
            Routine.objects.filter(Q(is_public=True) | Q(is_official=True))
            .select_related('user')
            .annotate(_exercise_count=Count('exercises'))
            .prefetch_related('exercises__exercise')
            .order_by('-is_official', '-times_imported', '-published_at')
        )

        search = self.request.query_params.get('search', '').strip()
        if search:
            qs = qs.filter(Q(name__icontains=search) | Q(description__icontains=search))

        official_only = self.request.query_params.get('official')
        if official_only is not None and official_only.lower() in ('true', '1'):
            qs = qs.filter(is_official=True)

        return qs

    @action(detail=True, methods=['post'])
    def import_template(self, request, pk=None):
        source = self.get_object()
        if source.user_id == request.user.id:
            return Response(
                {'detail': 'Esta rutina ya es tuya.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        imported = clone_routine_for_user(source, request.user)
        return Response(
            RoutineSerializer(imported, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )
