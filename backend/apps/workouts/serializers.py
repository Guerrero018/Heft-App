from rest_framework import serializers
from .models import WorkoutSession, WorkoutSet
from apps.exercises.serializers import ExerciseSerializer

class WorkoutSetSerializer(serializers.ModelSerializer):
    exercise_name = serializers.ReadOnlyField(source='exercise.name')
    # id is explicitly added so we can match sets when updating
    id = serializers.IntegerField(required=False)

    class Meta:
        model = WorkoutSet
        fields = ['id', 'exercise', 'exercise_name', 'set_number', 'set_type', 'weight', 'reps', 'rpe', 'rir', 'is_completed']

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
            # remove id if it somehow got through on create
            set_data.pop('id', None)
            WorkoutSet.objects.create(workout_session=session, **set_data)
            
        return session

    def update(self, instance, validated_data):
        sets_data = validated_data.pop('sets', None)
        
        instance.date = validated_data.get('date', instance.date)
        instance.notes = validated_data.get('notes', instance.notes)
        instance.end_time = validated_data.get('end_time', instance.end_time)
        instance.is_completed = validated_data.get('is_completed', instance.is_completed)
        instance.save()

        if sets_data is not None:
            # Non-destructive update: check existing IDs
            existing_sets = {s.id: s for s in instance.sets.all()}
            updated_set_ids = []

            for set_data in sets_data:
                set_id = set_data.get('id', None)
                if set_id and set_id in existing_sets:
                    # Update existing set
                    workout_set = existing_sets[set_id]
                    for attr, value in set_data.items():
                        if attr != 'id':
                            setattr(workout_set, attr, value)
                    workout_set.save()
                    updated_set_ids.append(set_id)
                else:
                    # Create new set
                    set_data.pop('id', None) # remove id just in case
                    new_set = WorkoutSet.objects.create(workout_session=instance, **set_data)
                    updated_set_ids.append(new_set.id)

            # Delete sets that were omitted
            for old_id, old_set in existing_sets.items():
                if old_id not in updated_set_ids:
                    old_set.delete()

        return instance
