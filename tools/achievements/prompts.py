"""Prompts y metadatos visuales para los 75 logros de Heft."""

from __future__ import annotations

STRENGTH_EXERCISE_VISUALS: dict[str, str] = {
    "bench_press": "barbell bench press lifter on flat bench",
    "squat": "barbell back squat athlete",
    "deadlift": "conventional barbell deadlift from floor",
    "incline_bench": "incline barbell bench press",
    "overhead_press": "standing barbell overhead press",
    "rdl": "romanian deadlift with barbell",
    "sumo_deadlift": "sumo stance barbell deadlift",
    "bent_row": "bent over barbell row",
    "close_grip_bench": "close grip barbell bench press",
    "lat_pulldown": "lat pulldown cable machine",
    "cable_row": "seated cable row",
    "pull_up": "athlete doing pull-up on bar",
    "dips": "parallel bar chest dips",
}

CATEGORY_LABELS: dict[str, str] = {
    "consistency": "constancia",
    "volume": "volumen",
    "records": "records",
    "body_progress": "progreso corporal",
    "routines": "rutinas",
    "profile": "perfil",
    "special": "especiales",
    "strength": "fuerza",
}

GENERAL_CONCEPTS: dict[str, str] = {
    "first_workout": "first gym workout finish flag and dumbbell",
    "week_streak_4": "flame streak four weeks consistency",
    "week_streak_8": "intense fire streak eight weeks",
    "week_streak_12": "lightning bolt twelve week gym streak",
    "days_30": "calendar thirty active workout days",
    "days_100": "calendar hundred workout days milestone",
    "year_1": "birthday cake one year fitness anniversary",
    "sessions_10": "ten workout sessions badge",
    "sessions_50": "fifty workouts veteran medal",
    "sessions_100": "hundred workouts centurion shield",
    "sets_500": "five hundred completed sets stacked plates",
    "sets_2000": "two thousand sets volume factory gears",
    "volume_10t": "ten ton weight scale ten thousand kg",
    "volume_50t": "massive iron volume fifty tons lifted",
    "long_session_90": "stopwatch ninety minute marathon workout",
    "first_pr": "personal record arrow breaking weight plate",
    "pr_5_exercises": "leaderboard five exercise personal records",
    "pr_big3": "trophy bench squat deadlift big three",
    "progress_10pct": "strength chart ten percent progress arrow up",
    "body_first_entry": "tape measure first body measurement",
    "body_5_entries": "weight scale five body progress entries",
    "body_photo": "camera before after progress photo",
    "body_3_photos": "photo album three body progress pictures",
    "routine_first": "first workout routine checklist playlist",
    "routine_5": "five workout routines planner list",
    "exercises_20": "compass twenty different exercises explored",
    "exercises_50": "hub fifty exercises versatile training",
    "custom_exercise": "lightbulb custom invented exercise",
    "onboarding_done": "profile checkmark completed setup",
    "profile_photo": "user avatar profile picture badge",
    "night_owl": "moon and dumbbell night gym owl",
    "early_bird": "sunrise dumbbell early morning workout",
    "weekend_warrior": "weekend calendar saturday sunday gym",
    "full_body_week": "full body muscle groups chest back legs shoulders",
    "rpe_tracker": "analytics chart RPE training data",
    "comeback": "replay return arrow comeback after break",
}

STRENGTH_PROMPT_TEMPLATE = (
    "Flat fitness app achievement badge, {visual} with equipment, "
    "minimal vector illustration, centered silhouette, dark transparent background, "
    "accent color lime yellow #E2F163, clean lines, no text, no photorealism, "
    "game achievement icon style, 512x512, readable at small size"
)

GENERAL_PROMPT_TEMPLATE = (
    "Flat fitness app achievement badge, symbol of {concept}, "
    "category {category_label}, same Heft style: minimal vector, lime accent #E2F163, "
    "dark background, no text, centered icon, 512x512, readable at small size"
)


def strength_prompt(exercise_key: str) -> str:
    visual = STRENGTH_EXERCISE_VISUALS.get(exercise_key, exercise_key.replace("_", " "))
    return STRENGTH_PROMPT_TEMPLATE.format(visual=visual)


def general_prompt(slug: str, category: str) -> str:
    concept = GENERAL_CONCEPTS.get(slug, slug.replace("_", " "))
    category_label = CATEGORY_LABELS.get(category, category)
    return GENERAL_PROMPT_TEMPLATE.format(concept=concept, category_label=category_label)
