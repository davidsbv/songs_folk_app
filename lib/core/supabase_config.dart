/// Configuración de Supabase (URL y clave anónima).
///
/// Para desarrollo puedes definir las variables de entorno al ejecutar:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// O sustituir los [defaultValue] por tus credenciales (no subas este archivo con datos reales a un repo público).
/// Las credenciales se obtienen en: Supabase Dashboard → Project Settings → API.
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

bool get isSupabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
