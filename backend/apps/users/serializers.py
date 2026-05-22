from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import check_password
from django.contrib.auth.password_validation import validate_password
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from .models import BodyMeasures, PasswordResetCode

User = get_user_model()


def resolve_media_url(file_field, request=None):
    if not file_field:
        return None
    url = file_field.url
    if url.startswith("/media/"):
        if request:
            return request.build_absolute_uri(url)
        return f"http://10.0.2.2:8000{url}"
    if url.startswith("http://"):
        return url.replace("http://", "https://", 1)
    return url

class CustomUserSerializer(serializers.ModelSerializer):
    profile_picture = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'height', 'weight', 'profile_picture', 'units_preference', 
            'birth_date', 'gender', 'experience_level', 'fitness_goal', 
            'workout_days_per_week', 'workout_duration_minutes', 'is_onboarded', 'track_rpe'
        )

    def validate_workout_days_per_week(self, value):
        if value is not None and not 1 <= value <= 7:
            raise serializers.ValidationError('Debe estar entre 1 y 7 días.')
        return value

    def to_representation(self, instance):
        """Sobrescribimos para devolver siempre la URL completa/Cloudinary/Default"""
        ret = super().to_representation(instance)
        
        # Lógica para obtener la URL correcta
        if instance.profile_picture:
            ret['profile_picture'] = resolve_media_url(
                instance.profile_picture,
                self.context.get("request"),
            )
        else:
            # Foto por defecto oficial de Heft
            ret['profile_picture'] = "https://res.cloudinary.com/dcmhsvy2l/image/upload/v1776343470/DefaultProfile.png"
            
        return ret


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
    weight = serializers.FloatField(required=False)

    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'password', 'tokens',
            'height', 'weight', 'gender', 'experience_level', 'fitness_goal',
            'workout_days_per_week', 'workout_duration_minutes'
        )

    def get_tokens(self, user):
        refresh = RefreshToken.for_user(user)
        return {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': CustomUserSerializer(user, context=self.context).data
        }

    def validate_email(self, value):
        email = value.lower().strip()
        if User.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError("¡ALERTA!: EL USUARIO YA EXISTE EN EL SISTEMA")
        return email

    def create(self, validated_data):
        onboarding_data = {
            'height': validated_data.pop('height', None),
            'weight': validated_data.pop('weight', None),
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


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        email = value.lower().strip()
        if not User.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError("No existe ninguna cuenta con ese email.")
        return email


class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(min_length=6, max_length=6)
    new_password = serializers.CharField(write_only=True, min_length=8)
    confirm_password = serializers.CharField(write_only=True, min_length=8)

    default_error_messages = {
        "invalid_code": "El código es inválido o ha expirado.",
        "too_many_attempts": "Demasiados intentos. Solicita un nuevo código.",
    }

    def validate(self, attrs):
        attrs["email"] = attrs["email"].lower().strip()

        if attrs["new_password"] != attrs["confirm_password"]:
            raise serializers.ValidationError(
                {"confirm_password": "Las contraseñas no coinciden."}
            )

        user = User.objects.filter(email__iexact=attrs["email"]).first()
        if not user:
            raise serializers.ValidationError({"email": "No existe ninguna cuenta con ese email."})

        reset_code = (
            PasswordResetCode.objects.filter(
                user=user,
                used_at__isnull=True,
                expires_at__gt=timezone.now(),
            )
            .order_by("-created_at")
            .first()
        )

        if not reset_code:
            raise serializers.ValidationError({"code": self.error_messages["invalid_code"]})

        if reset_code.attempts >= 5:
            raise serializers.ValidationError({"code": self.error_messages["too_many_attempts"]})

        if not check_password(attrs["code"], reset_code.code_hash):
            reset_code.attempts += 1
            update_fields = ["attempts"]
            if reset_code.attempts >= 5:
                reset_code.used_at = timezone.now()
                update_fields.append("used_at")
            reset_code.save(update_fields=update_fields)
            raise serializers.ValidationError({"code": self.error_messages["invalid_code"]})

        validate_password(attrs["new_password"], user=user)

        attrs["user"] = user
        attrs["reset_code"] = reset_code
        return attrs

    def save(self, **kwargs):
        user = self.validated_data["user"]
        reset_code = self.validated_data["reset_code"]
        now = timezone.now()

        user.set_password(self.validated_data["new_password"])
        user.save(update_fields=["password"])

        PasswordResetCode.objects.filter(
            user=user,
            used_at__isnull=True,
        ).update(used_at=now)

        reset_code.used_at = now
        reset_code.save(update_fields=["used_at"])

        return user


class BodyMeasuresSerializer(serializers.ModelSerializer):
    photo = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = BodyMeasures
        fields = (
            "id",
            "weight",
            "date",
            "notes",
            "photo",
            "neck_cm",
            "chest_cm",
            "waist_cm",
            "hips_cm",
            "shoulders_cm",
            "bicep_left_cm",
            "bicep_right_cm",
            "thigh_left_cm",
            "thigh_right_cm",
        )
        read_only_fields = ("id",)

    def validate_weight(self, value):
        if value <= 0 or value > 500:
            raise serializers.ValidationError("El peso debe estar entre 0 y 500 kg.")
        return value

    def validate(self, attrs):
        measurement_fields = (
            "neck_cm",
            "chest_cm",
            "waist_cm",
            "hips_cm",
            "shoulders_cm",
            "bicep_left_cm",
            "bicep_right_cm",
            "thigh_left_cm",
            "thigh_right_cm",
        )
        for field in measurement_fields:
            value = attrs.get(field)
            if value is not None and (value <= 0 or value > 300):
                raise serializers.ValidationError(
                    {field: "La medida debe estar entre 0 y 300 cm."}
                )
        return attrs

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        ret["photo"] = resolve_media_url(instance.photo, self.context.get("request"))
        return ret
