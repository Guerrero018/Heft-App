from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from django.conf import settings
from django.core.files import File
from django.core.management.base import BaseCommand, CommandError

from apps.achievements.catalog import achievement_catalog_entries
from apps.achievements.models import Achievement
from apps.achievements.storage import ensure_achievements_bucket

ROOT = Path(__file__).resolve().parents[5]
DEFAULT_BUILD_DIR = ROOT / ".achievement_build" / "export"
GENERATE_SCRIPT = ROOT / "tools" / "achievements" / "generate_all.py"


class Command(BaseCommand):
    help = (
        "Sube insignias PNG a Supabase Storage (o media local) y las asigna en Achievement.image. "
        "No requiere carpeta assets/ en el repositorio."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--source-dir",
            type=str,
            default=str(DEFAULT_BUILD_DIR),
            help="Directorio con {slug}.png (por defecto .achievement_build/export).",
        )
        parser.add_argument(
            "--generate",
            action="store_true",
            help="Genera PNG en un directorio temporal, sube y borra el temporal.",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Solo lista qué archivos se subirían.",
        )

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        generate = options["generate"]
        temp_dir: Path | None = None

        if generate:
            temp_dir = Path(tempfile.mkdtemp(prefix="heft_achievements_"))
            source_dir = temp_dir / "export"
            self.stdout.write(f"Generating badges in {temp_dir} ...")
            subprocess.check_call(
                [sys.executable, str(GENERATE_SCRIPT), "--build-dir", str(temp_dir)],
                cwd=str(ROOT),
            )
        else:
            source_dir = Path(options["source_dir"])

        if not source_dir.is_dir():
            raise CommandError(
                f"No existe {source_dir}. Usa --generate o pasa --source-dir con PNG nombrados por slug."
            )

        if settings.USE_SUPABASE_STORAGE:
            if not dry_run:
                try:
                    ensure_achievements_bucket()
                    self.stdout.write(
                        self.style.SUCCESS(
                            f"Bucket '{settings.SUPABASE_ACHIEVEMENTS_BUCKET}' listo en Supabase."
                        )
                    )
                except Exception as exc:
                    raise CommandError(
                        f"No se pudo preparar el bucket '{settings.SUPABASE_ACHIEVEMENTS_BUCKET}' "
                        f"en Supabase: {exc}\n"
                        "Créalo manualmente en Dashboard → Storage → New bucket "
                        f"(nombre: {settings.SUPABASE_ACHIEVEMENTS_BUCKET}, público recomendado)."
                    ) from exc
            self.stdout.write(
                self.style.NOTICE(
                    f"Destino: Supabase bucket '{settings.SUPABASE_ACHIEVEMENTS_BUCKET}' (público="
                    f"{settings.SUPABASE_ACHIEVEMENTS_BUCKET_PUBLIC})"
                )
            )
        else:
            self.stdout.write(
                self.style.WARNING(
                    "Supabase no configurado; las imágenes se guardarán en media local."
                )
            )

        png_index = self._index_pngs(source_dir)
        updated = 0
        missing = 0

        for entry in achievement_catalog_entries():
            slug = entry["slug"]
            path = png_index.get(slug)
            if path is None:
                self.stdout.write(self.style.WARNING(f"Missing PNG for slug: {slug}"))
                missing += 1
                continue

            if dry_run:
                self.stdout.write(f"Would upload {slug} <- {path}")
                updated += 1
                continue

            achievement = Achievement.objects.filter(slug=slug).first()
            if not achievement:
                self.stdout.write(self.style.WARNING(f"No DB row for slug: {slug}"))
                missing += 1
                continue

            with path.open("rb") as f:
                if achievement.image:
                    achievement.image.delete(save=False)
                achievement.image.save(f"{slug}.png", File(f), save=True)

            url = achievement.image.url
            self.stdout.write(f"Uploaded {slug} -> {url}")
            updated += 1

        if temp_dir and temp_dir.exists():
            shutil.rmtree(temp_dir, ignore_errors=True)
            self.stdout.write("Temporary build directory removed.")

        style = self.style.SUCCESS if missing == 0 else self.style.WARNING
        self.stdout.write(style(f"Done: {updated} uploaded, {missing} missing/skipped."))

    def _index_pngs(self, source_dir: Path) -> dict[str, Path]:
        index: dict[str, Path] = {}
        for path in source_dir.rglob("*.png"):
            if path.stem.startswith("."):
                continue
            index[path.stem] = path
        return index
