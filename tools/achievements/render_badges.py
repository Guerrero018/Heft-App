#!/usr/bin/env python
"""Genera badges flat 512x512 en .achievement_build/ (temporal; subir con upload_achievement_images)."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
TOOLS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BACKEND))
sys.path.insert(0, str(TOOLS_DIR))

from apps.achievements.catalog import achievement_catalog_entries  # noqa: E402
from paths import bases_dir, export_dir, resolve_build_dir  # noqa: E402

SIZE = 512
CENTER = SIZE // 2
ACCENT = (226, 241, 99)
MUTED = (120, 120, 120)
SURFACE = (26, 26, 26, 255)


def _configure(build_dir: Path) -> tuple[Path, Path]:
    return bases_dir(build_dir), export_dir(build_dir)


def _new_canvas() -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse((56, 56, 456, 456), fill=SURFACE)
    return img


def _barbell(draw: ImageDraw.ImageDraw, cx: int, cy: int, width: int, color=ACCENT) -> None:
    half = width // 2
    draw.rectangle((cx - half, cy - 4, cx + half, cy + 4), fill=color)
    for side in (-half - 8, half + 2):
        draw.rectangle((cx + side, cy - 14, cx + side + 10, cy + 14), fill=color)


def _person_torso(draw: ImageDraw.ImageDraw, cx: int, cy: int, color=ACCENT) -> None:
    draw.ellipse((cx - 18, cy - 30, cx + 18, cy + 6), fill=color)
    draw.rectangle((cx - 12, cy + 6, cx + 12, cy + 50), fill=color)


def draw_bench_press(draw: ImageDraw.ImageDraw) -> None:
    draw.rectangle((140, 300, 372, 330), fill=MUTED)
    _person_torso(draw, CENTER, 250)
    _barbell(draw, CENTER, 220, 160)


def draw_squat(draw: ImageDraw.ImageDraw) -> None:
    _person_torso(draw, CENTER, 230)
    _barbell(draw, CENTER, 200, 150)
    draw.polygon([(CENTER - 40, 280), (CENTER - 20, 340), (CENTER, 280)], fill=ACCENT)
    draw.polygon([(CENTER + 40, 280), (CENTER + 20, 340), (CENTER, 280)], fill=ACCENT)


def draw_deadlift(draw: ImageDraw.ImageDraw) -> None:
    _barbell(draw, CENTER, 320, 140)
    draw.polygon([(CENTER - 30, 200), (CENTER + 30, 200), (CENTER + 50, 320), (CENTER - 50, 320)], fill=ACCENT)


def draw_incline_bench(draw: ImageDraw.ImageDraw) -> None:
    draw.polygon([(120, 330), (340, 260), (380, 330)], fill=MUTED)
    _person_torso(draw, CENTER - 10, 250)
    _barbell(draw, CENTER, 230, 130)


def draw_overhead_press(draw: ImageDraw.ImageDraw) -> None:
    _person_torso(draw, CENTER, 280)
    _barbell(draw, CENTER, 170, 120)


def draw_rdl(draw: ImageDraw.ImageDraw) -> None:
    _barbell(draw, CENTER, 260, 130)
    draw.polygon([(CENTER - 25, 200), (CENTER + 25, 200), (CENTER + 35, 300), (CENTER - 35, 300)], fill=ACCENT)


def draw_sumo_deadlift(draw: ImageDraw.ImageDraw) -> None:
    _barbell(draw, CENTER, 310, 160)
    draw.polygon([(CENTER - 55, 300), (CENTER - 25, 340), (CENTER, 300)], fill=ACCENT)
    draw.polygon([(CENTER + 55, 300), (CENTER + 25, 340), (CENTER, 300)], fill=ACCENT)
    draw.ellipse((CENTER - 20, 220, CENTER + 20, 280), fill=ACCENT)


def draw_bent_row(draw: ImageDraw.ImageDraw) -> None:
    draw.polygon([(CENTER - 60, 280), (CENTER + 80, 240), (CENTER + 60, 300)], fill=ACCENT)
    _barbell(draw, CENTER + 20, 250, 120)


def draw_close_grip_bench(draw: ImageDraw.ImageDraw) -> None:
    draw.rectangle((140, 300, 372, 330), fill=MUTED)
    _person_torso(draw, CENTER, 250)
    _barbell(draw, CENTER, 220, 90)


def draw_lat_pulldown(draw: ImageDraw.ImageDraw) -> None:
    draw.rectangle((CENTER - 60, 120, CENTER + 60, 140), fill=MUTED)
    draw.line((CENTER, 140, CENTER, 220), fill=MUTED, width=4)
    _person_torso(draw, CENTER, 260)
    draw.line((CENTER, 220, CENTER, 250), fill=ACCENT, width=6)


def draw_cable_row(draw: ImageDraw.ImageDraw) -> None:
    draw.rectangle((100, 280, 180, 340), fill=MUTED)
    _person_torso(draw, CENTER + 40, 260)
    draw.line((180, 300, CENTER - 10, 280), fill=MUTED, width=4)
    draw.rectangle((CENTER - 30, 270, CENTER + 10, 290), fill=ACCENT)


def draw_pull_up(draw: ImageDraw.ImageDraw) -> None:
    draw.rectangle((CENTER - 80, 140, CENTER + 80, 155), fill=MUTED)
    draw.line((CENTER - 60, 155, CENTER - 60, 200), fill=MUTED, width=5)
    draw.line((CENTER + 60, 155, CENTER + 60, 200), fill=MUTED, width=5)
    draw.arc((CENTER - 30, 180, CENTER + 30, 280), 200, 340, fill=ACCENT, width=8)


def draw_dips(draw: ImageDraw.ImageDraw) -> None:
    draw.line((CENTER - 70, 160, CENTER - 70, 220), fill=MUTED, width=6)
    draw.line((CENTER + 70, 160, CENTER + 70, 220), fill=MUTED, width=6)
    draw.line((CENTER - 70, 180, CENTER + 70, 180), fill=MUTED, width=5)
    draw.ellipse((CENTER - 25, 200, CENTER + 25, 300), outline=ACCENT, width=8)


STRENGTH_DRAWERS = {
    "bench_press": draw_bench_press,
    "squat": draw_squat,
    "deadlift": draw_deadlift,
    "incline_bench": draw_incline_bench,
    "overhead_press": draw_overhead_press,
    "rdl": draw_rdl,
    "sumo_deadlift": draw_sumo_deadlift,
    "bent_row": draw_bent_row,
    "close_grip_bench": draw_close_grip_bench,
    "lat_pulldown": draw_lat_pulldown,
    "cable_row": draw_cable_row,
    "pull_up": draw_pull_up,
    "dips": draw_dips,
}


def _draw_flame(draw: ImageDraw.ImageDraw, intensity: int = 1) -> None:
    h = 40 + intensity * 15
    draw.polygon([(CENTER, CENTER - h), (CENTER - 35, CENTER + 20), (CENTER + 35, CENTER + 20)], fill=(255, 120 + intensity * 20, 40))
    draw.polygon([(CENTER, CENTER - h + 30), (CENTER - 20, CENTER + 10), (CENTER + 20, CENTER + 10)], fill=(255, 200, 80))


def _draw_trophy(draw: ImageDraw.ImageDraw) -> None:
    draw.rectangle((CENTER - 35, CENTER - 40, CENTER + 35, CENTER + 10), fill=ACCENT)
    draw.rectangle((CENTER - 15, CENTER + 10, CENTER + 15, CENTER + 40), fill=ACCENT)
    draw.rectangle((CENTER - 30, CENTER + 40, CENTER + 30, CENTER + 55), fill=MUTED)


def _draw_calendar(draw: ImageDraw.ImageDraw, dots: int = 3) -> None:
    draw.rectangle((CENTER - 50, CENTER - 40, CENTER + 50, CENTER + 50), outline=ACCENT, width=4)
    for i in range(min(dots, 9)):
        x = CENTER - 30 + (i % 3) * 30
        y = CENTER - 10 + (i // 3) * 25
        draw.ellipse((x, y, x + 12, y + 12), fill=ACCENT)


def _draw_dumbbell_icon(draw: ImageDraw.ImageDraw) -> None:
    _barbell(draw, CENTER, CENTER, 100)


def _draw_scale(draw: ImageDraw.ImageDraw) -> None:
    draw.rectangle((CENTER - 45, CENTER, CENTER + 45, CENTER + 50), fill=MUTED)
    draw.ellipse((CENTER - 50, CENTER - 30, CENTER + 50, CENTER + 20), outline=ACCENT, width=5)


def _draw_arrow_up(draw: ImageDraw.ImageDraw) -> None:
    draw.polygon([(CENTER, CENTER - 50), (CENTER - 35, CENTER + 10), (CENTER + 35, CENTER + 10)], fill=ACCENT)
    draw.rectangle((CENTER - 12, CENTER + 10, CENTER + 12, CENTER + 50), fill=ACCENT)


def _draw_camera(draw: ImageDraw.ImageDraw) -> None:
    draw.rectangle((CENTER - 50, CENTER - 20, CENTER + 50, CENTER + 40), fill=MUTED)
    draw.ellipse((CENTER - 25, CENTER - 10, CENTER + 25, CENTER + 30), outline=ACCENT, width=5)


def _draw_check(draw: ImageDraw.ImageDraw) -> None:
    draw.line((CENTER - 40, CENTER, CENTER - 10, CENTER + 35), fill=ACCENT, width=10)
    draw.line((CENTER - 10, CENTER + 35, CENTER + 45, CENTER - 30), fill=ACCENT, width=10)


def _draw_avatar(draw: ImageDraw.ImageDraw) -> None:
    draw.ellipse((CENTER - 40, CENTER - 50, CENTER + 40, CENTER + 30), fill=ACCENT)
    draw.ellipse((CENTER - 55, CENTER + 20, CENTER + 55, CENTER + 80), fill=ACCENT)


def _draw_moon(draw: ImageDraw.ImageDraw) -> None:
    draw.arc((CENTER - 45, CENTER - 45, CENTER + 45, CENTER + 45), 60, 300, fill=ACCENT, width=12)
    _barbell(draw, CENTER, CENTER + 60, 70)


def _draw_sun(draw: ImageDraw.ImageDraw) -> None:
    draw.ellipse((CENTER - 30, CENTER - 30, CENTER + 30, CENTER + 30), fill=(255, 200, 60))
    for angle in range(0, 360, 45):
        rad = math.radians(angle)
        x1 = CENTER + int(40 * math.cos(rad))
        y1 = CENTER + int(40 * math.sin(rad))
        x2 = CENTER + int(55 * math.cos(rad))
        y2 = CENTER + int(55 * math.sin(rad))
        draw.line((x1, y1, x2, y2), fill=(255, 200, 60), width=4)


def _draw_list(draw: ImageDraw.ImageDraw, lines: int = 3) -> None:
    for i in range(lines):
        y = CENTER - 30 + i * 28
        draw.rectangle((CENTER - 45, y, CENTER + 45, y + 12), fill=ACCENT if i == 0 else MUTED)


def _draw_lightbulb(draw: ImageDraw.ImageDraw) -> None:
    draw.ellipse((CENTER - 30, CENTER - 45, CENTER + 30, CENTER + 15), fill=ACCENT)
    draw.rectangle((CENTER - 15, CENTER + 15, CENTER + 15, CENTER + 45), fill=MUTED)


def _draw_chart(draw: ImageDraw.ImageDraw) -> None:
    draw.line([(CENTER - 50, CENTER + 30), (CENTER - 15, CENTER), (CENTER + 20, CENTER + 10), (CENTER + 50, CENTER - 40)], fill=ACCENT, width=6)


def _draw_shield(draw: ImageDraw.ImageDraw) -> None:
    draw.polygon([(CENTER, CENTER - 50), (CENTER + 45, CENTER - 20), (CENTER + 35, CENTER + 45), (CENTER, CENTER + 60), (CENTER - 35, CENTER + 45), (CENTER - 45, CENTER - 20)], fill=ACCENT)


def _draw_replay(draw: ImageDraw.ImageDraw) -> None:
    draw.arc((CENTER - 40, CENTER - 40, CENTER + 40, CENTER + 40), 45, 300, fill=ACCENT, width=8)
    draw.polygon([(CENTER - 45, CENTER - 20), (CENTER - 20, CENTER - 45), (CENTER - 20, CENTER + 5)], fill=ACCENT)


GENERAL_DRAWERS = {
    "first_workout": _draw_dumbbell_icon,
    "week_streak_4": lambda d: _draw_flame(d, 1),
    "week_streak_8": lambda d: _draw_flame(d, 2),
    "week_streak_12": lambda d: _draw_flame(d, 3),
    "days_30": lambda d: _draw_calendar(d, 6),
    "days_100": lambda d: _draw_calendar(d, 9),
    "year_1": lambda d: d.ellipse((CENTER - 35, CENTER - 35, CENTER + 35, CENTER + 35), fill=ACCENT),
    "sessions_10": _draw_dumbbell_icon,
    "sessions_50": _draw_trophy,
    "sessions_100": _draw_shield,
    "sets_500": lambda d: (_barbell(d, CENTER, CENTER - 20, 80), _barbell(d, CENTER, CENTER + 30, 80)),
    "sets_2000": lambda d: [_barbell(d, CENTER, CENTER - 40 + i * 35, 70) for i in range(3)],
    "volume_10t": _draw_scale,
    "volume_50t": lambda d: (_draw_scale(d), _barbell(d, CENTER, CENTER - 50, 90)),
    "long_session_90": lambda d: (d.ellipse((CENTER - 45, CENTER - 45, CENTER + 45, CENTER + 45), outline=ACCENT, width=6), d.line((CENTER, CENTER, CENTER, CENTER - 25), fill=ACCENT, width=5), d.line((CENTER, CENTER, CENTER + 20, CENTER + 10), fill=ACCENT, width=5)),
    "first_pr": _draw_arrow_up,
    "pr_5_exercises": lambda d: (_draw_trophy(d), _draw_chart(d)),
    "pr_big3": _draw_trophy,
    "progress_10pct": _draw_chart,
    "body_first_entry": lambda d: (d.rectangle((CENTER - 50, CENTER + 20, CENTER + 50, CENTER + 30), fill=MUTED), d.rectangle((CENTER - 6, CENTER - 50, CENTER + 6, CENTER + 20), fill=ACCENT)),
    "body_5_entries": _draw_scale,
    "body_photo": _draw_camera,
    "body_3_photos": _draw_camera,
    "routine_first": lambda d: _draw_list(d, 1),
    "routine_5": lambda d: _draw_list(d, 5),
    "exercises_20": lambda d: d.ellipse((CENTER - 40, CENTER - 40, CENTER + 40, CENTER + 40), outline=ACCENT, width=6),
    "exercises_50": lambda d: (d.ellipse((CENTER - 45, CENTER - 45, CENTER + 45, CENTER + 45), outline=ACCENT, width=5), d.line((CENTER, CENTER - 45, CENTER, CENTER + 45), fill=ACCENT, width=4), d.line((CENTER - 45, CENTER, CENTER + 45, CENTER), fill=ACCENT, width=4)),
    "custom_exercise": _draw_lightbulb,
    "onboarding_done": _draw_check,
    "profile_photo": _draw_avatar,
    "night_owl": _draw_moon,
    "early_bird": _draw_sun,
    "weekend_warrior": lambda d: _draw_calendar(d, 2),
    "full_body_week": lambda d: d.ellipse((CENTER - 35, CENTER - 35, CENTER + 35, CENTER + 35), fill=ACCENT),
    "rpe_tracker": _draw_chart,
    "comeback": _draw_replay,
}


def render_strength_base(exercise_key: str) -> Image.Image:
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    STRENGTH_DRAWERS.get(exercise_key, _draw_dumbbell_icon)(draw)
    return img


def render_general(slug: str) -> Image.Image:
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    GENERAL_DRAWERS.get(slug, _draw_dumbbell_icon)(draw)
    return img


def render_all_bases(strength_bases_dir: Path) -> int:
    strength_bases_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    seen: set[str] = set()
    for entry in achievement_catalog_entries():
        if entry["category"] != "strength":
            continue
        key = entry["criteria"]["exercise_key"]
        if key in seen:
            continue
        seen.add(key)
        path = strength_bases_dir / f"{key}.png"
        render_strength_base(key).save(path, optimize=True)
        count += 1
        print(f"  base: {path.name}")
    return count


def render_all_generals(general_export_dir: Path) -> int:
    general_export_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for entry in achievement_catalog_entries():
        if entry["category"] == "strength":
            continue
        slug = entry["slug"]
        path = general_export_dir / f"{slug}.png"
        render_general(slug).save(path, optimize=True)
        count += 1
        print(f"  general: {path.name}")
    return count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=str, default=None)
    args = parser.parse_args()
    build_dir = resolve_build_dir(args.build_dir)
    strength_bases_dir, general_export_dir = _configure(build_dir)

    print(f"Build dir: {build_dir}")
    print("Rendering strength bases...")
    bases = render_all_bases(strength_bases_dir)
    print(f"Rendered {bases} strength bases.")
    print("Rendering general badges...")
    generals = render_all_generals(general_export_dir)
    print(f"Rendered {generals} general badges.")


if __name__ == "__main__":
    main()
