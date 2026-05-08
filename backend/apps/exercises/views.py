from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import models
from .models import Exercise
from .serializers import ExerciseSerializer

class ExerciseViewSet(viewsets.ModelViewSet):
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Exercise.objects.filter(models.Q(is_global=True) | models.Q(user=user))

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated], pagination_class=None)
    def popular(self, request):
        """
        Devuelve el catálogo de populares utilizando NOMBRES LITERALES Y EXACTOS extraídos de la BD.
        Garantiza que siempre aparezcan ejercicios de todos los grupos musculares.
        """
        exact_famous_exercises = [
            # PECHO
            'Press de banca con barra',
            'Press inclinado con mancuernas',
            'Press declinado en polea',
            'Aperturas en polea baja',
            'Cruces de poleas de pie (recto)',
            'Flexiones profundas',
            'Fondos de pecho',
            
            # ESPALDA
            'Dominada',
            'Dominada con agarre ancho',
            'Remo con barra inclinado',
            'Remo sentado en polea',
            'Remo a una mano con cable inclinado',
            'Pullover con barra',
            'Remo en barra t en máquina de palanca',
            'Jalón inclinado en polea con brazos rectos',
            
            # CUÁDRICEPS Y GLÚTEO
            'Sentadilla frontal con barra en banco',
            'Sentadilla goblet con mancuerna',
            'Prensa de piernas en trineo a 45°',
            'Sentadilla hack en trineo',
            'Zancadas caminando',
            'Patada trasera con cable',
            'Deslizamiento en plataforma a una pierna',
            
            # ISQUIOTIBIALES (FEMORAL)
            'Peso muerto con barra',
            'Peso muerto rumano con barra',
            'Curl de piernas sentado en máquina de palanca',
            'Curl de piernas tumbado en máquina de palanca',
            'Femoral tumbado con mancuerna',
            'Buenos días con barra',
            
            # HOMBROS
            'Press militar con barra sentado tras nuca',
            'Press de hombros sentado con mancuerna',
            'Elevaciones laterales posteriores con mancuernas',
            'Elevación de hombros con barra en banco inclinado',
            'Remo invertido',
            
            # BRAZOS (BÍCEPS Y TRÍCEPS)
            'Curl con barra ez',
            'Curl con barra agarre cerrado de pie',
            'Curl martillo prono a una mano',
            'Curl predicador con barra',
            'Curl concentrado con banda',
            'Extensión de tríceps',
            'Fondos de pecho asistidos (de rodillas)',
            
            # CORE Y GEMELOS
            'Crunch con peso',
            'Plancha frontal con giro',
            'Despliegue de rueda abdominal de pie',
            'Prensa de gemelos en trineo a 45°',
            'Elevación de talones de pie con mancuernas'
        ]
        
        # Obtenemos TODOS los ejercicios que coincidan exactamente con nuestra lista maestra
        popular_exercises = list(Exercise.objects.filter(
            name__in=exact_famous_exercises,
            is_global=True
        ))
        
        # Por si el usuario ha borrado alguno, rellenamos hasta llegar a 40 con ejercicios globales variados
        if len(popular_exercises) < 40:
            seen_ids = [e.id for e in popular_exercises]
            additional = Exercise.objects.filter(is_global=True).exclude(id__in=seen_ids)[:(40 - len(popular_exercises))]
            popular_exercises.extend(additional)

        serializer = self.get_serializer(popular_exercises, many=True)
        return Response(serializer.data)
