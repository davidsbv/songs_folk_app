import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

class AdminUploadService {
  static const String appearanceBackgroundPath = 'appearance/app-background';

  Future<String?> pickAndUpload({
    required String folder,
    required List<String> allowedExtensions,
  }) async {
    if (!isSupabaseConfigured) {
      throw Exception('Supabase no está configurado.');
    }
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('No se pudieron leer los bytes del archivo.');
    }

    final safeName = (file.name.isEmpty ? 'archivo' : file.name)
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final now = DateTime.now().millisecondsSinceEpoch;
    final remotePath = '$folder/$now-$safeName';

    final client = Supabase.instance.client;
    await client.storage.from(supabaseStorageBucket).uploadBinary(
          remotePath,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: false),
        );
    return client.storage.from(supabaseStorageBucket).getPublicUrl(remotePath);
  }

  /// Sube la imagen de fondo global al bucket publico (`appearance/app-background`).
  /// Sobrescribe el archivo anterior para no acumular objetos.
  Future<String?> pickAndUploadAppearanceBackground() async {
    if (!isSupabaseConfigured) {
      throw Exception('Supabase no está configurado.');
    }
    const allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowed,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('No se pudieron leer los bytes del archivo.');
    }

    var ext = 'jpg';
    final name = file.name;
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) {
      ext = name.substring(dot + 1).toLowerCase();
      if (!allowed.contains(ext)) ext = 'jpg';
    }

    final client = Supabase.instance.client;
    await client.storage.from(supabaseStorageBucket).uploadBinary(
          appearanceBackgroundPath,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            upsert: true,
            contentType: _imageContentType(ext),
          ),
        );
    return client.storage.from(supabaseStorageBucket).getPublicUrl(appearanceBackgroundPath);
  }

  /// Elimina el archivo de fondo global de Storage.
  Future<void> deleteAppearanceBackgroundImage() async {
    if (!isSupabaseConfigured) {
      throw Exception('Supabase no está configurado.');
    }
    final client = Supabase.instance.client;
    await client.storage.from(supabaseStorageBucket).remove([appearanceBackgroundPath]);
  }

  static String _imageContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}
