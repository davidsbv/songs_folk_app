-- Añadir tipo OTRO para songs y migrar registros legacy.
-- Ejecutar en Supabase SQL Editor.

begin;

-- 1) Garantiza que exista OTRO en song_types.
insert into public.song_types (name, sort_order)
select 'OTRO', coalesce(max(sort_order), 0) + 1
from public.song_types
where not exists (
  select 1 from public.song_types where name = 'OTRO'
)
group by 1;

-- 2) Reasigna songs con type no existente/legacy hacia OTRO.
-- Nota: songs guarda FK song_type_id, así que normalizamos por id.
update public.songs s
set song_type_id = st_otro.id
from public.song_types st_otro
where st_otro.name = 'OTRO'
  and not exists (
    select 1
    from public.song_types st
    where st.id = s.song_type_id
  );

commit;

-- Checks
select id, name, sort_order
from public.song_types
order by sort_order, name;
