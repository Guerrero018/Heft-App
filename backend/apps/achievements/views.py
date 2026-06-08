from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import UserAchievementSerializer
from .services import build_achievements_read_payload, build_achievements_sync_payload


class UserAchievementsView(APIView):
    """
    GET: lectura rápida desde UserAchievement (sync solo en primer acceso).
    POST: re-evalúa todos los logros y devuelve los recién desbloqueados.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(self._serialize_payload(request, sync=False))

    def post(self, request):
        return Response(self._serialize_payload(request, sync=True))

    def _serialize_payload(self, request, *, sync: bool) -> dict:
        payload = (
            build_achievements_sync_payload(request.user)
            if sync
            else build_achievements_read_payload(request.user)
        )
        serializer = UserAchievementSerializer(
            payload["achievements"],
            many=True,
            context={"request": request},
        )
        return {
            "unlocked_count": payload["unlocked_count"],
            "total_count": payload["total_count"],
            "newly_unlocked": payload["newly_unlocked"],
            "achievements": serializer.data,
        }
