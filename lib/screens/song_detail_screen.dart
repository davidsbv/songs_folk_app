import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/song.dart';
import '../models/score.dart';

/// Pantalla de detalle: letra y, si [showOnlyLyrics] es false, partituras/tablaturas.
class SongDetailScreen extends StatelessWidget {
  final Song song;
  final bool showOnlyLyrics;

  const SongDetailScreen({
    super.key,
    required this.song,
    this.showOnlyLyrics = false,
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
              Text('Subtipo: ${song.subtype}', style: const TextStyle(fontSize: 16)),
              Text('Autor: ${song.author}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _sectionTitle('Letra'),
              const SizedBox(height: 8),
              if (song.lyricsText != null && song.lyricsText!.isNotEmpty)
                Text(song.lyricsText!, style: const TextStyle(fontSize: 16)),
              if (song.lyricsText != null &&
                  song.lyricsText!.isNotEmpty &&
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
              if (!showOnlyLyrics) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _sectionTitle('Partituras y tablaturas'),
                const SizedBox(height: 8),
                if (song.scores.isEmpty)
                  const Text(
                    'No hay partituras/tablaturas cargadas todavía.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                for (final score in song.scores) ...[
                  _scoreBlock(context, score),
                  const SizedBox(height: 16),
                ],
              ],
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

  Widget _scoreBlock(BuildContext context, Score score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instrumento: ${score.instrument}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text('Partitura', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (score.scorePdfPath != null)
          _openLinkButton(
            context,
            label: 'Ver partitura (PDF)',
            path: score.scorePdfPath!,
          ),
        if (score.scoreImagePath != null) _imageFromPath(score.scoreImagePath!),
        if (score.scorePdfPath == null && score.scoreImagePath == null)
          const Text(
            'Sin partitura cargada.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        const SizedBox(height: 12),
        const Text('Tablatura', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (score.tabPdfPath != null)
          _openLinkButton(
            context,
            label: 'Ver tablatura (PDF)',
            path: score.tabPdfPath!,
          ),
        if (score.tabImagePath != null) _imageFromPath(score.tabImagePath!),
        if (score.tabPdfPath == null && score.tabImagePath == null)
          const Text(
            'Sin tablatura cargada.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
      ],
    );
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

  Widget _openLinkButton(
    BuildContext context, {
    required String label,
    required String path,
  }) {
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
                errorBuilder: (_, error, stackTrace) => const Text('Error al cargar la imagen'),
              )
            : Image.asset(
                path,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, error, stackTrace) => const Text('Imagen no encontrada en assets'),
              ),
      ),
    );
  }
}
