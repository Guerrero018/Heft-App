"""Matching de nombres de ejercicio del catálogo para logros de fuerza."""

import unicodedata


def _normalize(name: str) -> str:
    text = unicodedata.normalize("NFD", (name or "").lower())
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    return text.replace("ñ", "n").strip()


def _contains_any(text: str, patterns: list[str]) -> bool:
    return any(p in text for p in patterns)


def _contains_all(text: str, patterns: list[str]) -> bool:
    return all(p in text for p in patterns)


STRENGTH_EXERCISE_KEYS = frozenset(
    {
        "bench_press",
        "squat",
        "deadlift",
        "incline_bench",
        "overhead_press",
        "rdl",
        "sumo_deadlift",
        "bent_row",
        "close_grip_bench",
        "lat_pulldown",
        "cable_row",
        "pull_up",
        "dips",
    }
)


def matches_strength_exercise(exercise_name: str, exercise_key: str) -> bool:
    n = _normalize(exercise_name)

    if exercise_key == "bench_press":
        if any(
            x in n
            for x in (
                "inclinado",
                "declinado",
                "agarre cerrado",
                "close grip",
                "guillotina",
                " jm",
            )
        ):
            return False
        return _contains_any(
            n,
            [
                "press de banca con barra",
                "press de banca agarre ancho",
                "barbell bench press",
                "press banca",
            ],
        )

    if exercise_key == "squat":
        if any(
            x in n
            for x in (
                "frontal",
                "zercher",
                "bulgara",
                "búlgara",
                "jefferson",
                "salto",
                "hack",
                "smith",
                "multipower",
            )
        ):
            return False
        return _contains_any(
            n,
            [
                "sentadilla completa con barra",
                "sentadilla ancha con barra",
                "sentadilla con barra",
                "sentadilla en banco con barra",
                "back squat",
                "barbell squat",
            ],
        )

    if exercise_key == "deadlift":
        if any(
            x in n
            for x in ("rumano", "sumo", "piernas rectas", "lateral", "una mano")
        ):
            return False
        return _contains_any(
            n, ["peso muerto con barra", "barbell deadlift", "peso muerto "]
        )

    if exercise_key == "incline_bench":
        return _contains_any(n, ["press de banca inclinado", "incline bench"])

    if exercise_key == "overhead_press":
        return _contains_any(
            n,
            [
                "press militar de pie con barra",
                "press militar con barra",
                "overhead press",
                "military press",
            ],
        ) and "sentado" not in n and "smith" not in n

    if exercise_key == "rdl":
        return _contains_any(n, ["peso muerto rumano", "romanian deadlift"])

    if exercise_key == "sumo_deadlift":
        return _contains_any(n, ["peso muerto sumo", "sumo deadlift"])

    if exercise_key == "bent_row":
        return _contains_any(
            n,
            [
                "remo con barra inclinado",
                "bent over row",
                "remo inclinado con barra",
            ],
        )

    if exercise_key == "close_grip_bench":
        return _contains_any(
            n,
            [
                "press de banca con agarre cerrado",
                "press de banca agarre cerrado",
                "close grip bench",
            ],
        )

    if exercise_key == "lat_pulldown":
        return _contains_all(n, ["jalon"]) and _contains_any(
            n, ["pecho", "lat", "posterior"]
        )

    if exercise_key == "cable_row":
        return _contains_any(
            n,
            [
                "remo sentado en polea",
                "remo en polea",
                "seated cable row",
                "remo con cable",
            ],
        )

    if exercise_key == "pull_up":
        if "asistid" in n:
            return False
        return (
            n == "dominada"
            or n.startswith("dominada ")
            or "pull up" in n
            or "pull-up" in n
        )

    if exercise_key == "dips":
        return (
            n == "fondos de pecho"
            or "fondos de pecho" in n
            or "chest dip" in n
        )

    return False


def is_bodyweight_key(exercise_key: str) -> bool:
    return exercise_key in ("pull_up", "dips")
