from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .services import PERIOD_DAYS, build_user_statistics


class UserStatisticsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        period = request.query_params.get("period", "week")
        if period not in PERIOD_DAYS:
            period = "week"
        data = build_user_statistics(request.user, period)
        return Response(data)
