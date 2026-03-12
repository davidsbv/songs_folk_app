# songs_folk_app

App Flutter de canciones y partituras (Coplero, Partituras, Calendario). Los datos pueden venir de **Supabase** (base de datos en la nube) o de una lista local de ejemplo.

## Requisitos

- Flutter SDK ^3.11.0
- (Opcional) Cuenta en [Supabase](https://supabase.com) para usar base de datos en la nube

## Configuración de Supabase (opcional)

Si quieres usar base de datos en la nube (recomendado para producción y para el futuro panel de administración):

1. **Crear proyecto** en [Supabase](https://app.supabase.com): New Project → nombre y contraseña de BD.
2. **Ejecutar migraciones** en el SQL Editor del proyecto (Dashboard → SQL Editor):
   - Pegar y ejecutar el contenido de `supabase/migrations/00001_initial_schema.sql`
   - Luego `00002_seed_catalogs.sql`
   - Luego `00003_seed_sample_songs.sql`
3. **Obtener credenciales**: Project Settings → API → Project URL y `anon` public key.
4. **Configurar la app** al ejecutar:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```
   O editar temporalmente `lib/core/supabase_config.dart` y poner los valores en `defaultValue` (no subas ese archivo con claves reales a un repositorio público).

Si no configuras Supabase, la app usa datos de ejemplo en memoria (las mismas 5 canciones que antes).

## Ejecutar la app

```bash
flutter pub get
flutter run
```

Para Web: `flutter run -d chrome` o `flutter run -d web-server`.

## Despliegue (Android, iOS, Web) y hosting

La app está preparada para **una sola base de datos en la nube** (Supabase). Así puedes publicar la misma app en las tres plataformas sin configurar servidores propios:

| Qué | Dónde |
|-----|--------|
| **Base de datos y archivos (PDFs/imágenes)** | Supabase (ya está en la nube cuando creas el proyecto). Más adelante puedes usar Supabase Storage para subir partituras. |
| **App Android** | Google Play Store. Generas un AAB: `flutter build appbundle` y lo subes en Play Console. |
| **App iOS** | App Store. Necesitas cuenta de desarrollador Apple y Mac para `flutter build ios` y subir con Xcode/Transporter. |
| **App Web** | Cualquier hosting estático (Firebase Hosting, Vercel, Netlify, o el que prefieras). Comando: `flutter build web` y subes la carpeta `build/web`. |

No hace falta alquilar un VPS ni configurar servidores: Supabase gestiona la BD y el almacenamiento, y tú solo publicas el cliente Flutter en cada tienda/web.

### Resumen para más adelante

1. **Supabase**: ya tienes la BD y las migraciones. Cuando añadas el panel de administración, podrás restringir la escritura con Auth (solo usuarios autenticados puedan crear/editar canciones).
2. **Publicar Android**: cuenta en Play Console → crear app → subir el AAB generado con `flutter build appbundle`.
3. **Publicar iOS**: cuenta Apple Developer → Xcode/Transporter para subir el IPA.
4. **Publicar Web**: `flutter build web` → subir `build/web` a Firebase Hosting (gratis), Vercel o similar.

## Estructura del proyecto

- `lib/models/` – Modelos (Song, Score) y catálogos (tipos/subtipos).
- `lib/repositories/` – [SongsRepository]: obtiene canciones y catálogos desde Supabase o datos locales.
- `lib/screens/` – Pantallas (Partituras, Coplero, Calendario, detalle de canción).
- `lib/core/` – Configuración (Supabase URL y clave).
- `supabase/migrations/` – Scripts SQL para crear tablas y datos iniciales en Supabase.

---

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
