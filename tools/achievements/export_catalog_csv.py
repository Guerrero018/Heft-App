#!/usr/bin/env python
"""Exporta el catálogo de 75 logros a CSV con prompts para producción visual."""

from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
TOOLS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BACKEND))
sys.path.insert(0, str(TOOLS_DIR))

import os  # noqa: E402

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "heft_core.settings")

import django  # noqa: E402

django.setup()

from apps.achievements.catalog import achievement_catalog_entries  # noqa: E402
from prompts import general_prompt, strength_prompt  # noqa: E402

OUTPUT = ROOT / "docs" / "achievements-catalog.csv"


def base_exercise_for(entry: dict) -> str:
    if entry["category"] != "strength":
        return ""
    criteria = entry.get("criteria") or {}
    return str(criteria.get("exercise_key", ""))


def build_prompt(entry: dict) -> str:
    if entry["category"] == "strength":
        criteria = entry.get("criteria") or {}
        return strength_prompt(str(criteria.get("exercise_key", "")))
    return general_prompt(entry["slug"], entry["category"])


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    rows = []
    for entry in achievement_catalog_entries():
        slug = entry["slug"]
        rows.append(
            {
                "slug": slug,
                "title": entry["title"],
                "category": entry["category"],
                "tier": entry.get("tier") or "",
                "base_exercise": base_exercise_for(entry),
                "prompt": build_prompt(entry),
                "status": "pending",
                "filename": f"{slug}.png",
            }
        )

    fieldnames = [
        "slug",
        "title",
        "category",
        "tier",
        "base_exercise",
        "prompt",
        "status",
        "filename",
    ]
    with OUTPUT.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Exported {len(rows)} rows to {OUTPUT}")


if __name__ == "__main__":
    main()
