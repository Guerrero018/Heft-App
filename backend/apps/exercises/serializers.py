from rest_framework import serializers
from .models import Exercise

class ExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exercise
        fields = '__all__'
        read_only_fields = ('user',)

    def create(self, validated_data):
        # Automatically assign the exercise to the logged-in user
        if 'request' in self.context and self.context['request'].user.is_authenticated:
            validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
