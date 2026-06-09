from django.urls import path

from .views import ExportDownloadView, ExportPreviewView

urlpatterns = [
    path('exports/preview/', ExportPreviewView.as_view(), name='export_preview'),
    path('exports/download/', ExportDownloadView.as_view(), name='export_download'),
]
