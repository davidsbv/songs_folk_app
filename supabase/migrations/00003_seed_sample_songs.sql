-- Canciones de ejemplo (las mismas que en SampleSongsService).
-- Ejecutar después de 00002_seed_catalogs.sql.
-- Usa los UUID fijos de song_types e instruments de la migración anterior.

INSERT INTO songs (id, title, author, song_type_id, subtype, lyrics_text, lyrics_pdf_path, lyrics_image_path)
SELECT
  'c1000001-0001-4000-8000-000000000001',
  'Mayo a La Virgen de La Antigua',
  'Diego Pérez Pezuela',
  st.id,
  'RELIGIOSAS',
  NULL,
  'https://drive.google.com/file/d/1J7_IboqVB84boJs1VM7_SYi-IGl08LCs/view?usp=drivesdk',
  NULL
FROM song_types st WHERE st.name = 'JOTA'
ON CONFLICT (id) DO NOTHING;

INSERT INTO songs (id, title, author, song_type_id, subtype, lyrics_text, lyrics_pdf_path, lyrics_image_path)
SELECT
  'c1000001-0001-4000-8000-000000000002',
  'Guiño al Señorío',
  'Diego Pérez Pezuela',
  st.id,
  'SEGUIDILLAS A LOS PUEBLOS',
  'Letra de ejemplo para "Guiño al Señorío".\nAquí iría la letra en texto.\nMás adelante también PDF o imagen.',
  NULL,
  NULL
FROM song_types st WHERE st.name = 'SEGUIDILLA'
ON CONFLICT (id) DO NOTHING;

INSERT INTO songs (id, title, author, song_type_id, subtype, lyrics_text, lyrics_pdf_path, lyrics_image_path)
SELECT
  'c1000001-0001-4000-8000-000000000003',
  'Pasacalles De La Plaza',
  'Anónimo',
  st.id,
  'A LAS FIESTAS',
  'Letra de ejemplo para "Pasacalles De La Plaza".',
  NULL,
  NULL
FROM song_types st WHERE st.name = 'JOTA'
ON CONFLICT (id) DO NOTHING;

INSERT INTO songs (id, title, author, song_type_id, subtype, lyrics_text, lyrics_pdf_path, lyrics_image_path)
SELECT
  'c1000001-0001-4000-8000-000000000004',
  'Vals del Río',
  'Anónimo',
  st.id,
  'VARIAS',
  'Letra de ejemplo del "Vals del Río".',
  NULL,
  NULL
FROM song_types st WHERE st.name = 'JOTA'
ON CONFLICT (id) DO NOTHING;

INSERT INTO songs (id, title, author, song_type_id, subtype, lyrics_text, lyrics_pdf_path, lyrics_image_path)
SELECT
  'c1000001-0001-4000-8000-000000000005',
  'Fandango Serrano',
  'Anónimo',
  st.id,
  'VARIAS',
  'Letra de ejemplo para "Fandango Serrano".',
  NULL,
  NULL
FROM song_types st WHERE st.name = 'JOTA'
ON CONFLICT (id) DO NOTHING;

-- Scores: Mayo a La Virgen -> DULZAINA
INSERT INTO scores (song_id, instrument_id)
SELECT s.id, i.id FROM songs s CROSS JOIN instruments i
WHERE s.title = 'Mayo a La Virgen de La Antigua' AND i.name = 'DULZAINA'
ON CONFLICT (song_id, instrument_id) DO NOTHING;

-- Guiño al Señorío -> DULZAINA
INSERT INTO scores (song_id, instrument_id)
SELECT s.id, i.id FROM songs s CROSS JOIN instruments i
WHERE s.title = 'Guiño al Señorío' AND i.name = 'DULZAINA'
ON CONFLICT (song_id, instrument_id) DO NOTHING;

-- Pasacalles De La Plaza -> CUERDA (con PDF) y DULZAINA
INSERT INTO scores (song_id, instrument_id, score_pdf_path)
SELECT s.id, i.id, 'https://drive.google.com/file/d/1J7_IboqVB84boJs1VM7_SYi-IGl08LCs/view?usp=drivesdk'
FROM songs s CROSS JOIN instruments i
WHERE s.title = 'Pasacalles De La Plaza' AND i.name = 'CUERDA'
ON CONFLICT (song_id, instrument_id) DO UPDATE SET score_pdf_path = EXCLUDED.score_pdf_path;

INSERT INTO scores (song_id, instrument_id)
SELECT s.id, i.id FROM songs s CROSS JOIN instruments i
WHERE s.title = 'Pasacalles De La Plaza' AND i.name = 'DULZAINA'
ON CONFLICT (song_id, instrument_id) DO NOTHING;

-- Vals del Río -> CUERDA (imagen)
INSERT INTO scores (song_id, instrument_id, score_image_path)
SELECT s.id, i.id, 'https://media.istockphoto.com/id/867870340/es/foto/abstracto-fondo-de-texto.jpg?s=612x612&w=is&k=20&c=nKMzbc5elJsbbtY7Teg0nWFaSpJuho1A7cE4idIwX2M='
FROM songs s CROSS JOIN instruments i
WHERE s.title = 'Vals del Río' AND i.name = 'CUERDA'
ON CONFLICT (song_id, instrument_id) DO UPDATE SET score_image_path = EXCLUDED.score_image_path;

-- Fandango Serrano -> CUERDA (imagen)
INSERT INTO scores (song_id, instrument_id, score_image_path)
SELECT s.id, i.id, 'https://media.istockphoto.com/id/1361321670/es/vector/borde-abstracto-del-adorno-del-alfabeto-negro-aislado-sobre-fondo-blanco-ilustraci%C3%B3n.jpg?s=612x612&w=0&k=20&c=Io5c4c-7ddt4ZxtHJvdZH43zenvR-iNKPPhRXxDbV1w='
FROM songs s CROSS JOIN instruments i
WHERE s.title = 'Fandango Serrano' AND i.name = 'CUERDA'
ON CONFLICT (song_id, instrument_id) DO UPDATE SET score_image_path = EXCLUDED.score_image_path;
