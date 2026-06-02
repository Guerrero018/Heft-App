# Configura Firebase para Heft (Android FCM)
# Uso: .\scripts\setup_firebase.ps1
# Opcional: .\scripts\setup_firebase.ps1 -ProjectId "tu-proyecto-firebase"

param(
    [string]$ProjectId = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$frontend = Join-Path $root "frontend"
$jsonPath = Join-Path $frontend "android\app\google-services.json"

Set-Location $frontend

if (-not (Test-Path $jsonPath)) {
    Write-Host ""
    Write-Host "Falta: frontend\android\app\google-services.json" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Abre https://console.firebase.google.com"
    Write-Host "2. Proyecto Heft (nº 945196821861 si usas el mismo de Google Sign-In)"
    Write-Host "3. Añade app Android con package: com.heft.frontend"
    Write-Host "4. Descarga google-services.json en:"
    Write-Host "   $jsonPath"
    Write-Host ""
    if ($ProjectId) {
        Write-Host "Intentando flutterfire configure --project=$ProjectId ..."
        $flutterfire = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin\flutterfire.bat"
        if (Test-Path $flutterfire) {
            & $flutterfire configure --project=$ProjectId --yes --platforms=android
        }
    }
    exit 1
}

Write-Host "Generando lib/firebase_options.dart ..."
dart run tool/generate_firebase_options.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Listo. Reconstruye la app:" -ForegroundColor Green
Write-Host "  cd frontend"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter run"
