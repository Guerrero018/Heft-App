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
        Devuelve una lista masiva y curada de los ejercicios más populares y efectivos.
        """
        search_terms = [
            # BÁSICOS DE POTENCIA (THE BIG THREE & FRIENDS)
            'Press de banca con barra', 'Sentadilla con barra', 'Peso muerto convencional', 
            'Dominadas', 'Press militar con barra', 'Remo con barra', 'Fondos en paralelas', 
            'Prensa de piernas', 'Peso muerto rumano',
            
            # PECHO (CHEST)
            'Press inclinado con barra', 'Press inclinado con mancuernas', 'Press de banca con mancuernas',
            'Aperturas con mancuernas', 'Crossover en poleas', 'Peck deck', 'Cruces de polea alta',
            'Press declinado', 'Flexiones', 'Push-ups',
            
            # ESPALDA (BACK)
            'Jalón al pecho', 'Jalón al pecho agarre estrecho', 'Remo en polea baja', 
            'Remo Gironda', 'Remo con mancuerna a una mano', 'Remo en punta', 'Remo en T',
            'Pullover con mancuerna', 'Pullover en polea alta', 'Extensiones lumbares', 
            'Dominadas supinas', 'Chin-ups',
            
            # HOMBRO (SHOULDERS)
            'Press de hombros con mancuernas', 'Press Arnold', 'Elevaciones laterales', 
            'Elevaciones laterales en polea', 'Face pull', 'Pájaros con mancuernas', 
            'Elevación frontal con mancuerna', 'Remo al mentón', 'Encogimientos de hombros',
            
            # PIERNA Y GLÚTEO (LEGS & GLUTES)
            'Extensiones de cuádriceps', 'Curl femoral sentado', 'Curl femoral tumbado', 
            'Zancadas con mancuernas', 'Lunges', 'Sentadilla búlgara', 'Hip thrust', 
            'Prensa hack', 'Sentadilla Goblet', 'Abducción de cadera en máquina', 
            'Aducción de cadera', 'Gemelo de pie', 'Prensa de gemelos', 'Patada de glúteo en polea',
            'Sentadilla sumo', 'Step-up',
            
            # BÍCEPS (BICEPS)
            'Curl de bíceps con barra', 'Curl de bíceps con mancuernas', 'Curl martillo', 
            'Curl predicador', 'Banco Scott', 'Curl con barra Z', 'Curl concentrado',
            'Curl de bíceps en polea', 'Curl araña',
            
            # TRÍCEPS (TRICEPS)
            'Extensiones de tríceps en polea', 'Press francés', 'Patada de tríceps', 
            'Tríceps tras nuca', 'Press cerrado para tríceps', 'Fondos entre bancos', 
            'Extensiones con cuerda',
            
            # CORE & ABDOMINALES
            'Crunch abdominal', 'Bicicleta abdominal', 'Plancha frontal', 'Plank', 
            'Elevación de piernas colgado', 'Rueda abdominal', 'Ab-wheel', 'Russian twist'
        ]
        
        popular_exercises = []
        seen_ids = set()
        
        # Estrategia de búsqueda mejorada: Buscamos coincidencias para cada término
        for term in search_terms:
            # Buscamos por nombre completo o parcial que sea global
            matches = Exercise.objects.filter(
                models.Q(name__icontains=term),
                is_global=True
            )[:1] # Tomamos solo el mejor match por término para diversidad
            
            for ex in matches:
                if ex.id not in seen_ids:
                    popular_exercises.append(ex)
                    seen_ids.add(ex.id)
        
        # Si aún queremos más variedad, rellenamos con los más usados (si tuvieras contador)
        # Por ahora rellenamos con globales aleatorios si faltan (poco probable con ~100 términos)
        if len(popular_exercises) < 30:
            additional = Exercise.objects.filter(is_global=True).exclude(id__in=seen_ids)[:20]
            popular_exercises.extend(additional)

        # Retornamos los primeros 120 resultados únicos encontrados
        serializer = self.get_serializer(popular_exercises[:120], many=True)
        return Response(serializer.data)
