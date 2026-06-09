from rest_framework import serializers


class ExportRequestSerializer(serializers.Serializer):
    FORMAT_CSV = 'csv'
    FORMAT_PDF = 'pdf'
    FORMAT_CHOICES = [FORMAT_CSV, FORMAT_PDF]

    format = serializers.ChoiceField(choices=FORMAT_CHOICES, default=FORMAT_CSV)
    include_workouts = serializers.BooleanField(default=True)
    include_body_measures = serializers.BooleanField(default=True)
    include_prs = serializers.BooleanField(default=True)
    date_from = serializers.DateField(required=False, allow_null=True)
    date_to = serializers.DateField(required=False, allow_null=True)
    routine_id = serializers.IntegerField(required=False, allow_null=True, min_value=1)
    exercise_id = serializers.IntegerField(required=False, allow_null=True, min_value=1)

    def validate(self, attrs):
        date_from = attrs.get('date_from')
        date_to = attrs.get('date_to')
        if date_from and date_to and date_from > date_to:
            raise serializers.ValidationError(
                {'date_to': 'La fecha final debe ser posterior o igual a la inicial.'},
            )

        if not any(
            [
                attrs.get('include_workouts', True),
                attrs.get('include_body_measures', True),
                attrs.get('include_prs', True),
            ],
        ):
            raise serializers.ValidationError(
                'Selecciona al menos un tipo de dato para exportar.',
            )
        return attrs

    def to_filters(self):
        from .filters import ExportFilters

        validated = self.validated_data
        return ExportFilters(
            date_from=validated.get('date_from'),
            date_to=validated.get('date_to'),
            routine_id=validated.get('routine_id'),
            exercise_id=validated.get('exercise_id'),
            include_workouts=validated.get('include_workouts', True),
            include_body_measures=validated.get('include_body_measures', True),
            include_prs=validated.get('include_prs', True),
        )
