from rest_framework import serializers
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'height', 'units_preference', 
            'birth_date', 'gender', 'experience_level', 'fitness_goal', 
            'workout_days_per_week', 'workout_duration_minutes', 'is_onboarded'
        )

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    tokens = serializers.SerializerMethodField()
    
    # Campos de onboarding opcionales durante el registro
    height = serializers.FloatField(required=False)
    gender = serializers.CharField(required=False)
    experience_level = serializers.CharField(required=False)
    fitness_goal = serializers.CharField(required=False)
    workout_days_per_week = serializers.IntegerField(required=False)
    workout_duration_minutes = serializers.IntegerField(required=False)

    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'password', 'tokens',
            'height', 'gender', 'experience_level', 'fitness_goal',
            'workout_days_per_week', 'workout_duration_minutes'
        )

    def get_tokens(self, user):
        refresh = RefreshToken.for_user(user)
        return {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': CustomUserSerializer(user).data
        }

    def validate_email(self, value):
        email = value.lower().strip()
        if User.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError("¡ALERTA!: EL USUARIO YA EXISTE EN EL SISTEMA")
        return email

    def create(self, validated_data):
        onboarding_data = {
            'height': validated_data.pop('height', None),
            'gender': validated_data.pop('gender', None),
            'experience_level': validated_data.pop('experience_level', None),
            'fitness_goal': validated_data.pop('fitness_goal', None),
            'workout_days_per_week': validated_data.pop('workout_days_per_week', 3),
            'workout_duration_minutes': validated_data.pop('workout_duration_minutes', 60),
            'is_onboarded': False # Siempre False al registrarse, hasta completar Onboarding
        }
        
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            **onboarding_data
        )
        return user
