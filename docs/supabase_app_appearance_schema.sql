-- Apariencia global de la app (lectura publica, escritura solo admins).
-- El modo claro/oscuro por usuario se guarda en el dispositivo (Flutter), no aqui.
-- Ejecutar en SQL Editor (tras tener ya `admin_users` y, si aplica, `is_admin`).

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

create table if not exists public.app_appearance (
  id int primary key default 1,
  accent_seed_color_hex text,
  scaffold_background_color_hex text,
  font_color_hex text,
  background_image_url text,
  background_overlay_opacity double precision not null default 0.35,
  updated_at timestamptz not null default now(),
  constraint app_appearance_singleton_chk check (id = 1),
  constraint app_appearance_overlay_chk check (
    background_overlay_opacity >= 0 and background_overlay_opacity <= 1
  )
);

alter table public.app_appearance
  add column if not exists font_color_hex text;

create or replace function public.set_updated_at_app_appearance()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_app_appearance_updated_at on public.app_appearance;
create trigger trg_app_appearance_updated_at
before update on public.app_appearance
for each row execute function public.set_updated_at_app_appearance();

insert into public.app_appearance (id)
values (1)
on conflict (id) do nothing;

grant usage on schema public to anon, authenticated;
grant select on table public.app_appearance to anon, authenticated;
grant insert, update on table public.app_appearance to authenticated;
grant select on table public.admin_users to authenticated;

alter table public.app_appearance enable row level security;

drop policy if exists "read app_appearance public" on public.app_appearance;
create policy "read app_appearance public"
on public.app_appearance for select to anon, authenticated
using (true);

drop policy if exists "insert app_appearance admin only" on public.app_appearance;
create policy "insert app_appearance admin only"
on public.app_appearance for insert to authenticated
with check (public.is_admin(auth.uid()));

drop policy if exists "update app_appearance admin only" on public.app_appearance;
create policy "update app_appearance admin only"
on public.app_appearance for update to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

commit;
