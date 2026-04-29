-- Checks de verificacion para Coplas (esquema + RLS + catalogo + datos).
-- Solo lectura.

-- 1) Tablas esperadas
select to_regclass('public.copla_types') as copla_types,
       to_regclass('public.copla_subtypes') as copla_subtypes,
       to_regclass('public.coplas') as coplas,
       to_regclass('public.admin_users') as admin_users;

-- 2) RLS habilitado
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('copla_types', 'copla_subtypes', 'coplas', 'admin_users')
order by tablename;

-- 3) Policies activas
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
  and tablename in ('copla_types', 'copla_subtypes', 'coplas', 'admin_users')
order by tablename, policyname;

-- 4) Catalogo cargado
select * from public.copla_types order by sort_order, name;

select ct.name as tipo, cs.name as subtipo, cs.sort_order
from public.copla_subtypes cs
join public.copla_types ct on ct.id = cs.copla_type_id
order by ct.sort_order, cs.sort_order, cs.name;

-- 5) Conteo de coplas por tipo/subtipo
select ct.name as tipo, cs.name as subtipo, count(*) as total
from public.coplas c
join public.copla_types ct on ct.id = c.copla_type_id
join public.copla_subtypes cs on cs.id = c.copla_subtype_id
where c.deleted_at is null
group by ct.name, cs.name
order by ct.name, cs.name;
