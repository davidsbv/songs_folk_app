-- Migracion opcional de letras antiguas (songs -> coplas).
-- Ejecutar solo cuando quieras poblar coplas desde songs.
-- Requiere tipos/subtipos ya cargados en copla_types/copla_subtypes.

begin;

insert into public.coplas (copla_type_id, copla_subtype_id, text, author, updated_at)
select
  ct.id as copla_type_id,
  cs.id as copla_subtype_id,
  s.lyrics_text as text,
  nullif(trim(s.author), '') as author,
  coalesce(s.updated_at, now()) as updated_at
from public.songs s
join public.song_types st on st.id = s.song_type_id
join public.copla_types ct on ct.name = st.name
join public.copla_subtypes cs
  on cs.copla_type_id = ct.id
 and cs.name = s.subtype
where s.lyrics_text is not null
  and trim(s.lyrics_text) <> ''
  and not exists (
    select 1
    from public.coplas c
    where c.text = s.lyrics_text
      and coalesce(c.author, '') = coalesce(nullif(trim(s.author), ''), '')
      and c.copla_type_id = ct.id
      and c.copla_subtype_id = cs.id
  );

commit;
