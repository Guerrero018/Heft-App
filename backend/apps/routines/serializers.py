from rest_framework import serializers
from .models import Routine, RoutineExercise
from apps.exercises.serializers import ExerciseSerializer

class RoutineExerciseSerializer(serializers.ModelSerializer):
    exercise_name = serializers.ReadOnlyField(source='exercise.name')
    muscle_group = serializers.ReadOnlyField(source='exercise.muscle_group')
    external_id = serializers.ReadOnlyField(source='exercise.external_id')
    gif_url = serializers.ReadOnlyField(source='exercise.gif_url')
    
    class Meta:
        model = RoutineExercise
        fields = ['id', 'exercise', 'exercise_name', 'muscle_group', 'external_id', 'gif_url', 'order', 'target_sets', 'target_reps', 'target_weight', 'rest_time_seconds']

class RoutineSerializer(serializers.ModelSerializer):
    exercises = RoutineExerciseSerializer(many=True, required=False)

    class Meta:
        model = Routine
        fields = ['id', 'name', 'description', 'is_active', 'created_at', 'updated_at', 'exercises']
        read_only_fields = ('user', 'created_at', 'updated_at')

    def create(self, validated_data):
        # Handle cases where exercises might be None or absent
        exercises_data = validated_data.pop('exercises', []) or []
        
        if 'request' in self.context and self.context['request'].user.is_authenticated:
            validated_data['user'] = self.context['request'].user
        else:
            raise serializers.ValidationError("Debe estar autenticado para crear una rutina.")
            
        routine = Routine.objects.create(**validated_data)
        
        for exercise_data in exercises_data:
            RoutineExercise.objects.create(routine=routine, **exercise_data)
            
        return routine

    def update(self, instance, validated_data):
        exercises_data = validated_data.pop('exercises', None)
        
        instance.name = validated_data.get('name', instance.name)
        instance.description = validated_data.get('description', instance.description)
        instance.is_active = validated_data.get('is_active', instance.is_active)
        instance.save()

        if exercises_data is not None:
            # Recreate exercises for simplicity, or handle updates more granularly
            instance.exercises.all().delete()
            for exercise_data in exercises_data:
                RoutineExercise.objects.create(routine=instance, **exercise_data)

        return instance
