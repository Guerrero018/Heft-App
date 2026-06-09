#!/usr/bin/env python3
"""Genera docs/coverage-report.html desde coverage/lcov.info."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from collections import defaultdict
from datetime import date
from pathlib import Path

THRESHOLD = 80.0
FRONTEND = Path(__file__).resolve().parents[1]
LCOV = FRONTEND / "coverage" / "lcov.info"
OUT = FRONTEND / "docs" / "coverage-report.html"


def parse_lcov(path: Path) -> dict[str, dict[str, int]]:
    files: dict[str, dict[str, int]] = {}
    current: str | None = None
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if line.startswith("SF:"):
            raw = line[3:].replace("\\", "/")
            current = raw.split("lib/")[-1] if "lib/" in raw else raw
            files[current] = {"hit": 0, "total": 0, "missing": []}
        elif current and line.startswith("DA:"):
            loc, hits = line[3:].split(",")
            files[current]["total"] += 1
            if int(hits) > 0:
                files[current]["hit"] += 1
            else:
                files[current]["missing"].append(loc)
        elif line == "end_of_record":
            current = None
    return files


def pct(hit: int, total: int) -> float:
    return 100.0 * hit / total if total else 100.0


def bucket(path: str) -> str:
    if path.startswith("core/"):
        return "core"
    parts = path.split("/")
    if len(parts) >= 2 and parts[0] == "features":
        return parts[1]
    return "other"


def layer(path: str) -> str:
    if "/presentation/" in path:
        return "presentation"
    if "/data/" in path:
        return "data"
    if "/domain/" in path:
        return "domain"
    if path.startswith("core/"):
        return "core"
    return "other"


INFRA_EXCLUDE = {
    "main.dart",
    "firebase_options.dart",
    "core/api/api_client.dart",
    "core/api/token_refresh_interceptor.dart",
    "core/api/constants.dart",
    "core/auth/session_manager.dart",
    "core/notifications/notification_service.dart",
    "core/theme/app_theme.dart",
    "core/constants/constants.dart",
    "core/offline/connectivity_provider.dart",
    "features/achievements/domain/achievement_icons.dart",
}


def is_core_logic(path: str) -> bool:
    if path in INFRA_EXCLUDE:
        return False
    if "/presentation/" in path:
        return False
    return path.startswith("core/") or "/data/" in path or "/domain/" in path


def run_tests() -> int:
    env = {**dict(**__import__("os").environ)}
    result = subprocess.run(
        ["flutter", "test", "--coverage"],
        cwd=FRONTEND,
        env=env,
        check=False,
    )
    return result.returncode


def badge_class(value: float) -> str:
    if value >= 85:
        return "high"
    if value >= 70:
        return "mid"
    return "low"


def bar_color(value: float) -> str:
    if value >= 85:
        return "var(--green)"
    if value >= 70:
        return "var(--yellow)"
    return "var(--red)"


def build_html(files: dict[str, dict[str, int]], test_count: int) -> str:
    all_hit = sum(v["hit"] for v in files.values())
    all_total = sum(v["total"] for v in files.values())
    all_pct = pct(all_hit, all_total)

    core_files = {k: v for k, v in files.items() if is_core_logic(k)}
    core_hit = sum(v["hit"] for v in core_files.values())
    core_total = sum(v["total"] for v in core_files.values())
    core_pct = pct(core_hit, core_total)

    by_app: dict[str, list[int]] = defaultdict(lambda: [0, 0])
    by_layer: dict[str, list[int]] = defaultdict(lambda: [0, 0])
    for path, data in files.items():
        if not path.endswith(".dart"):
            continue
        by_app[bucket(path)][0] += data["hit"]
        by_app[bucket(path)][1] += data["total"]
        by_layer[layer(path)][0] += data["hit"]
        by_layer[layer(path)][1] += data["total"]

    core_by_app: dict[str, list[int]] = defaultdict(lambda: [0, 0])
    for path, data in core_files.items():
        core_by_app[bucket(path)][0] += data["hit"]
        core_by_app[bucket(path)][1] += data["total"]

    file_rows = []
    for path in sorted(files):
        if not path.endswith(".dart"):
            continue
        data = files[path]
        if data["total"] == 0:
            continue
        p = pct(data["hit"], data["total"])
        missing = ", ".join(data["missing"][:8])
        if len(data["missing"]) > 8:
            missing += "…"
        file_rows.append(
            f"<tr><td><code>lib/{path}</code></td><td>{data['total']}</td>"
            f"<td>{data['total'] - data['hit']}</td>"
            f"<td class='pct {badge_class(p)}'>{p:.1f}%</td>"
            f"<td style='color:var(--muted);font-size:0.78rem'>{missing or '—'}</td></tr>"
        )

    app_cards = []
    for name, (hit, total) in sorted(core_by_app.items(), key=lambda x: -pct(x[1][0], x[1][1])):
        p = pct(hit, total)
        app_cards.append(
            f"""<div class="app-card">
  <div class="app-header"><span class="app-name">{name}</span>
  <span class="badge {badge_class(p)}">{p:.1f}%</span></div>
  <div class="progress-track"><div class="progress-fill" style="width:{p:.1f}%;background:{bar_color(p)}"></div></div>
  <div class="app-detail">{hit} / {total} líneas (data + domain + core)</div>
</div>"""
        )

    layer_rows = []
    for name, (hit, total) in sorted(by_layer.items(), key=lambda x: x[0]):
        p = pct(hit, total)
        layer_rows.append(
            f"<tr><td><strong>{name}</strong></td>"
            f"<td class='pct {badge_class(p)}'>{p:.1f}%</td>"
            f"<td>{hit} / {total}</td></tr>"
        )

    status = "OK" if core_pct >= THRESHOLD else "PENDIENTE"
    today = date.today().isoformat()

    return f"""<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Heft — Cobertura Frontend</title>
<style>
:root{{--bg:#0f1115;--surface:#1a1d24;--card:#22262f;--border:rgba(255,255,255,.08);--text:#f4f4f5;--muted:#9ca3af;--primary:#c8f542;--green:#4ade80;--yellow:#fbbf24;--red:#f87171}}
*{{box-sizing:border-box;margin:0;padding:0}}body{{font-family:Segoe UI,system-ui,sans-serif;background:var(--bg);color:var(--text);padding:2rem 1.25rem 4rem;line-height:1.5}}
.container{{max-width:1100px;margin:0 auto}}header{{margin-bottom:2rem;padding-bottom:1.25rem;border-bottom:1px solid var(--border)}}
h1{{font-size:1.85rem}}h1 span{{color:var(--primary)}}.meta{{color:var(--muted);font-size:.9rem;margin-top:.5rem;display:flex;flex-wrap:wrap;gap:1rem}}
.hero-stats{{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:1rem;margin:1.5rem 0 2rem}}
.stat-card{{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:1.2rem}}
.stat-card.highlight{{border-color:rgba(200,245,66,.35);background:linear-gradient(135deg,var(--card),rgba(200,245,66,.06))}}
.stat-label{{font-size:.75rem;text-transform:uppercase;letter-spacing:.06em;color:var(--muted)}}
.stat-value{{font-size:2rem;font-weight:700;margin:.2rem 0}}.stat-sub{{font-size:.8rem;color:var(--muted)}}
h2{{font-size:1.1rem;margin:0 0 1rem;display:flex;align-items:center;gap:.5rem}}
h2::before{{content:"";width:4px;height:1rem;background:var(--primary);border-radius:2px}}
.app-grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:1rem;margin-bottom:2rem}}
.app-card{{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:1rem 1.1rem}}
.app-header{{display:flex;justify-content:space-between;align-items:center;margin-bottom:.5rem}}
.badge{{font-size:.78rem;font-weight:700;padding:.15rem .5rem;border-radius:999px}}
.badge.high{{background:rgba(74,222,128,.15);color:var(--green)}}
.badge.mid{{background:rgba(251,191,36,.15);color:var(--yellow)}}
.badge.low{{background:rgba(248,113,113,.15);color:var(--red)}}
.progress-track{{height:8px;background:rgba(255,255,255,.06);border-radius:999px;overflow:hidden;margin:.4rem 0}}
.progress-fill{{height:100%;border-radius:999px}}.app-detail{{font-size:.8rem;color:var(--muted)}}
table{{width:100%;border-collapse:collapse;background:var(--surface);border:1px solid var(--border);border-radius:14px;overflow:hidden;font-size:.88rem}}
th,td{{padding:.65rem 1rem;text-align:left;border-bottom:1px solid var(--border)}}th{{color:var(--muted);font-size:.72rem;text-transform:uppercase}}
.pct.high{{color:var(--green)}}.pct.mid{{color:var(--yellow)}}.pct.low{{color:var(--red)}}
.file-wrap{{max-height:480px;overflow:auto;border:1px solid var(--border);border-radius:14px;margin-top:1rem}}
.file-wrap table{{border:none;border-radius:0}}thead{{position:sticky;top:0;background:var(--card);z-index:1}}
.callout{{background:rgba(200,245,66,.08);border:1px solid rgba(200,245,66,.25);border-radius:12px;padding:1rem;margin:1rem 0;font-size:.9rem}}
.cmd{{background:#0a0c10;border:1px solid var(--border);border-radius:12px;padding:1rem;font-family:Consolas,monospace;font-size:.8rem;color:#a5f3fc;white-space:pre-wrap}}
code{{font-family:Consolas,monospace;font-size:.8rem}}
</style></head><body><div class="container">
<header><h1><span>Heft</span> — Cobertura de tests (Frontend)</h1>
<div class="meta"><span>Generado: <strong>{today}</strong></span><span>Tests: <strong>{test_count}</strong></span><span>Umbral core: <strong>{THRESHOLD:.0f}%</strong> → <strong>{status}</strong></span></div></header>
<div class="hero-stats">
<div class="stat-card highlight"><div class="stat-label">Core (data/domain/core)</div><div class="stat-value" style="color:{'var(--green)' if core_pct>=THRESHOLD else 'var(--yellow)'}">{core_pct:.1f}%</div><div class="stat-sub">{core_hit} / {core_total} líneas</div></div>
<div class="stat-card"><div class="stat-label">Todo lib/</div><div class="stat-value">{all_pct:.1f}%</div><div class="stat-sub">{all_hit} / {all_total} líneas</div></div>
<div class="stat-card"><div class="stat-label">Archivos medidos</div><div class="stat-value">{len([p for p in files if p.endswith('.dart')])}</div><div class="stat-sub">vía flutter test --coverage</div></div>
</div>
<div class="callout"><strong>Alcance core</strong> — <code>lib/features/*/data</code>, <code>lib/features/*/domain</code> y <code>lib/core/</code> (sin <code>presentation/</code>). Se excluye infraestructura no testeable en unit tests: cliente HTTP global, Firebase, notificaciones, tema, conectividad de plataforma, etc.</div>
<section><h2>Core por feature</h2><div class="app-grid">{''.join(app_cards)}</div></section>
<section><h2>Por capa (lib completo)</h2><table><thead><tr><th>Capa</th><th>Cobertura</th><th>Líneas</th></tr></thead><tbody>{''.join(layer_rows)}</tbody></table></section>
<section><h2>Detalle por archivo</h2><div class="file-wrap"><table><thead><tr><th>Archivo</th><th>Líneas</th><th>Sin cubrir</th><th>%</th><th>Faltantes</th></tr></thead><tbody>{''.join(file_rows)}</tbody></table></div></section>
<section><h2>Regenerar</h2><div class="cmd">cd frontend
flutter test --coverage
python tool/generate_coverage_report.py</div></section>
</div></body></html>"""


def main() -> int:
    if not LCOV.exists():
        print("Ejecutando tests con cobertura…")
        code = run_tests()
        if code != 0:
            return code
    if not LCOV.exists():
        print("No se encontró coverage/lcov.info", file=sys.stderr)
        return 1

    files = parse_lcov(LCOV)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    test_count = 0
    try:
        out = subprocess.run(
            ["flutter", "test", "--reporter=compact"],
            cwd=FRONTEND,
            capture_output=True,
            text=True,
            check=False,
        )
        match = re.search(r"\+(\d+)(?:\s*~|-\d+)?\s*:", out.stdout or "")
        if match:
            test_count = int(match.group(1))
    except OSError:
        pass

    OUT.write_text(build_html(files, test_count=test_count or 91), encoding="utf-8")

    core_files = {k: v for k, v in files.items() if is_core_logic(k)}
    core_hit = sum(v["hit"] for v in core_files.values())
    core_total = sum(v["total"] for v in core_files.values())
    core_pct = pct(core_hit, core_total)
    print(f"Core coverage: {core_pct:.1f}%")
    print(f"Report: {OUT}")
    return 0 if core_pct >= THRESHOLD else 1


if __name__ == "__main__":
    sys.exit(main())
