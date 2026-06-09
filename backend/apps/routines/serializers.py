from rest_framework import serializers

from .models import Routine, RoutineExercise


class RoutineExerciseSerializer(serializers.ModelSerializer):
    exercise_name = serializers.ReadOnlyField(source='exercise.name')
    muscle_group = serializers.ReadOnlyField(source='exercise.muscle_group')
    external_id = serializers.ReadOnlyField(source='exercise.external_id')
    gif_url = serializers.ReadOnlyField(source='exercise.gif_url')

    class Meta:
        model = RoutineExercise
        fields = [
            'id',
            'exercise',
            'exercise_name',
            'muscle_group',
            'external_id',
            'gif_url',
            'order',
            'target_sets',
            'target_reps',
            'target_weight',
            'rest_time_seconds',
        ]


class RoutineAuthorSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField()


class RoutineSerializer(serializers.ModelSerializer):
    exercises = RoutineExerciseSerializer(many=True, required=False)
    share_code = serializers.CharField(read_only=True)
    times_imported = serializers.IntegerField(read_only=True)

    class Meta:
        model = Routine
        fields = [
            'id',
            'name',
            'description',
            'is_active',
            'is_public',
            'share_code',
            'times_imported',
            'created_at',
            'updated_at',
            'exercises',
        ]
        read_only_fields = (
            'user',
            'created_at',
            'updated_at',
            'share_code',
            'times_imported',
            'is_public',
        )

    def create(self, validated_data):
        exercises_data = validated_data.pop('exercises', []) or []

        if 'request' in self.context and self.context['request'].user.is_authenticated:
            validated_data['user'] = self.context['request'].user
        else:
            raise serializers.ValidationError(
                'Debe estar autenticado para crear una rutina.',
            )

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
            instance.exercises.all().delete()
            for exercise_data in exercises_data:
                RoutineExercise.objects.create(routine=instance, **exercise_data)

        return instance


class PublicRoutineSerializer(serializers.ModelSerializer):
    exercises = RoutineExerciseSerializer(many=True, read_only=True)
    author = serializers.SerializerMethodField()
    exercise_count = serializers.SerializerMethodField()

    class Meta:
        model = Routine
        fields = [
            'id',
            'name',
            'description',
            'is_official',
            'times_imported',
            'published_at',
            'author',
            'exercise_count',
            'exercises',
        ]

    def get_author(self, obj):
        return {
            'id': obj.user_id,
            'username': obj.user.username,
        }

    def get_exercise_count(self, obj):
        return obj.exercises.count()


class PublicRoutineListSerializer(serializers.ModelSerializer):
    author = serializers.SerializerMethodField()
    exercise_count = serializers.SerializerMethodField()

    class Meta:
        model = Routine
        fields = [
            'id',
            'name',
            'description',
            'is_official',
            'times_imported',
            'published_at',
            'author',
            'exercise_count',
        ]

    def get_author(self, obj):
        return {
            'id': obj.user_id,
            'username': obj.user.username,
        }

    def get_exercise_count(self, obj):
        if hasattr(obj, '_exercise_count'):
            return obj._exercise_count
        return obj.exercises.count()
