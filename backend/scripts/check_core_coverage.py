#!/usr/bin/env python
"""Verifica cobertura >= 80% en apps core (workouts, routines, exercises, statistics)."""
from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

THRESHOLD = 80.0
CORE_PATTERNS = (
    "apps/workouts/*",
    "apps/routines/*",
    "apps/exercises/*",
    "apps/statistics/*",
)


def main() -> int:
    backend = Path(__file__).resolve().parents[1]
    include = ",".join(CORE_PATTERNS)

    test_env = {**os.environ, "DJANGO_SETTINGS_MODULE": "heft_core.settings_test"}
    run = subprocess.run(
        [
            sys.executable,
            "-m",
            "coverage",
            "run",
            "--source=apps/workouts,apps/routines,apps/exercises,apps/statistics",
            "manage.py",
            "test",
            "apps.workouts",
            "apps.routines",
            "apps.exercises",
            "apps.statistics",
            "-v",
            "0",
        ],
        cwd=backend,
        env=test_env,
        capture_output=True,
        text=True,
        check=False,
    )
    if run.returncode != 0:
        print(run.stdout)
        print(run.stderr)
        return run.returncode

    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "coverage",
            "report",
            f"--include={include}",
            "--omit=*/migrations/*,*/tests.py",
        ],
        cwd=backend,
        capture_output=True,
        text=True,
        check=False,
    )
    output = result.stdout + result.stderr
    print(output)

    failures: list[str] = []
    for line in output.splitlines():
        match = re.match(r"^(apps/\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%", line)
        if not match:
            continue
        module, percent_str = match.group(1), match.group(5)
        percent = float(percent_str)
        if percent < THRESHOLD:
            failures.append(f"{module} ({percent}%)")

    total_match = re.search(r"^TOTAL\s+\d+\s+\d+\s+\d+\s+(\d+)%", output, re.MULTILINE)
    if total_match:
        total = float(total_match.group(1))
        print(f"\nTotal core: {total}% (umbral {THRESHOLD:.0f}%)")

    if failures:
        print("\nPor debajo del umbral:")
        for item in failures:
            print(f"  - {item}")
        return 1

    if result.returncode not in (0, 1):
        return result.returncode

    print("\nApps core cumplen el umbral.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
