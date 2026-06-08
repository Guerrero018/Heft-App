"""Catálogo de los 75 logros de Heft para cargar en la base de datos."""

from __future__ import annotations

from typing import Any


def _strength_weight(
    slug_prefix: str,
    exercise_key: str,
    label: str,
    icon: str,
    bronze: float,
    silver: float,
    gold: float,
    start_order: int,
) -> list[dict[str, Any]]:
    items = []
    for order, (tier, threshold) in enumerate(
        [("bronze", bronze), ("silver", silver), ("gold", gold)]
    ):
        tier_label = {"bronze": "Bronce", "silver": "Plata", "gold": "Oro"}[tier]
        items.append(
            {
                "slug": f"{slug_prefix}_{tier}",
                "category": "strength",
                "tier": tier,
                "title": f"{label} — {tier_label}",
                "subtitle": f"≥ {threshold:g} kg",
                "description": (
                    f"Levanta al menos {threshold:g} kg en una serie completada de {label}."
                ),
                "icon_key": icon,
                "criteria": {
                    "type": "strength_weight",
                    "exercise_key": exercise_key,
                    "threshold": threshold,
                },
                "sort_order": start_order + order,
            }
        )
    return items


def _strength_reps(
    slug_prefix: str,
    exercise_key: str,
    label: str,
    icon: str,
    bronze: int,
    silver: int,
    gold: int,
    start_order: int,
) -> list[dict[str, Any]]:
    items = []
    for order, (tier, threshold) in enumerate(
        [("bronze", bronze), ("silver", silver), ("gold", gold)]
    ):
        tier_label = {"bronze": "Bronce", "silver": "Plata", "gold": "Oro"}[tier]
        items.append(
            {
                "slug": f"{slug_prefix}_{tier}",
                "category": "strength",
                "tier": tier,
                "title": f"{label} — {tier_label}",
                "subtitle": f"≥ {threshold} reps",
                "description": (
                    f"Completa una serie de al menos {threshold} repeticiones en {label}."
                ),
                "icon_key": icon,
                "criteria": {
                    "type": "strength_reps",
                    "exercise_key": exercise_key,
                    "threshold": threshold,
                },
                "sort_order": start_order + order,
            }
        )
    return items


def _general(
    slug: str,
    category: str,
    title: str,
    subtitle: str,
    description: str,
    icon_key: str,
    criteria: dict[str, Any],
    sort_order: int,
) -> dict[str, Any]:
    return {
        "slug": slug,
        "category": category,
        "tier": None,
        "title": title,
        "subtitle": subtitle,
        "description": description,
        "icon_key": icon_key,
        "criteria": criteria,
        "sort_order": sort_order,
    }


def achievement_catalog_entries() -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    order = 0

    strength_specs = [
        ("bench_press", "bench_press", "Press de banca", "fitness_center", 60, 100, 140),
        ("squat", "squat", "Sentadilla", "accessibility_new", 80, 120, 160),
        ("deadlift", "deadlift", "Peso muerto", "vertical_align_bottom", 100, 140, 180),
        ("incline_bench", "incline_bench", "Banca inclinada", "trending_up", 50, 85, 120),
        ("overhead_press", "overhead_press", "Press militar", "arrow_upward", 40, 60, 80),
        ("rdl", "rdl", "Peso muerto rumano", "swap_vert", 70, 100, 130),
        ("sumo_deadlift", "sumo_deadlift", "Peso muerto sumo", "open_in_full", 90, 130, 170),
        ("bent_row", "bent_row", "Remo con barra", "format_align_left", 60, 90, 120),
        ("close_grip_bench", "close_grip_bench", "Banca agarre cerrado", "compress", 50, 80, 110),
        ("lat_pulldown", "lat_pulldown", "Jalón al pecho", "arrow_downward", 50, 70, 90),
        ("cable_row", "cable_row", "Remo en polea", "table_rows", 50, 75, 100),
    ]
    for spec in strength_specs:
        entries.extend(_strength_weight(*spec, start_order=order))
        order += 3

    entries.extend(_strength_reps("pull_up", "pull_up", "Dominada", "self_improvement", 5, 10, 20, order))
    order += 3
    entries.extend(_strength_reps("dips", "dips", "Fondos de pecho", "south", 8, 15, 25, order))
    order += 3

    general = [
        _general(
            "first_workout", "consistency", "Primera sesión", "1 entrenamiento",
            "Completaste tu primer entrenamiento en Heft.", "flag",
            {"type": "total_sessions", "threshold": 1}, order,
        ),
        _general(
            "week_streak_4", "consistency", "Racha de hierro", "4 semanas",
            "Cumpliste tu objetivo semanal 4 semanas seguidas.", "local_fire_department",
            {"type": "week_streak", "threshold": 4}, order + 1,
        ),
        _general(
            "week_streak_8", "consistency", "Imparable", "8 semanas",
            "Cumpliste tu objetivo semanal 8 semanas seguidas.", "whatshot",
            {"type": "week_streak", "threshold": 8}, order + 2,
        ),
        _general(
            "week_streak_12", "consistency", "Máquina de constancia", "12 semanas",
            "Cumpliste tu objetivo semanal 12 semanas seguidas.", "bolt",
            {"type": "week_streak", "threshold": 12}, order + 3,
        ),
        _general(
            "days_30", "consistency", "30 días activo", "30 días distintos",
            "Entrenaste en 30 días distintos.", "calendar_month",
            {"type": "distinct_workout_days", "threshold": 30}, order + 4,
        ),
        _general(
            "days_100", "consistency", "Centenario", "100 días distintos",
            "Entrenaste en 100 días distintos.", "event_available",
            {"type": "distinct_workout_days", "threshold": 100}, order + 5,
        ),
        _general(
            "year_1", "consistency", "Un año con Heft", "12 meses activo",
            "Llevas al menos un año entrenando con Heft y al menos un entreno al mes de media.",
            "cake", {"type": "year_active"}, order + 6,
        ),
        _general(
            "sessions_10", "volume", "Novato constante", "10 sesiones",
            "Completaste 10 entrenamientos.", "sports_gymnastics",
            {"type": "total_sessions", "threshold": 10}, order + 7,
        ),
        _general(
            "sessions_50", "volume", "Veterano", "50 sesiones",
            "Completaste 50 entrenamientos.", "military_tech",
            {"type": "total_sessions", "threshold": 50}, order + 8,
        ),
        _general(
            "sessions_100", "volume", "Centurión del gym", "100 sesiones",
            "Completaste 100 entrenamientos.", "shield",
            {"type": "total_sessions", "threshold": 100}, order + 9,
        ),
        _general(
            "sets_500", "volume", "500 series", "Volumen acumulado",
            "Completaste 500 series en total.", "repeat",
            {"type": "total_sets", "threshold": 500}, order + 10,
        ),
        _general(
            "sets_2000", "volume", "Fabricante de series", "2.000 series",
            "Completaste 2.000 series en total.", "autorenew",
            {"type": "total_sets", "threshold": 2000}, order + 11,
        ),
        _general(
            "volume_10t", "volume", "10 toneladas", "10.000 kg",
            "Acumulaste 10.000 kg de volumen (peso × reps).", "scale",
            {"type": "total_volume_kg", "threshold": 10000}, order + 12,
        ),
        _general(
            "volume_50t", "volume", "Levantador de hierro", "50.000 kg",
            "Acumulaste 50.000 kg de volumen (peso × reps).", "fitness_center",
            {"type": "total_volume_kg", "threshold": 50000}, order + 13,
        ),
        _general(
            "long_session_90", "volume", "Sesión maratón", "≥ 90 min",
            "Completaste un entrenamiento de al menos 90 minutos.", "timer",
            {"type": "session_duration_min", "threshold": 90}, order + 14,
        ),
        _general(
            "first_pr", "records", "Primer récord", "Nueva marca",
            "Batiste tu mejor marca en cualquier ejercicio.", "trending_up",
            {"type": "pr_any"}, order + 15,
        ),
        _general(
            "pr_5_exercises", "records", "Multirrécord", "5 ejercicios",
            "Has batido tu récord en 5 ejercicios distintos.", "leaderboard",
            {"type": "pr_exercise_count", "threshold": 5}, order + 16,
        ),
        _general(
            "pr_big3", "records", "Tríada de poder", "Banca + sentadilla + muerto",
            "Alcanzaste el nivel bronce (o superior) en press de banca, sentadilla y peso muerto.",
            "emoji_events", {"type": "pr_big3"}, order + 17,
        ),
        _general(
            "progress_10pct", "records", "+10 % de fuerza", "Progresión",
            "Subiste al menos un 10 % tu máximo en un ejercicio respecto al mes anterior.",
            "show_chart", {"type": "progress_10pct"}, order + 18,
        ),
        _general(
            "body_first_entry", "body_progress", "Línea de salida", "1 registro",
            "Registraste tu primera medida o peso corporal.", "straighten",
            {"type": "body_entries", "threshold": 1}, order + 19,
        ),
        _general(
            "body_5_entries", "body_progress", "Seguimiento activo", "5 registros",
            "Tienes 5 registros de progreso corporal.", "monitor_weight_outlined",
            {"type": "body_entries", "threshold": 5}, order + 20,
        ),
        _general(
            "body_photo", "body_progress", "Antes y después", "1 foto",
            "Subiste tu primera foto de progreso.", "photo_camera",
            {"type": "body_photos", "threshold": 1}, order + 21,
        ),
        _general(
            "body_3_photos", "body_progress", "Álbum de evolución", "3 fotos",
            "Tienes al menos 3 fotos de progreso corporal.", "collections",
            {"type": "body_photos", "threshold": 3}, order + 22,
        ),
        _general(
            "routine_first", "routines", "Mi primera rutina", "1 rutina",
            "Creaste tu primera rutina personalizada.", "playlist_add",
            {"type": "routines_count", "threshold": 1}, order + 23,
        ),
        _general(
            "routine_5", "routines", "Planificador", "5 rutinas",
            "Creaste 5 rutinas.", "view_list",
            {"type": "routines_count", "threshold": 5}, order + 24,
        ),
        _general(
            "exercises_20", "routines", "Explorador", "20 ejercicios",
            "Has realizado 20 ejercicios distintos en tus entrenos.", "explore",
            {"type": "distinct_exercises", "threshold": 20}, order + 25,
        ),
        _general(
            "exercises_50", "routines", "Polivalente", "50 ejercicios",
            "Has realizado 50 ejercicios distintos en tus entrenos.", "hub",
            {"type": "distinct_exercises", "threshold": 50}, order + 26,
        ),
        _general(
            "custom_exercise", "routines", "Inventor", "Ejercicio propio",
            "Creaste un ejercicio personalizado.", "lightbulb_outline",
            {"type": "custom_exercises", "threshold": 1}, order + 27,
        ),
        _general(
            "onboarding_done", "profile", "Perfil completo", "Onboarding",
            "Completaste la configuración inicial de tu perfil.", "check_circle_outline",
            {"type": "onboarding"}, order + 28,
        ),
        _general(
            "profile_photo", "profile", "Cara visible", "Foto de perfil",
            "Añadiste una foto de perfil.", "account_circle",
            {"type": "profile_photo"}, order + 29,
        ),
        _general(
            "night_owl", "special", "Búho del gym", "Después de las 22:00",
            "Entrenaste después de las 22:00.", "nightlight_round",
            {"type": "night_workout"}, order + 30,
        ),
        _general(
            "early_bird", "special", "Madrugador", "Antes de las 07:00",
            "Entrenaste antes de las 07:00.", "wb_sunny_outlined",
            {"type": "early_workout"}, order + 31,
        ),
        _general(
            "weekend_warrior", "special", "Guerrero de finde", "10 fines de semana",
            "Completaste 10 entrenamientos en sábado o domingo.", "weekend",
            {"type": "weekend_sessions", "threshold": 10}, order + 32,
        ),
        _general(
            "full_body_week", "special", "Cuerpo completo", "4 grupos en una semana",
            "En una misma semana entrenaste pecho, espalda, pierna y hombro.",
            "accessibility", {"type": "full_body_week"}, order + 33,
        ),
        _general(
            "rpe_tracker", "special", "Datos al detalle", "50 series con RPE",
            "Registraste RPE en 50 series completadas.", "analytics_outlined",
            {"type": "rpe_sets", "threshold": 50}, order + 34,
        ),
        _general(
            "comeback", "special", "La vuelta", "Tras 14 días parado",
            "Volviste a entrenar después de al menos 14 días sin sesión.", "replay",
            {"type": "comeback", "gap_days": 14}, order + 35,
        ),
    ]
    entries.extend(general)
    return entries


def load_achievement_catalog() -> int:
    from .models import Achievement

    created_or_updated = 0
    for entry in achievement_catalog_entries():
        Achievement.objects.update_or_create(
            slug=entry["slug"],
            defaults={
                "category": entry["category"],
                "tier": entry["tier"],
                "title": entry["title"],
                "subtitle": entry["subtitle"],
                "description": entry["description"],
                "icon_key": entry["icon_key"],
                "criteria": entry["criteria"],
                "sort_order": entry["sort_order"],
                "is_active": True,
            },
        )
        created_or_updated += 1
    return created_or_updated
