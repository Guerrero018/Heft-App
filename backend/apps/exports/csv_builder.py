from __future__ import annotations

import csv
import io
import zipfile
from datetime import datetime, timezone

from apps.workouts.models import WorkoutSession


def _duration_minutes(session: WorkoutSession) -> str:
    if session.start_time and session.end_time:
        delta = session.end_time - session.start_time
        return str(int(delta.total_seconds() // 60))
    return ''


def _workouts_rows(workouts: list[WorkoutSession]) -> list[list[str]]:
    rows: list[list[str]] = []
    for session in workouts:
        routine_name = session.routine.name if session.routine else ''
        for workout_set in session.sets.all():
            rows.append(
                [
                    session.date.isoformat(),
                    session.name or 'Entrenamiento',
                    routine_name,
                    workout_set.exercise.name,
                    workout_set.exercise.muscle_group,
                    str(workout_set.set_number),
                    str(workout_set.weight),
                    str(workout_set.reps),
                    workout_set.set_type,
                    str(workout_set.rpe) if workout_set.rpe is not None else '',
                    str(workout_set.rir) if workout_set.rir is not None else '',
                    _duration_minutes(session),
                    session.notes or '',
                ],
            )
    return rows


def _body_measures_rows(measures) -> list[list[str]]:
    rows: list[list[str]] = []
    for measure in measures:
        rows.append(
            [
                measure.date.isoformat(),
                str(measure.weight),
                str(measure.neck_cm or ''),
                str(measure.chest_cm or ''),
                str(measure.waist_cm or ''),
                str(measure.hips_cm or ''),
                str(measure.shoulders_cm or ''),
                str(measure.bicep_left_cm or ''),
                str(measure.bicep_right_cm or ''),
                str(measure.thigh_left_cm or ''),
                str(measure.thigh_right_cm or ''),
                measure.notes or '',
            ],
        )
    return rows


def _prs_rows(prs: list[dict]) -> list[list[str]]:
    return [
        [
            row['exercise_name'],
            row['muscle_group'],
            str(row['max_weight_kg']),
            str(row['reps']),
            row['date'],
            row['workout_name'],
            row['routine_name'],
        ]
        for row in prs
    ]


def _write_csv(headers: list[str], rows: list[list[str]]) -> bytes:
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(headers)
    writer.writerows(rows)
    return buffer.getvalue().encode('utf-8-sig')


WORKOUT_HEADERS = [
    'fecha',
    'entrenamiento',
    'rutina',
    'ejercicio',
    'grupo_muscular',
    'serie',
    'peso_kg',
    'reps',
    'tipo_serie',
    'rpe',
    'rir',
    'duracion_min',
    'notas',
]

BODY_MEASURE_HEADERS = [
    'fecha',
    'peso_kg',
    'cuello_cm',
    'pecho_cm',
    'cintura_cm',
    'cadera_cm',
    'hombros_cm',
    'biceps_izq_cm',
    'biceps_der_cm',
    'muslo_izq_cm',
    'muslo_der_cm',
    'notas',
]

PR_HEADERS = [
    'ejercicio',
    'grupo_muscular',
    'peso_max_kg',
    'reps',
    'fecha',
    'entrenamiento',
    'rutina',
]


def build_csv_export(data: dict) -> tuple[bytes, str]:
    files: dict[str, bytes] = {}

    if data['workouts']:
        files['entrenamientos.csv'] = _write_csv(
            WORKOUT_HEADERS,
            _workouts_rows(data['workouts']),
        )
    if data['body_measures']:
        files['medidas.csv'] = _write_csv(
            BODY_MEASURE_HEADERS,
            _body_measures_rows(data['body_measures']),
        )
    if data['prs']:
        files['records_personales.csv'] = _write_csv(PR_HEADERS, _prs_rows(data['prs']))

    if not files:
        files['exportacion_vacia.csv'] = _write_csv(['info'], [['No hay datos con los filtros seleccionados']])

    if len(files) == 1:
        filename, content = next(iter(files.items()))
        stamp = datetime.now(timezone.utc).strftime('%Y%m%d')
        return content, f'heft_{filename.replace(".csv", "")}_{stamp}.csv'

    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, content in files.items():
            archive.writestr(name, content)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%d')
    return zip_buffer.getvalue(), f'heft_export_{stamp}.zip'
