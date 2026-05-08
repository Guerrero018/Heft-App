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
        Devuelve una lista masiva y curada basada en palabras clave y grupos musculares reales.
        """
        # Definimos los 'imprescindibles' por grupo muscular real de la DB
        categories = {
            'pecho': ['Banca', 'Apertura', 'Polea', 'Flexi', 'Dips'],
            'espalda': ['Remo', 'Dominada', 'Jalón', 'Jalon', 'Pull', 'Lumbares'],
            'isquiotibiales': ['Curl de pierna', 'Femoral', 'Peso muerto', 'Isquio', 'Buenos días'],
            'cuadriceps': ['Sentadilla', 'Prensa', 'Extensión', 'Extension', 'Zancada', 'Hack'],
            'hombros': ['Militar', 'Press de hombro', 'Lateral', 'Frontal', 'Face pull', 'Pájaro'],
            'biceps': ['Curl', 'Martillo', 'Scott', 'Bíceps'],
            'triceps': ['Francés', 'Frances', 'Tríceps', 'Polea', 'Extensión'],
            'gluteos': ['Hip thrust', 'Glúteo', 'Abducción', 'Patada'],
            'abdominales': ['Crunch', 'Plancha', 'Plank', 'Piernas', 'Rueda']
        }
        
        popular_exercises = []
        seen_ids = set()
        
        # Estrategia: Por cada categoría, buscamos sus palabras clave
        for muscle, keywords in categories.items():
            category_matches = []
            for kw in keywords:
                # Buscamos que coincida el grupo Y la palabra clave
                matches = Exercise.objects.filter(
                    muscle_group=muscle,
                    name__icontains=kw,
                    is_global=True
                )[:3] # Cogemos hasta 3 por palabra clave para variedad
                
                for ex in matches:
                    if ex.id not in seen_ids:
                        category_matches.append(ex)
                        seen_ids.add(ex.id)
            
            # Añadimos los de esta categoría a la lista global
            popular_exercises.extend(category_matches)
        
        # Si por algún motivo extremo la lista sigue siendo corta, rellenamos con globales
        if len(popular_exercises) < 50:
            additional = Exercise.objects.filter(is_global=True).exclude(id__in=seen_ids)[:30]
            popular_exercises.extend(additional)

        # Retornamos los resultados (limitamos a 150 para no saturar)
        serializer = self.get_serializer(popular_exercises[:150], many=True)
        return Response(serializer.data)
