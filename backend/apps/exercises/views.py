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
        Devuelve una lista curada de los ejercicios más populares/efectivos.
        """
        search_terms = [
            # BÁSICOS PESADOS
            'Press de banca con barra', 'Sentadilla', 'Peso muerto', 'Dominada', 
            'Press militar', 'Remo con barra', 'Fondos', 'Prensa de piernas',
            # PECHO
            'Press inclinado', 'Aperturas', 'Crossover', 'Peck deck', 'Cruces de polea',
            # ESPALDA
            'Jalón al pecho', 'Remo en polea baja', 'Remo Gironda', 'Remo con mancuerna',
            'Remo en punta', 'Pullover', 'Extensiones lumbares',
            # HOMBRO
            'Press Arnold', 'Face pull', 'Pájaros', 'Elevación lateral', 'Elevación frontal',
            # PIERNA Y GLÚTEO
            'Extensiones de cuádriceps', 'Curl femoral', 'Peso muerto rumano', 'Zancadas',
            'Hip thrust', 'Prensa hack', 'Sentadilla búlgara', 'Abducción', 'Aducción',
            'Gemelo', 'Pantorrilla', 'Patada de glúteo',
            # BRAZOS
            'Curl de bíceps', 'Martillo', 'Curl predicador', 'Banco Scott', 'Barra Z',
            'Extensiones de tríceps', 'Press francés', 'Patada de tríceps', 'Tríceps tras nuca',
            # CORE
            'Crunch', 'Bicicleta', 'Plancha', 'Plank', 'Elevación de piernas', 'Rueda abdominal'
        ]
        
        popular_exercises = []
        seen_ids = set()
        
        # Buscamos coincidencias para cada término
        for term in search_terms:
            exercise = Exercise.objects.filter(
                models.Q(name__icontains=term),
                is_global=True
            ).first()
            
            if exercise and exercise.id not in seen_ids:
                popular_exercises.append(exercise)
                seen_ids.add(exercise.id)
        
        # Fallback si por algún motivo la lista es muy corta
        if len(popular_exercises) < 20:
            additional = Exercise.objects.filter(is_global=True).exclude(id__in=seen_ids)[:20]
            popular_exercises.extend(additional)

        serializer = self.get_serializer(popular_exercises[:100], many=True)
        return Response(serializer.data)
