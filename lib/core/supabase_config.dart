// Configuración de Supabase (URL y clave anónima).
//
// Para desarrollo puedes definir las variables de entorno al ejecutar:
//   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
//
// O sustituir los valores por defecto por tus credenciales (no subas este
// archivo con datos reales a un repo público).
// Las credenciales se obtienen en: Supabase Dashboard → Project Settings → API.
//
// Nota: `String.fromEnvironment` usa la variable de entorno si existe, aunque
// esté vacía. En algunos entornos de build eso puede provocar que
// `isSupabaseConfigured` sea `false` y se caiga al fallback de "sample data".
// Aquí hacemos fallback a valores por defecto cuando la env está vacía.

const String _defaultSupabaseUrl = 'https://zxwgmvzdfowtaehwywso.supabase.co';
const String _defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4d2dtdnpkZm93dGFlaHd5d3NvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjQ2MjcsImV4cCI6MjA5MjM0MDYyN30.6aq3ubARQDSzmYOX7ByyS-_0zqz5Jej6im3y2TgaqnM';

final String supabaseUrl = (() {
  const envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  return envUrl.isNotEmpty ? envUrl : _defaultSupabaseUrl;
})();

final String supabaseAnonKey = (() {
  const envKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  return envKey.isNotEmpty ? envKey : _defaultSupabaseAnonKey;
})();

bool get isSupabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

const String supabaseStorageBucket = String.fromEnvironment(
  'SUPABASE_STORAGE_BUCKET',
  defaultValue: 'songs-assets',
);
