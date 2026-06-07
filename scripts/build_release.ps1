# Build release de Heft apuntando a la API de producción (Render).
# Usa frontend/.env.production (cargado automáticamente en kReleaseMode).
#
# Uso:
#   .\scripts\build_release.ps1              # APK debuggable release
#   .\scripts\build_release.ps1 -AppBundle   # AAB para Play Store

param(
    [switch]$AppBundle
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$frontend = Join-Path $root "frontend"
$prodEnv = Join-Path $frontend ".env.production"

if (-not (Test-Path $prodEnv)) {
    Write-Host "Falta $prodEnv" -ForegroundColor Red
    exit 1
}

Set-Location $frontend
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($AppBundle) {
    Write-Host "Building app bundle (release) → API de producción" -ForegroundColor Cyan
    flutter build appbundle --release
} else {
    Write-Host "Building APK (release) → API de producción" -ForegroundColor Cyan
    flutter build apk --release
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Listo. La app en release usa:" -ForegroundColor Green
    Get-Content $prodEnv | Where-Object { $_ -match 'API_BASE_URL' }
}
