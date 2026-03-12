import 'score.dart';

/// Modelo de canción.
///
/// Idea clave (evitar redundancia):
/// - La letra pertenece a la canción (no depende del instrumento).
/// - Partitura y tablatura dependen del instrumento y van en [Score].
/// - OpenSong (acordes sobre letra, transposición) lo haremos como módulo aparte.
class Song {
  final String title;
  final String author;
  final String type; // Ej: "Jota", "Pasacalles"
  final String subtype; // Ej: "Mayo", "Fiestas", "Baile", etc.

  /// Letra en texto plano (ideal para que el usuario añada canciones y para OpenSong después).
  final String? lyricsText;
  /// Ruta o URL del PDF de la letra (si existe).
  final String? lyricsPdfPath;
  /// Ruta o URL de la imagen de la letra (si existe).
  final String? lyricsImagePath;

  /// Partituras/tablaturas por instrumento.
  final List<Score> scores;

  const Song({
    required this.title,
    required this.author,
    required this.type,
    required this.subtype,
    this.lyricsText,
    this.lyricsPdfPath,
    this.lyricsImagePath,
    this.scores = const [],
  });
}
