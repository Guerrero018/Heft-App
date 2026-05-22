from .models import BodyMeasurePhoto

MAX_BODY_MEASURE_PHOTOS = BodyMeasurePhoto.MAX_PER_ENTRY


def photo_urls_for_measure(measure, request=None):
    from .media_utils import resolve_media_url

    urls = []
    for photo in measure.measure_photos.all():
        url = resolve_media_url(photo.image, request, legacy_kind="body")
        if url:
            urls.append(url)
    return urls


def incoming_photo_files(request):
    if request is None:
        return []
    files = list(request.FILES.getlist("photos"))
    legacy = request.FILES.get("photo")
    if legacy and legacy not in files:
        files.insert(0, legacy)
    return files
