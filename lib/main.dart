import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

/// Modelo de canción con soporte flexible para letra, partitura y tablatura.
///
/// - Letra: puede ser texto (para usuarios y futuro OpenSong), PDF o imagen.
/// - Partitura y tablatura: PDF o imagen.
/// OpenSong (acordes sobre letra, cambio de tonalidad) se desarrollará como
/// un módulo aparte más adelante.
class Song {
  final String title;
  final String author;
  final String type;       // Ej: "Jota", "Pasacalles"
  final String instrument; // Ej: "CUERDA", "DULZAINA"

  /// Letra en texto plano (ideal para que el usuario añada canciones y para OpenSong después).
  final String? lyricsText;
  /// Ruta o URL del PDF de la letra (si existe).
  final String? lyricsPdfPath;
  /// Ruta o URL de la imagen de la letra (si existe).
  final String? lyricsImagePath;

  /// Ruta o URL del PDF de la partitura.
  final String? scorePdfPath;
  /// Ruta o URL de la imagen de la partitura.
  final String? scoreImagePath;

  /// Ruta o URL del PDF de la tablatura.
  final String? tabPdfPath;
  /// Ruta o URL de la imagen de la tablatura.
  final String? tabImagePath;

  const Song({
    required this.title,
    required this.author,
    required this.type,
    required this.instrument,
    this.lyricsText,
    this.lyricsPdfPath,
    this.lyricsImagePath,
    this.scorePdfPath,
    this.scoreImagePath,
    this.tabPdfPath,
    this.tabImagePath,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cancionero Folk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Song> sampleSongs = const [
    Song(
      title: 'Mayo a La Virgen de La Antigua',
      type: 'Jota',
      instrument: 'DULZAINA',
      author: 'Diego Pérez Pezuela',
     /* lyricsText:
          'Letra de ejemplo para "Mayo a La Virgen de La Antigua".\n'
          'Primera estrofa...\n'
          'Segunda línea...\n\n'
          'Estribillo...',*/
      lyricsPdfPath: 'https://drive.google.com/file/d/1J7_IboqVB84boJs1VM7_SYi-IGl08LCs/view?usp=drivesdk',
    ),
    Song(
      title: 'Guiño al Señorío',
      type: 'Seguidilla',
      instrument: 'DULZAINA',
      author: 'Diego Pérez Pezuela',
      lyricsText:
          'Letra de ejemplo para "Guiño al Señorío".\n'
          'Aquí iría la letra en texto.\n'
          'Más adelante también PDF o imagen.',
    ),
    Song(
      title: 'Pasacalles De La Plaza',
      type: 'Pasacalles',
      instrument: 'CUERDA',
      author: 'Anónimo',
      lyricsText: 'Letra de ejemplo para "Pasacalles De La Plaza".',
      // Ejemplo: partitura como PDF (URL pública de ejemplo; luego serán tus archivos)
      scorePdfPath: 'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.pdf',
    ),
    Song(
      title: 'Vals del Río',
      type: 'Vals',
      instrument: 'CUERDA',
      author: 'Anónimo',
      lyricsText: 'Letra de ejemplo del "Vals del Río".',
      // Ejemplo: partitura como imagen (URL de ejemplo; luego serán tus assets o URLs)
      scoreImagePath: 'https://media.istockphoto.com/id/867870340/es/foto/abstracto-fondo-de-texto.jpg?s=612x612&w=is&k=20&c=nKMzbc5elJsbbtY7Teg0nWFaSpJuho1A7cE4idIwX2M=',
    ),
    Song(
      title: 'Fandango Serrano',
      type: 'Fandango',
      instrument: 'CUERDA',
      author: 'Anónimo',
      lyricsText: 'Letra de ejemplo para "Fandango Serrano".',
      scoreImagePath: 'https://media.istockphoto.com/id/1361321670/es/vector/borde-abstracto-del-adorno-del-alfabeto-negro-aislado-sobre-fondo-blanco-ilustraci%C3%B3n.jpg?s=612x612&w=0&k=20&c=Io5c4c-7ddt4ZxtHJvdZH43zenvR-iNKPPhRXxDbV1w=',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cancionero Folk'),
      ),
      body: ListView.builder(
        itemCount: sampleSongs.length,
        itemBuilder: (context, index) {
          final song = sampleSongs[index];
          return ListTile(
            title: Text(song.title),
            subtitle: Text(
              '${song.type} · ${song.instrument}\n${song.author}',
            ),
            leading: const Icon(Icons.music_note),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongDetailScreen(song: song),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Pantalla de detalle: muestra letra (texto, PDF o imagen), partitura y tablatura
/// según lo que tenga la canción.
class SongDetailScreen extends StatelessWidget {
  final Song song;

  const SongDetailScreen({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(song.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Estilo: ${song.type}', style: const TextStyle(fontSize: 16)),
              Text(
                'Instrumento: ${song.instrument}',
                style: const TextStyle(fontSize: 16),
              ),
              Text('Autor: ${song.author}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // ----- LETRA -----
              _sectionTitle('Letra'),
              const SizedBox(height: 8),
              if (song.lyricsText != null && song.lyricsText!.isNotEmpty)
                Text(song.lyricsText!, style: const TextStyle(fontSize: 16)),
              if (song.lyricsText != null && song.lyricsText!.isNotEmpty &&
                  (song.lyricsPdfPath != null || song.lyricsImagePath != null))
                const SizedBox(height: 8),
              if (song.lyricsPdfPath != null)
                _openLinkButton(
                  context,
                  label: 'Ver letra (PDF)',
                  path: song.lyricsPdfPath!,
                ),
              if (song.lyricsImagePath != null) ...[
                const SizedBox(height: 8),
                _imageFromPath(song.lyricsImagePath!),
              ],
              if (_noLyrics(song))
                const Text(
                  'Sin letra cargada. Puedes añadir texto, PDF o imagen más adelante.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // ----- PARTITURA -----
              _sectionTitle('Partitura'),
              const SizedBox(height: 8),
              if (song.scorePdfPath != null)
                _openLinkButton(
                  context,
                  label: 'Ver partitura (PDF)',
                  path: song.scorePdfPath!,
                ),
              if (song.scoreImagePath != null) ...[
                if (song.scorePdfPath != null) const SizedBox(height: 8),
                _imageFromPath(song.scoreImagePath!),
              ],
              if (song.scorePdfPath == null && song.scoreImagePath == null)
                const Text(
                  'Sin partitura cargada.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // ----- TABLATURA -----
              _sectionTitle('Tablatura'),
              const SizedBox(height: 8),
              if (song.tabPdfPath != null)
                _openLinkButton(
                  context,
                  label: 'Ver tablatura (PDF)',
                  path: song.tabPdfPath!,
                ),
              if (song.tabImagePath != null) ...[
                if (song.tabPdfPath != null) const SizedBox(height: 8),
                _imageFromPath(song.tabImagePath!),
              ],
              if (song.tabPdfPath == null && song.tabImagePath == null)
                const Text(
                  'Sin tablatura cargada.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _noLyrics(Song s) {
    final hasText = s.lyricsText != null && s.lyricsText!.isNotEmpty;
    final hasPdf = s.lyricsPdfPath != null && s.lyricsPdfPath!.isNotEmpty;
    final hasImage = s.lyricsImagePath != null && s.lyricsImagePath!.isNotEmpty;
    return !hasText && !hasPdf && !hasImage;
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _openLinkButton(BuildContext context, {required String label, required String path}) {
    final uri = Uri.tryParse(path);
    final isUrl = uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: OutlinedButton.icon(
        onPressed: () async {
          if (isUrl) {
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!launched && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo abrir el enlace')),
              );
            }
          } else {
            // Ruta local o asset: más adelante usaremos un visor de PDF en la app
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ruta local/asset: $path. Visor en app próximamente.')),
              );
            }
          }
        },
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _imageFromPath(String path) {
    final uri = Uri.tryParse(path);
    final isUrl = uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isUrl
            ? Image.network(
                path,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const Text('Error al cargar la imagen'),
              )
            : Image.asset(
                path,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const Text('Imagen no encontrada en assets'),
              ),
        ),
    );
  }
}
