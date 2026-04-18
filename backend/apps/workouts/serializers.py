from rest_framework import serializers
from .models import WorkoutSession, WorkoutSet
from apps.exercises.serializers import ExerciseSerializer

class WorkoutSetSerializer(serializers.ModelSerializer):
    exercise_name = serializers.ReadOnlyField(source='exercise.name')

    class Meta:
        model = WorkoutSet
        fields = ['id', 'exercise', 'exercise_name', 'set_number', 'weight', 'reps', 'is_completed']

class WorkoutSessionSerializer(serializers.ModelSerializer):
    sets = WorkoutSetSerializer(many=True, required=False)
    routine_name = serializers.ReadOnlyField(source='routine.name')

    class Meta:
        model = WorkoutSession
        fields = ['id', 'routine', 'routine_name', 'name', 'date', 'start_time', 'end_time', 'notes', 'is_completed', 'sets']
        read_only_fields = ('user', 'start_time')

    def create(self, validated_data):
        sets_data = validated_data.pop('sets', [])
        
        if 'request' in self.context and self.context['request'].user.is_authenticated:
            validated_data['user'] = self.context['request'].user
            
        session = WorkoutSession.objects.create(**validated_data)
        
        for set_data in sets_data:
            WorkoutSet.objects.create(workout_session=session, **set_data)
            
        return session

    def update(self, instance, validated_data):
        sets_data = validated_data.pop('sets', None)
        
        instance.date = validated_data.get('date', instance.date)
        instance.notes = validated_data.get('notes', instance.notes)
        instance.save()

        if sets_data is not None:
            # Recreate sets for simplicity during updates
            instance.sets.all().delete()
            for set_data in sets_data:
                WorkoutSet.objects.create(workout_session=instance, **set_data)

        return instance
