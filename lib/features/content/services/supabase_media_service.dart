import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseMediaService {
  SupabaseMediaService(this._supabase);

  final SupabaseClient _supabase;
  static const _bucketName = 'content-media';

  String get bucketName => _bucketName;

  Future<String> uploadImage({
    required String userId,
    required String folder,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final safeName = fileName.trim().isEmpty ? 'image.jpg' : fileName.trim();
    final extension = safeName.contains('.')
        ? safeName.split('.').last.toLowerCase()
        : 'jpg';
    final path = '$userId/$folder/${const Uuid().v4()}.$extension';

    await _supabase.storage.from(_bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );

    return _supabase.storage.from(_bucketName).getPublicUrl(path);
  }
}
