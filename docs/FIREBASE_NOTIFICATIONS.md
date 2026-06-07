# Firebase / notificaciones push (Heft)

## Resumen

La app usa **Firebase Cloud Messaging (FCM)**. En Android hace falta:

1. `frontend/android/app/google-services.json` (desde Firebase Console)
2. `frontend/lib/firebase_options.dart` (generado automáticamente)
3. Permiso **POST_NOTIFICATIONS** en el móvil (Android 13+)

## Paso 1 — Firebase Console

### Android

1. Abre [Firebase Console](https://console.firebase.google.com).
2. Usa el mismo proyecto que Google Sign-In (número de proyecto **945196821861**) o crea uno nuevo.
3. **Añadir app** → **Android**
4. Package name: `com.heft.frontend`
5. Descarga **`google-services.json`**

### iOS (push en iPhone)

1. En el mismo proyecto Firebase: **Añadir app** → **iOS**
2. Bundle ID: `com.heft.frontend`
3. Descarga **`GoogleService-Info.plist`**
4. Cópialo en:

   ```
   frontend/ios/Runner/GoogleService-Info.plist
   ```

5. Abre `frontend/ios/Runner.xcworkspace` en Xcode → target **Runner** → **Signing & Capabilities** → **+ Capability** → **Push Notifications** (y **Background Modes** → Remote notifications si no aparece solo; el `Info.plist` ya incluye `remote-notification`).
6. Sube la **APNs key** (.p8) en Firebase → Project settings → Cloud Messaging → Apple app configuration.

## Paso 2 — Colocar el archivo

Copia el JSON aquí:

```
frontend/android/app/google-services.json
```

## Paso 3 — Generar `firebase_options.dart`

Desde la carpeta `frontend/`:

```powershell
dart run tool/generate_firebase_options.dart
```

O desde la raíz del repo:

```powershell
.\scripts\setup_firebase.ps1
```

Esto actualiza `lib/firebase_options.dart` con `isConfigured = true` y las claves de tu proyecto.

### Alternativa: FlutterFire CLI

Si tienes sesión en Firebase CLI:

```powershell
dart pub global activate flutterfire_cli
cd frontend
flutterfire configure --project=TU_PROJECT_ID --yes --platforms=android
```

(Sustituye `TU_PROJECT_ID` por el id del proyecto, p. ej. `heft-xxxxx` en la consola.)

## Paso 4 — Reconstruir la app

```powershell
cd frontend
flutter clean
flutter pub get
flutter run
```

## Builds release (API de producción)

En **release** la app carga `frontend/.env.production` (no `.env`):

```env
API_BASE_URL=https://heft-backend-ywi0.onrender.com/api/
```

Desde la raíz del repo:

```powershell
.\scripts\build_release.ps1           # APK release
.\scripts\build_release.ps1 -AppBundle  # AAB Play Store
```

O manualmente: `cd frontend` → `flutter build apk --release`.

## Paso 5 — Activar permisos en el móvil

En la app: **Perfil → Ajustes → Notificaciones → Activar permisos**.

En Android 13+ el sistema mostrará el diálogo de notificaciones.

## Recordatorios automáticos sin Celery (Render free)

Si no usas Background Workers en Render, configura **cron HTTP**:

→ Guía completa: [docs/CRON_NOTIFICATIONS.md](CRON_NOTIFICATIONS.md)

## Backend (push desde servidor)

En el backend (Render / `.env`) configura:

**Opción A (recomendada en local):** guarda el JSON descargado como `backend/firebase-credentials.json` y en `.env`:

```env
FIREBASE_CREDENTIALS_FILE=firebase-credentials.json
```

**Opción B (Render):** una sola línea en la variable de entorno:

```env
FIREBASE_CREDENTIALS_JSON={"type":"service_account",...}
```

No pegues JSON con varias líneas en `.env` — `python-dotenv` fallará.

Descarga la clave en Firebase → Project settings → Service accounts → Generate new private key.

## Comprobar que funciona

1. Login en la app.
2. En logs de Flutter deberías ver `FCM token: ...`.
3. En backend, el token se registra en `POST /api/notifications/devices/`.

## Archivos del repo

| Archivo | Descripción |
|---------|-------------|
| `frontend/android/app/google-services.json` | **No incluido** — lo añades tú (por proyecto) |
| `frontend/ios/Runner/GoogleService-Info.plist` | **No incluido** — iOS (mismo proyecto Firebase) |
| `frontend/.env.production` | API Render en builds `--release` |
| `frontend/lib/firebase_options.dart` | Generado por `tool/generate_firebase_options.dart` |
| `scripts/build_release.ps1` | APK / App Bundle release |
| `frontend/tool/generate_firebase_options.dart` | Script generador |
| `scripts/setup_firebase.ps1` | Script de ayuda Windows |
