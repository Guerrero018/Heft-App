"""Firebase Admin SDK initialisation and send helpers.

The SDK is initialised lazily on first use so that the app boots normally even
in environments where FIREBASE_CREDENTIALS_JSON is not set (e.g. CI, tests).
"""

import json
import logging
import os

logger = logging.getLogger(__name__)

_app = None


def _get_app():
    """Return the initialised Firebase app, creating it once if needed."""
    global _app
    if _app is not None:
        return _app

    try:
        import firebase_admin
        from firebase_admin import credentials

        creds_json = os.getenv("FIREBASE_CREDENTIALS_JSON", "")
        if not creds_json:
            logger.warning(
                "FIREBASE_CREDENTIALS_JSON not set — push notifications disabled."
            )
            return None

        cred_dict = json.loads(creds_json)
        cred = credentials.Certificate(cred_dict)
        _app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialised.")
        return _app
    except Exception as exc:
        logger.error("Failed to initialise Firebase Admin SDK: %s", exc)
        return None


def send_push(*, token: str, title: str, body: str, data: dict | None = None) -> bool:
    """Send a single FCM push notification.

    Returns True on success, False on any failure.
    """
    app = _get_app()
    if app is None:
        return False

    try:
        from firebase_admin import messaging

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            token=token,
        )
        messaging.send(message, app=app)
        return True
    except Exception as exc:
        logger.error("FCM send failed for token %s…: %s", token[:20], exc)
        return False


def send_push_multicast(
    *, tokens: list[str], title: str, body: str, data: dict | None = None
) -> tuple[int, int]:
    """Send to multiple tokens via MulticastMessage.

    Returns (success_count, failure_count).
    """
    if not tokens:
        return 0, 0

    app = _get_app()
    if app is None:
        return 0, len(tokens)

    try:
        from firebase_admin import messaging

        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            tokens=tokens,
        )
        response = messaging.send_each_for_multicast(message, app=app)
        return response.success_count, response.failure_count
    except Exception as exc:
        logger.error("FCM multicast failed: %s", exc)
        return 0, len(tokens)
