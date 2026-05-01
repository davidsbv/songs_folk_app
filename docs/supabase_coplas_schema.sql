-- Base schema de Coplas (sin seed de catalogo ni migraciones de datos).
-- Ejecutar una vez por entorno.

begin;

create extension if not exists pgcrypto;

create or replace function public.is_admin(_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users a
    where a.user_id = _uid
  );
$$;

grant execute on function public.is_admin(uuid) to anon, authenticated;

-- Tabla de administradores de la app.
-- Debe contener los UUID de usuarios de Supabase Auth con acceso al panel admin.
create table if not exists admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists copla_types (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  sort_order int default 0
);

create table if not exists copla_subtypes (
  id uuid primary key default gen_random_uuid(),
  copla_type_id uuid not null references copla_types(id) on delete cascade,
  name text not null,
  sort_order int default 0,
  unique (copla_type_id, name)
);

create table if not exists coplas (
  id uuid primary key default gen_random_uuid(),
  copla_type_id uuid not null references copla_types(id),
  copla_subtype_id uuid not null references copla_subtypes(id),
  text text not null,
  author text,
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create or replace function set_updated_at_coplas()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_coplas_updated_at on coplas;
create trigger trg_coplas_updated_at
before update on coplas
for each row execute function set_updated_at_coplas();

-- Permisos de lectura para app publica
grant usage on schema public to anon, authenticated;
grant select on table public.copla_types to anon, authenticated;
grant select on table public.copla_subtypes to anon, authenticated;
grant select on table public.coplas to anon, authenticated;

alter table public.copla_types enable row level security;
alter table public.copla_subtypes enable row level security;
alter table public.coplas enable row level security;

drop policy if exists "read copla_types public" on public.copla_types;
create policy "read copla_types public"
on public.copla_types for select to anon, authenticated using (true);

drop policy if exists "read copla_subtypes public" on public.copla_subtypes;
create policy "read copla_subtypes public"
on public.copla_subtypes for select to anon, authenticated using (true);

drop policy if exists "read coplas public" on public.coplas;
create policy "read coplas public"
on public.coplas for select to anon, authenticated using (true);

-- Escritura admin
grant insert, update, delete on table public.coplas to authenticated;
grant select on table public.admin_users to authenticated;

alter table public.admin_users enable row level security;

drop policy if exists "admin_users read own row" on public.admin_users;
create policy "admin_users read own row"
on public.admin_users for select to authenticated
using (user_id = auth.uid());

drop policy if exists "insert coplas admin only" on public.coplas;
create policy "insert coplas admin only"
on public.coplas for insert to authenticated
with check (public.is_admin(auth.uid()));

drop policy if exists "update coplas admin only" on public.coplas;
create policy "update coplas admin only"
on public.coplas for update to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

drop policy if exists "delete coplas admin only" on public.coplas;
create policy "delete coplas admin only"
on public.coplas for delete to authenticated
using (public.is_admin(auth.uid()));

commit;
