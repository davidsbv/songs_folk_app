-- Datos iniciales: tipos JOTA/SEGUIDILLA, subtipos de Song, instrumentos.
-- Ejecutar después de 00001_initial_schema.sql.

INSERT INTO song_types (id, name, sort_order) VALUES
  ('a0000001-0001-4000-8000-000000000001', 'JOTA', 1),
  ('a0000001-0001-4000-8000-000000000002', 'SEGUIDILLA', 2)
ON CONFLICT (name) DO NOTHING;

-- Subtipos de Song - JOTA
INSERT INTO song_subtypes (song_type_id, name, sort_order)
SELECT id, unnest(ARRAY[
  'ENTRADAS', 'A LA MUJER', 'CALLES Y PLAZAS', 'ENAMORADOS', 'AUTORIDADES',
  'RELIGIOSAS', 'DE LOS PUEBLOS', 'ENTRE RONDADORES', 'DE ANIMALES', 'ESCATOLÓGICAS',
  'VARIAS', 'DE VENTANA', 'A LA ADOLESCENCIA', 'A LAS FIESTAS', 'A LOS QUINTOS',
  'AL CRISTO', 'A LOS HIJOS', 'A ESTACIONES DEL AÑO', 'JOCOSAS', 'VERDES',
  'PERSONAJES', 'DESPEDIDAS'
]), generate_series(1, 22)
FROM song_types WHERE name = 'JOTA'
ON CONFLICT (song_type_id, name) DO NOTHING;

-- Subtipos de Song - SEGUIDILLA
INSERT INTO song_subtypes (song_type_id, name, sort_order)
SELECT id, unnest(ARRAY[
  'SEGUIDILLAS A LA VIRGEN', 'SEGUIDILLAS A LA MUJER', 'SEGUIDILLAS A LOS PUEBLOS'
]), generate_series(1, 3)
FROM song_types WHERE name = 'SEGUIDILLA'
ON CONFLICT (song_type_id, name) DO NOTHING;

-- Instrumentos (para partituras/tablaturas)
INSERT INTO instruments (id, name, sort_order) VALUES
  ('b0000001-0001-4000-8000-000000000001', 'CUERDA', 1),
  ('b0000001-0001-4000-8000-000000000002', 'DULZAINA', 2)
ON CONFLICT (name) DO NOTHING;

-- Subtipos de Song en Partituras - CUERDA (partituras_catalog.dart: subtypesCuerda)
INSERT INTO partituras_subtypes (instrument_id, name, sort_order)
SELECT id, unnest(ARRAY[
  'DANZAS DE LA HUERCE', 'HABANERAS', 'HIMNOS', 'JOTAS', 'MAYOS', 'MAZURCAS',
  'MISAS', 'NANAS', 'OLIVERAS', 'OTROS', 'PASACALLES Y PASODOBLES', 'PERICONES',
  'ROMANCES', 'SEGADORAS', 'SEGUIDILLAS Y JOTAS', 'VALSES', 'VILLANCICOS'
]), generate_series(1, 17)
FROM instruments WHERE name = 'CUERDA'
ON CONFLICT (instrument_id, name) DO NOTHING;

-- Subtipos de Song en Partituras - DULZAINA (partituras_catalog.dart: subtypesDulzaina)
INSERT INTO partituras_subtypes (instrument_id, name, sort_order)
SELECT id, unnest(ARRAY[
  'CHARRADAS', 'CORRIDOS', 'DANZAS DE GALVE DE SORBE', 'DANZAS DE LA HUERCE',
  'DIANAS', 'HABANERAS', 'HIMNOS', 'JOTAS', 'MARCHAS', 'OTROS',
  'PASACALLES Y PASODOBLES', 'POLLOS', 'RUMBAS', 'TARANTELAS', 'VALSES'
]), generate_series(1, 15)
FROM instruments WHERE name = 'DULZAINA'
ON CONFLICT (instrument_id, name) DO NOTHING;
