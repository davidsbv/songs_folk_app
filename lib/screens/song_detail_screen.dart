import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/song.dart';
import '../models/score.dart';
import 'pdf_viewer_screen.dart';

/// Pantalla de detalle: letra y, si [showOnlyLyrics] es false, partituras/tablaturas.
class SongDetailScreen extends StatelessWidget {
  final Song song;
  final bool showOnlyLyrics;
  final double fontScale;

  const SongDetailScreen({
    super.key,
    required this.song,
    this.showOnlyLyrics = false,
    this.fontScale = 1.0,
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
                style: TextStyle(
                  fontSize: 24 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Estilo: ${song.type}', style: TextStyle(fontSize: 16 * fontScale)),
              Text('Subtipo: ${song.subtype}', style: TextStyle(fontSize: 16 * fontScale)),
              Text('Autor: ${song.author}', style: TextStyle(fontSize: 16 * fontScale)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _sectionTitle('Letra', fontScale: fontScale),
              const SizedBox(height: 8),
              if (song.lyricsText != null && song.lyricsText!.isNotEmpty)
                Text(song.lyricsText!, style: TextStyle(fontSize: 16 * fontScale)),
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
                Text(
                  'Sin letra cargada.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14 * fontScale,
                  ),
                ),
              if (!showOnlyLyrics) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _sectionTitle('Partituras y tablaturas', fontScale: fontScale),
                const SizedBox(height: 8),
                if (song.scores.isEmpty)
                  Text(
                    'No hay partituras/tablaturas cargadas todavía.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14 * fontScale,
                    ),
                  ),
                for (final score in song.scores) ...[
                  _scoreBlock(context, score, fontScale: fontScale),
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

  Widget _scoreBlock(
    BuildContext context,
    Score score, {
    required double fontScale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instrumento: ${score.instrument}',
          style: TextStyle(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Partitura',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14 * fontScale,
          ),
        ),
        const SizedBox(height: 6),
        if (score.scorePdfPath != null)
          _openLinkButton(
            context,
            label: 'Ver partitura (PDF)',
            path: score.scorePdfPath!,
          ),
        if (score.scoreImagePath != null) _imageFromPath(score.scoreImagePath!),
        if (score.scorePdfPath == null && score.scoreImagePath == null)
          Text(
            'Sin partitura cargada.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14 * fontScale,
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Tablatura',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14 * fontScale,
          ),
        ),
        const SizedBox(height: 6),
        if (score.tabPdfPath != null)
          _openLinkButton(
            context,
            label: 'Ver tablatura (PDF)',
            path: score.tabPdfPath!,
          ),
        if (score.tabImagePath != null) _imageFromPath(score.tabImagePath!),
        if (score.tabPdfPath == null && score.tabImagePath == null)
          Text(
            'Sin tablatura cargada.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14 * fontScale,
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String text, {required double fontScale}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18 * fontScale,
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
    final isPdf = path.toLowerCase().contains('.pdf');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: OutlinedButton.icon(
        onPressed: () async {
          if (isPdf) {
            if (!context.mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(title: label, path: path),
              ),
            );
            return;
          }
          if (isUrl) {
            final launched = await launchUrl(
              uri,
              mode: LaunchMode.inAppBrowserView,
            );
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
