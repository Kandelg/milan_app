import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:milan_app/core/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads profile photos to Supabase Storage.
class StorageRepository {
  StorageRepository(this._client, this._picker);

  final SupabaseClient _client;
  final ImagePicker _picker;

  /// Opens the gallery and returns the chosen file (or `null` if cancelled).
  Future<XFile?> pickImage({bool fromCamera = false}) {
    final ImageSource source =
        fromCamera ? ImageSource.camera : ImageSource.gallery;
    return _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1440);
  }

  /// Uploads bytes under `<userId>/<uuid>.<ext>` and returns the public URL.
  ///
  /// Works on Android, iOS **and** web, because it never touches
  /// platform file paths.
  Future<String> uploadProfilePhoto({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final String extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';

    final String objectPath =
        '$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';

    await _client.storage
        .from('profile-photos')
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$extension',
          ),
        );

    return _client.storage.from('profile-photos').getPublicUrl(objectPath);
  }

  /// Deletes a previously uploaded photo, ignoring "not found" errors.
  Future<void> deleteProfilePhoto(String publicUrl) async {
    try {
      final Uri uri = Uri.parse(publicUrl);
      final String marker = '/profile-photos/';
      final int index = uri.path.indexOf(marker);
      if (index < 0) return;
      final String objectPath = uri.path.substring(index + marker.length);
      await _client.storage.from('profile-photos').remove([objectPath]);
    } catch (_) {
      // Best-effort cleanup; a leftover file is not fatal.
    }
  }

  /// Uploads bytes as a story photo under `<userId>/<timestamp>.<ext>` and
  /// returns the public URL. Works on web too (no file paths touched).
  Future<String> uploadStoryPhoto({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final String extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';

    final String objectPath =
        '$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';

    await _client.storage
        .from(kStoryBucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$extension',
          ),
        );

    return _client.storage.from(kStoryBucket).getPublicUrl(objectPath);
  }
}
