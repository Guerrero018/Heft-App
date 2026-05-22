import uuid


def profile_picture_path(instance, filename):
    ext = (filename.rsplit(".", 1)[-1] if "." in filename else "jpg").lower()
    user_id = instance.pk or "tmp"
    return f"user_{user_id}/avatar_{uuid.uuid4().hex[:12]}.{ext}"


def body_measure_photo_path(instance, filename):
    ext = (filename.rsplit(".", 1)[-1] if "." in filename else "jpg").lower()
    measure = instance.body_measure
    return (
        f"user_{measure.user_id}/{measure.date}_"
        f"m{measure.id}_{uuid.uuid4().hex[:10]}.{ext}"
    )
