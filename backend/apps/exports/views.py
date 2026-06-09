from django.http import HttpResponse
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.routines.models import Routine

from .collectors import build_preview, collect_export_data
from .csv_builder import build_csv_export
from .pdf_builder import build_pdf_export
from .serializers import ExportRequestSerializer


def _validate_ownership(user, filters) -> None:
    if filters.routine_id and not Routine.objects.filter(
        id=filters.routine_id,
        user=user,
    ).exists():
        raise ValidationError({'routine_id': 'Rutina no encontrada.'})


class ExportPreviewView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ExportRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        filters = serializer.to_filters()
        _validate_ownership(request.user, filters)
        preview = build_preview(request.user, filters)
        return Response(preview.to_dict())


class ExportDownloadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ExportRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        filters = serializer.to_filters()
        _validate_ownership(request.user, filters)

        data = collect_export_data(request.user, filters)
        export_format = serializer.validated_data['format']

        if export_format == ExportRequestSerializer.FORMAT_PDF:
            data['include_workouts_flag'] = filters.include_workouts
            content, filename = build_pdf_export(data)
            content_type = 'application/pdf'
        else:
            content, filename = build_csv_export(data)
            content_type = (
                'application/zip'
                if filename.endswith('.zip')
                else 'text/csv; charset=utf-8'
            )

        response = HttpResponse(content, content_type=content_type)
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        return response
