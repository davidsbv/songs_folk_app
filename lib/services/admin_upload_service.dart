import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

class AdminUploadService {
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
}
