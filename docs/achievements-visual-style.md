# Heft — Achievement Design System

## Almacenamiento (producción)

Las insignias **no viven en el repositorio**. Flujo:

1. **Build temporal** (opcional, local): `.achievement_build/` — gitignored
2. **Supabase Storage**: bucket `achievements` (público, cacheable)
3. **PostgreSQL**: solo la ruta en `Achievement.image` + metadatos del catálogo

```text
tools/achievements/generate_all.py   →  .achievement_build/export/{slug}.png
python manage.py upload_achievement_images  →  Supabase + Achievement.image
GET /api/achievements/  →  image_url (URL pública Supabase)
```

### Variables de entorno

```env
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
SUPABASE_ACHIEVEMENTS_BUCKET=achievements
SUPABASE_ACHIEVEMENTS_BUCKET_PUBLIC=True
```

Crear el bucket `achievements` en Supabase Dashboard (público recomendado).

### Comandos

```bash
# Generar PNG localmente (temporal)
python tools/achievements/generate_all.py

# Subir a Supabase desde .achievement_build/export/
cd backend && python manage.py upload_achievement_images

# Generar, subir y borrar temporal en un paso
cd backend && python manage.py upload_achievement_images --generate
```

## Especificaciones visuales

| Regla | Valor |
|-------|-------|
| Tamaño | 512×512 px PNG |
| Zona segura | Círculo ~400 px central |
| Acento | `#E2F163` |
| Fondo | `#1A1A1A` o transparente |
| Tiers | Bronce `#CD7F32`, Plata `#B8B8B8`, Oro `#FFD54F` |
| Sin texto | en la imagen |

Catálogo de prompts: [achievements-catalog.csv](achievements-catalog.csv)

## Sustituir arte generado

1. Coloca PNG nombrados `{slug}.png` en cualquier carpeta.
2. `python manage.py upload_achievement_images --source-dir /ruta/a/png`
3. Los archivos se suben a Supabase; no hace falta commitearlos.
