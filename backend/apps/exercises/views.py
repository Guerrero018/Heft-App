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
        Devuelve el catálogo de populares utilizando búsqueda 'Fuzzy' ultrarrobusta.
        Ignora errores de tildes o diferencias entre la BD local y la de producción.
        """
        # Formato: (fragmento_grupo_muscular, [palabras_clave_del_ejercicio])
        robust_search_map = [
            # PECHO
            ('pecho', ['banca', 'inclinad', 'declinad', 'apertura', 'cruce', 'flexion', 'fondo']),
            # ESPALDA
            ('espalda', ['dominada', 'remo', 'jalon', 'jalón', 'pullover']),
            # CUÁDRICEPS / PIERNA
            ('cuadriceps', ['sentadilla', 'prensa', 'extension', 'extensión', 'zancada', 'hack', 'bulgara', 'búlgara']),
            # ISQUIOTIBIALES / FEMORAL (Búsqueda súper amplia)
            ('isquio', ['curl', 'peso muerto', 'femoral', 'buenos dias', 'buenos días']),
            ('femo', ['curl', 'peso muerto']), 
            # GLÚTEOS
            ('gluteo', ['hip thrust', 'patada', 'abducci', 'puente']),
            # HOMBROS
            ('hombro', ['militar', 'lateral', 'frontal', 'pajaro', 'pájaro', 'face pull']),
            # BRAZOS (BÍCEPS Y TRÍCEPS)
            ('biceps', ['curl', 'martillo', 'scott', 'predicador']),
            ('triceps', ['frances', 'francés', 'extension', 'extensión', 'patada', 'cerrado']),
            # CORE Y GEMELOS
            ('abdomin', ['crunch', 'plancha', 'rueda', 'elevacion', 'elevación']),
            ('gemelo', ['talon', 'gemelo'])
        ]
        
        popular_exercises = []
        seen_ids = set()
        
        for muscle_fragment, keywords in robust_search_map:
            for kw in keywords:
                # Buscamos de forma muy permisiva: que el grupo contenga el fragmento y el nombre la palabra
                matches = Exercise.objects.filter(
                    muscle_group__icontains=muscle_fragment,
                    name__icontains=kw,
                    is_global=True
                )[:3] # Hasta 3 por palabra clave
                
                for ex in matches:
                    if ex.id not in seen_ids:
                        popular_exercises.append(ex)
                        seen_ids.add(ex.id)
                        
        # Búsqueda de rescate universal para los reyes del gimnasio (por si fallan los grupos musculares)
        kings = ['press de banca', 'sentadilla', 'peso muerto', 'dominada']
        for king in kings:
            matches = Exercise.objects.filter(name__icontains=king, is_global=True)[:2]
            for ex in matches:
                if ex.id not in seen_ids:
                    popular_exercises.append(ex)
                    seen_ids.add(ex.id)
        
        # Si la lista es menor a 40, rellenamos con globales para que nunca esté vacía
        if len(popular_exercises) < 40:
            additional = Exercise.objects.filter(is_global=True).exclude(id__in=seen_ids)[:(40 - len(popular_exercises))]
            popular_exercises.extend(additional)

        serializer = self.get_serializer(popular_exercises[:100], many=True)
        return Response(serializer.data)
