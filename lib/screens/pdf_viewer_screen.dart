import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final String path;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(path);
    final isUrl = uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: isUrl
          ? SfPdfViewer.network(
              path,
              canShowScrollHead: true,
              canShowScrollStatus: true,
            )
          : SfPdfViewer.asset(
              path,
              canShowScrollHead: true,
              canShowScrollStatus: true,
            ),
    );
  }
}
