# Supabase Setup (songs_folk_app)

Guía rápida para dejar base de datos + storage listos en un entorno nuevo.

## Orden recomendado de ejecución

1. `docs/supabase_coplas_schema.sql`
   - Crea tablas de coplas, trigger `updated_at`, RLS y policies.
2. `docs/supabase_coplas_seed_catalog.sql`
   - Carga tipos/subtipos de coplas (re-ejecutable).
3. `docs/supabase_storage_setup.sql`
   - Crea bucket `songs-assets` y policies de Storage.
4. `docs/supabase_coplas_checks.sql`
   - Verifica tablas, RLS, policies y catálogo.
5. (Opcional) `docs/supabase_coplas_migration_from_songs.sql`
   - Migra letras históricas de `songs` a `coplas`.

## Requisitos previos

- Proyecto Supabase creado.
- En la app:
  - `lib/core/supabase_config.dart` con `supabaseUrl` y `supabaseAnonKey`.
  - `supabaseStorageBucket` con valor `songs-assets` (o el bucket que uses).

## Configuración de usuario admin

El login `/admin` usa Supabase Auth (email/password) y comprobación en `admin_users`.

Pasos:

1. Crear usuario en Authentication (si no existe).
2. Insertar su `user_id` en `public.admin_users`:

```sql
insert into public.admin_users (user_id)
values ('TU-USER-ID')
on conflict (user_id) do nothing;
```

## Comprobaciones mínimas tras setup

Ejecutar:

- `docs/supabase_coplas_checks.sql`
- bloque de checks al final de `docs/supabase_storage_setup.sql`

Y validar en app:

1. Entrar por `/admin` y login.
2. Alta de copla y verificar en Coplero tras sincronizar.
3. Alta/edición de canción.
4. Subida de PDF/imagen desde admin song (Storage).

## Problemas frecuentes

- `403 / row-level security` en coplas:
  - revisar policies de `coplas` y `admin_users`.
- Login admin correcto pero acceso denegado:
  - falta fila en `admin_users`.
- Error al subir archivos:
  - bucket no existe o nombre distinto a `songs-assets`.
  - policies de `storage.objects` faltantes.
- Subida OK pero URL no abre:
  - bucket no público (o falta policy de lectura pública).

## Notas de operación

- Los scripts están pensados para ser re-ejecutables cuando aplica (`seed`, `storage`).
- En `song`, tipo/subtipo pueden quedar sin selección en UI; se guarda subtipo como `SIN CLASIFICAR` cuando corresponda.
