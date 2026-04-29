-- Configuracion de Supabase Storage para songs_folk_app.
-- Este script es idempotente y se puede re-ejecutar.
-- Bucket esperado por la app: songs-assets (ver lib/core/supabase_config.dart)

begin;

-- 1) Crear bucket publico si no existe.
insert into storage.buckets (id, name, public)
values ('songs-assets', 'songs-assets', true)
on conflict (id) do update
set public = excluded.public;

-- 2) Limpiar policies previas con el mismo nombre.
drop policy if exists "songs_assets_public_read" on storage.objects;
drop policy if exists "songs_assets_auth_insert" on storage.objects;
drop policy if exists "songs_assets_auth_update" on storage.objects;
drop policy if exists "songs_assets_auth_delete" on storage.objects;

-- 3) Lectura publica para URLs directas (bucket publico).
create policy "songs_assets_public_read"
on storage.objects
for select
to public
using (bucket_id = 'songs-assets');

-- 4) Escritura/borrado para usuarios autenticados.
create policy "songs_assets_auth_insert"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'songs-assets');

create policy "songs_assets_auth_update"
on storage.objects
for update
to authenticated
using (bucket_id = 'songs-assets')
with check (bucket_id = 'songs-assets');

create policy "songs_assets_auth_delete"
on storage.objects
for delete
to authenticated
using (bucket_id = 'songs-assets');

commit;

-- =========================
-- Checks de verificacion
-- =========================

-- A) Bucket creado y publico
select id, name, public, created_at
from storage.buckets
where id = 'songs-assets';

-- B) Policies activas
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
  and policyname like 'songs_assets_%'
order by policyname;
