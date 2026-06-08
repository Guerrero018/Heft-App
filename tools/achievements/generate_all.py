#!/usr/bin/env python
"""Pipeline local temporal: render → tiers → validate (sin commitear PNG)."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

TOOLS = Path(__file__).resolve().parent


def run(script: str, build_dir: str | None) -> None:
    path = TOOLS / script
    cmd = [sys.executable, str(path)]
    if build_dir:
        cmd.extend(["--build-dir", build_dir])
    print(f"\n=== {script} ===")
    subprocess.check_call(cmd)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=str, default=None)
    args = parser.parse_args()

    run("export_catalog_csv.py", args.build_dir)
    run("render_badges.py", args.build_dir)
    run("apply_tiers.py", args.build_dir)
    exit_code = subprocess.call(
        [sys.executable, str(TOOLS / "validate_badges.py")]
        + (["--build-dir", args.build_dir] if args.build_dir else [])
    )
    if exit_code != 0:
        raise SystemExit(exit_code)
    print("\nBuild complete. Upload with: python manage.py upload_achievement_images")


if __name__ == "__main__":
    main()
