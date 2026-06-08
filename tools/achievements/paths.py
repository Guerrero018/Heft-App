"""Rutas de build temporal (no se commitean; destino final = Supabase)."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_BUILD_DIR = ROOT / ".achievement_build"


def resolve_build_dir(value: str | None = None) -> Path:
    return Path(value) if value else DEFAULT_BUILD_DIR


def bases_dir(build_dir: Path) -> Path:
    return build_dir / "_bases"


def export_dir(build_dir: Path) -> Path:
    return build_dir / "export"


def qa_dir(build_dir: Path) -> Path:
    return build_dir / "_qa"
