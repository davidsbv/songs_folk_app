-- Seed de catalogo de Coplas (tipos y subtipos).
-- Seguro de re-ejecutar (idempotente para tipos y upsert para subtipos).
-- Ejecutar tras: docs/supabase_coplas_schema.sql

begin;

insert into public.copla_types (name, sort_order) values
('JOTA', 1),
('SEGUIDILLA', 2)
on conflict (name) do update
set sort_order = excluded.sort_order;

insert into public.copla_subtypes (copla_type_id, name, sort_order)
select ct.id, v.name, v.sort_order
from public.copla_types ct
join (values
  ('JOTA', 'ENTRADAS', 1),
  ('JOTA', 'A LA MUJER', 2),
  ('JOTA', 'CALLES Y PLAZAS', 3),
  ('JOTA', 'ENAMORADOS', 4),
  ('JOTA', 'AUTORIDADES', 5),
  ('JOTA', 'RELIGIOSAS', 6),
  ('JOTA', 'DE LOS PUEBLOS', 7),
  ('JOTA', 'ENTRE RONDADORES', 8),
  ('JOTA', 'DE ANIMALES', 9),
  ('JOTA', 'ESCATOLÓGICAS', 10),
  ('JOTA', 'VARIAS', 11),
  ('JOTA', 'DE VENTANA', 12),
  ('JOTA', 'A LA ADOLESCENCIA', 13),
  ('JOTA', 'A LAS FIESTAS', 14),
  ('JOTA', 'A LOS QUINTOS', 15),
  ('JOTA', 'AL CRISTO', 16),
  ('JOTA', 'A LOS HIJOS', 17),
  ('JOTA', 'A ESTACIONES DEL AÑO', 18),
  ('JOTA', 'JOCOSAS', 19),
  ('JOTA', 'VERDES', 20),
  ('JOTA', 'PERSONAJES', 21),
  ('JOTA', 'DESPEDIDAS', 22),
  ('SEGUIDILLA', 'SEGUIDILLAS A LA VIRGEN', 1),
  ('SEGUIDILLA', 'SEGUIDILLAS A LA MUJER', 2),
  ('SEGUIDILLA', 'SEGUIDILLAS A LOS PUEBLOS', 3)
) as v(type_name, name, sort_order)
  on ct.name = v.type_name
on conflict (copla_type_id, name) do update
set sort_order = excluded.sort_order;

commit;
