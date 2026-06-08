#!/usr/bin/env python
"""Aplica marcos bronce/plata/oro y exporta 39 PNG de fuerza a export/{slug}.png."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
TOOLS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BACKEND))
sys.path.insert(0, str(TOOLS_DIR))

from apps.achievements.catalog import achievement_catalog_entries  # noqa: E402
from paths import bases_dir, export_dir, resolve_build_dir  # noqa: E402

SIZE = 512
TIER_COLORS = {"bronze": (205, 127, 50, 255), "silver": (184, 184, 184, 255), "gold": (255, 213, 79, 255)}
TIER_RING_WIDTH = {"bronze": 8, "silver": 12, "gold": 16}


def apply_tier_frame(base: Image.Image, tier: str) -> Image.Image:
    color = TIER_COLORS[tier]
    width = TIER_RING_WIDTH[tier]
    img = base.copy().convert("RGBA")
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    outer = 56
    draw.ellipse((outer, outer, SIZE - outer, SIZE - outer), outline=color, width=width)

    if tier == "silver":
        glow = overlay.filter(ImageFilter.GaussianBlur(2))
        img = Image.alpha_composite(img, glow)
    elif tier == "gold":
        draw.ellipse((70, 70, SIZE - 70, SIZE - 70), outline=(*color[:3], 120), width=4)
        for angle in range(0, 360, 60):
            rad = math.radians(angle)
            cx, cy = SIZE // 2, SIZE // 2
            x1 = cx + int(200 * math.cos(rad))
            y1 = cy + int(200 * math.sin(rad))
            x2 = cx + int(220 * math.cos(rad))
            y2 = cy + int(220 * math.sin(rad))
            draw.line((x1, y1, x2, y2), fill=(*color[:3], 180), width=3)

    return Image.alpha_composite(img, overlay)


def export_strength_tiers(build_dir: Path) -> int:
    strength_bases_dir = bases_dir(build_dir)
    strength_export_dir = export_dir(build_dir)
    strength_export_dir.mkdir(parents=True, exist_ok=True)
    count = 0

    for entry in achievement_catalog_entries():
        if entry["category"] != "strength":
            continue
        slug = entry["slug"]
        tier = entry["tier"]
        exercise_key = entry["criteria"]["exercise_key"]
        base_path = strength_bases_dir / f"{exercise_key}.png"
        if not base_path.exists():
            print(f"  WARN: missing base {base_path.name}, skipping {slug}")
            continue
        base = Image.open(base_path).convert("RGBA")
        result = apply_tier_frame(base, tier) if tier else base
        out = strength_export_dir / f"{slug}.png"
        result.save(out, optimize=True)
        count += 1
        print(f"  tier export: {out.name}")
    return count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=str, default=None)
    args = parser.parse_args()
    build_dir = resolve_build_dir(args.build_dir)
    count = export_strength_tiers(build_dir)
    print(f"Exported {count} strength tier badges to {export_dir(build_dir)}")


if __name__ == "__main__":
    main()
