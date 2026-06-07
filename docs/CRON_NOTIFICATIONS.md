# Recordatorios programados sin Celery (cron HTTP)

Para producción en **Render free** (sin Background Workers), un cron externo llama a la API cada hora.

## 1. Variable en Render

En el servicio **web** (y solo ahí hace falta):

```env
CRON_SECRET=genera_una_clave_larga_y_aleatoria
```

Ejemplo (PowerShell):

```powershell
[guid]::NewGuid().ToString() + [guid]::NewGuid().ToString()
```

También necesitas (si envías push):

```env
FIREBASE_CREDENTIALS_JSON={...}
NOTIFICATIONS_ENABLED=true
```

**No** hace falta `CELERY_BROKER_URL` ni Redis para este modo.

## 2. Endpoint

| Método | URL |
|--------|-----|
| `POST` o `GET` | `https://TU-SERVICIO.onrender.com/api/internal/cron/notifications/` |

Cabecera (una de las dos):

```http
Authorization: Bearer TU_CRON_SECRET
```

o

```http
X-Cron-Secret: TU_CRON_SECRET
```

Respuesta OK:

```json
{
  "ok": true,
  "results": {
    "workout_reminder": 0,
    "body_progress": 0,
    "weekly_summary": 0,
    "inactivity": 0
  }
}
```

## 3. cron-job.org (gratis)

1. Cuenta en https://cron-job.org
2. **Create cronjob**
3. **Title:** Heft notifications
4. **URL:** `https://TU-SERVICIO.onrender.com/api/internal/cron/notifications/`
5. **Schedule:** cada hora (`0 * * * *`)
6. **Request method:** POST (o GET)
7. **Headers:**
   - `Authorization` = `Bearer TU_CRON_SECRET`
8. Guardar y activar

## 4. Qué ejecuta cada llamada

El cron externo llama **cada hora** (hora del servidor, irrelevante para el usuario). En cada ejecución el backend comprueba, **por usuario**, su zona IANA (`timezone` en preferencias, sincronizada desde la app):

- Recordatorios de **entrenamiento** (hora + días locales)
- Recordatorios de **medidas corporales** (día y hora locales)
- **Resumen semanal** (día y hora locales)
- Alerta de **inactividad** a las **10:00 hora local** de cada usuario

La app envía la zona del dispositivo (p. ej. `Europe/Madrid`) al abrir o guardar preferencias de notificaciones.

## 4.1 Rotar `CRON_SECRET` (recomendado si se filtró)

1. Genera un valor nuevo (PowerShell):

   ```powershell
   [guid]::NewGuid().ToString() + [guid]::NewGuid().ToString()
   ```

2. En **Render** → servicio web → Environment → actualiza `CRON_SECRET` y guarda (redeploy).
3. En **cron-job.org** → tu job → Headers → `Authorization` = `Bearer NUEVO_SECRETO`.
4. Prueba:

   ```powershell
   curl.exe -X POST "https://TU-SERVICIO.onrender.com/api/internal/cron/notifications/" `
     -H "Authorization: Bearer NUEVO_SECRETO"
   ```

5. Borra el secreto antiguo de capturas, chats y notas.

## 5. Probar a mano

```powershell
curl -X POST "https://TU-SERVICIO.onrender.com/api/internal/cron/notifications/" `
  -H "Authorization: Bearer TU_CRON_SECRET"
```

O desde local contra Render tras desplegar.

## 6. Celery en local (opcional)

Puedes seguir usando worker + beat en tu PC para desarrollo; en producción solo hace falta este cron HTTP.
