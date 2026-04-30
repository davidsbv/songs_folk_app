-- Esquema de Eventos (calendario) para Supabase.
-- Ejecutar una vez por entorno en SQL Editor.

begin;

create extension if not exists pgcrypto;

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  start_at timestamptz not null,
  end_at timestamptz not null,
  all_day boolean not null default false,
  location text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- Evita rangos invalidos.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'events_end_after_start_chk'
  ) then
    alter table public.events
      add constraint events_end_after_start_chk
      check (end_at >= start_at);
  end if;
end $$;

create index if not exists idx_events_start_at on public.events(start_at);
create index if not exists idx_events_end_at on public.events(end_at);
create index if not exists idx_events_deleted_at on public.events(deleted_at);

create or replace function public.set_updated_at_events()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_events_updated_at on public.events;
create trigger trg_events_updated_at
before update on public.events
for each row execute function public.set_updated_at_events();

-- Acceso para app publica (lectura de eventos no eliminados).
grant usage on schema public to anon, authenticated;
grant select on table public.events to anon, authenticated;

-- Escritura desde panel admin autenticado.
grant insert, update, delete on table public.events to authenticated;
grant select on table public.admin_users to authenticated;

alter table public.events enable row level security;

drop policy if exists "read events public" on public.events;
create policy "read events public"
on public.events for select to anon, authenticated
using (deleted_at is null);

drop policy if exists "insert events admin only" on public.events;
create policy "insert events admin only"
on public.events for insert to authenticated
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "update events admin only" on public.events;
create policy "update events admin only"
on public.events for update to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- Opcionalmente podrías quitar esta policy si prefieres solo soft-delete por update(deleted_at).
drop policy if exists "delete events admin only" on public.events;
create policy "delete events admin only"
on public.events for delete to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

commit;
