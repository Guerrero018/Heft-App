#!/usr/bin/env python
"""Valida PNG en .achievement_build/export y genera previews QA."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
TOOLS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BACKEND))
sys.path.insert(0, str(TOOLS_DIR))

from apps.achievements.catalog import achievement_catalog_entries  # noqa: E402
from paths import export_dir, qa_dir, resolve_build_dir  # noqa: E402

MAX_BYTES = 80 * 1024
EXPECTED_SIZE = (512, 512)
PREVIEW_SIZES = (48, 80)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=str, default=None)
    args = parser.parse_args()
    build_dir = resolve_build_dir(args.build_dir)
    export = export_dir(build_dir)
    qa = qa_dir(build_dir)
    qa.mkdir(parents=True, exist_ok=True)

    errors: list[str] = []
    ok = 0

    for entry in achievement_catalog_entries():
        slug = entry["slug"]
        path = export / f"{slug}.png"
        if not path.exists():
            errors.append(f"MISSING: {slug}.png")
            continue

        size_bytes = path.stat().st_size
        if size_bytes > MAX_BYTES:
            errors.append(f"OVERSIZE ({size_bytes} B): {slug}.png")

        with Image.open(path) as img:
            if img.size != EXPECTED_SIZE:
                errors.append(f"BAD_SIZE {img.size}: {slug}.png")
            for preview in PREVIEW_SIZES:
                preview_img = img.resize((preview, preview), Image.Resampling.LANCZOS)
                preview_img.save(qa / f"{slug}_{preview}px.png", optimize=True)
        ok += 1

    print(f"Validated {ok}/75 badges in {export}")
    if errors:
        print(f"Errors ({len(errors)}):")
        for err in errors:
            print(f"  - {err}")
        return 1

    print(f"QA previews saved to {qa}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
