-- Esquema inicial: tipos y subtipos de Song, instrumentos, canciones y partituras.
-- Ejecutar en el SQL Editor del proyecto Supabase (Dashboard → SQL Editor).
-- Tipo y subtipo de la app son solo los de Song. Dos catálogos de subtipos:
--   song_subtypes = por tipo (Coplero: JOTA/SEGUIDILLA).
--   partituras_subtypes = opciones de subtipo en Partituras según instrumento (Cuerda/Dulzaina).

-- Tipos de canción (JOTA, SEGUIDILLA)
CREATE TABLE IF NOT EXISTS song_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  sort_order int NOT NULL DEFAULT 0
);

-- Subtipos de Song por tipo (Coplero: RELIGIOSAS, VARIAS, etc.)
CREATE TABLE IF NOT EXISTS song_subtypes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  song_type_id uuid NOT NULL REFERENCES song_types(id) ON DELETE CASCADE,
  name text NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  UNIQUE(song_type_id, name)
);

-- Instrumentos para las partituras (CUERDA, DULZAINA)
CREATE TABLE IF NOT EXISTS instruments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  sort_order int NOT NULL DEFAULT 0
);

-- Opciones de subtipo de Song en la pantalla Partituras, según instrumento (Cuerda/Dulzaina).
-- Son los mismos subtipos de Song; solo cambia qué opciones se muestran en el desplegable.
CREATE TABLE IF NOT EXISTS partituras_subtypes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instrument_id uuid NOT NULL REFERENCES instruments(id) ON DELETE CASCADE,
  name text NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  UNIQUE(instrument_id, name)
);

-- Canciones
CREATE TABLE IF NOT EXISTS songs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  author text NOT NULL DEFAULT '',
  song_type_id uuid NOT NULL REFERENCES song_types(id) ON DELETE RESTRICT,
  subtype text NOT NULL DEFAULT '',
  lyrics_text text,
  lyrics_pdf_path text,
  lyrics_image_path text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Partituras/tablaturas por canción e instrumento
CREATE TABLE IF NOT EXISTS scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  song_id uuid NOT NULL REFERENCES songs(id) ON DELETE CASCADE,
  instrument_id uuid NOT NULL REFERENCES instruments(id) ON DELETE RESTRICT,
  score_pdf_path text,
  score_image_path text,
  tab_pdf_path text,
  tab_image_path text,
  UNIQUE(song_id, instrument_id)
);

-- Índices para filtros y listados
CREATE INDEX IF NOT EXISTS idx_songs_song_type ON songs(song_type_id);
CREATE INDEX IF NOT EXISTS idx_songs_subtype ON songs(subtype);
CREATE INDEX IF NOT EXISTS idx_scores_song ON scores(song_id);
CREATE INDEX IF NOT EXISTS idx_scores_instrument ON scores(instrument_id);

-- Políticas RLS: lectura pública. Escritura la restringiremos después con Auth.
ALTER TABLE song_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE song_subtypes ENABLE ROW LEVEL SECURITY;
ALTER TABLE instruments ENABLE ROW LEVEL SECURITY;
ALTER TABLE partituras_subtypes ENABLE ROW LEVEL SECURITY;
ALTER TABLE songs ENABLE ROW LEVEL SECURITY;
ALTER TABLE scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lectura pública song_types" ON song_types FOR SELECT USING (true);
CREATE POLICY "Lectura pública song_subtypes" ON song_subtypes FOR SELECT USING (true);
CREATE POLICY "Lectura pública instruments" ON instruments FOR SELECT USING (true);
CREATE POLICY "Lectura pública partituras_subtypes" ON partituras_subtypes FOR SELECT USING (true);
CREATE POLICY "Lectura pública songs" ON songs FOR SELECT USING (true);
CREATE POLICY "Lectura pública scores" ON scores FOR SELECT USING (true);

-- Escritura (más adelante restringir a admin)
CREATE POLICY "Inserción songs" ON songs FOR INSERT WITH CHECK (true);
CREATE POLICY "Actualización songs" ON songs FOR UPDATE USING (true);
CREATE POLICY "Borrado songs" ON songs FOR DELETE USING (true);
CREATE POLICY "Inserción scores" ON scores FOR INSERT WITH CHECK (true);
CREATE POLICY "Actualización scores" ON scores FOR UPDATE USING (true);
CREATE POLICY "Borrado scores" ON scores FOR DELETE USING (true);
CREATE POLICY "Inserción song_types" ON song_types FOR INSERT WITH CHECK (true);
CREATE POLICY "Inserción song_subtypes" ON song_subtypes FOR INSERT WITH CHECK (true);
CREATE POLICY "Inserción instruments" ON instruments FOR INSERT WITH CHECK (true);
CREATE POLICY "Inserción partituras_subtypes" ON partituras_subtypes FOR INSERT WITH CHECK (true);
