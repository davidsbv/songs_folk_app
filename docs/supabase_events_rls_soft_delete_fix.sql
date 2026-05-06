-- Corrección RLS para borrado de eventos (calendario admin).
--
-- Síntoma en la app:
--   PostgrestException ... "new row violates row-level security policy for table \"events\""
--
-- Causas habituales:
--
-- 1) UPDATE + RETURNING (PostgREST cuando el cliente usa .select() tras el PATCH):
--    La fila devuelta debe cumplir las políticas SELECT. Si solo existe
--    "read events public" con (deleted_at IS NULL), tras marcar deleted_at la fila ya no
--    es seleccionable → error aunque UPDATE y WITH CHECK sean correctos.
--    Solución A (app): no pedir fila devuelta en el soft-delete (EventsRepository).
--    Solución B (SQL): política SELECT para admins (bloque opcional al final).
--
-- 2) La política FOR UPDATE tiene WITH CHECK que obliga deleted_at IS NULL en la fila resultante.
--
-- Prerrequisitos:
--   - Función public.is_admin(uuid) y tabla public.admin_users (ver supabase_events_schema.sql).
--   - Tu usuario de Supabase Auth debe estar en admin_users (igual que para el login del panel).
--
-- Ejecutar en SQL Editor de Supabase (proyecto correspondiente).

begin;

drop policy if exists "update events admin only" on public.events;

create policy "update events admin only"
on public.events for update to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

-- Borrado físico (fallback de la app si soft-delete no está permitido).
drop policy if exists "delete events admin only" on public.events;

create policy "delete events admin only"
on public.events for delete to authenticated
using (public.is_admin(auth.uid()));

commit;

-- Opcional B: admins pueden SELECT filas con deleted_at no nulo (útil si algún cliente
-- pide .select() tras UPDATE o para herramientas internas).
--
-- begin;
-- drop policy if exists "read events admin all" on public.events;
-- create policy "read events admin all"
-- on public.events for select to authenticated
-- using (public.is_admin(auth.uid()));
-- commit;

-- Opcional: revisar políticas actuales en tu proyecto
-- select policyname, cmd, qual, with_check
-- from pg_policies
-- where schemaname = 'public' and tablename = 'events';
