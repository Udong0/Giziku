import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Upload & hapus file gambar makanan ke Supabase Storage.
///
/// Bucket `food-images` harus **public** karena project pakai Firebase Auth,
/// bukan Supabase Auth — RLS berbasis `auth.uid()` tidak berlaku.
///
/// File di-upload ke path `<firebase_uid>/<uuid>.jpg` supaya:
/// - Mudah cleanup per-user (folder per UID)
/// - Path tidak bisa di-guess user lain (UID = random-looking string)
class FoodImageStorage {
  FoodImageStorage(this._client);

  final SupabaseClient _client;
  static const _bucket = 'food-images';

  /// Upload [localFile] ke Supabase Storage, return public URL.
  ///
  /// File disimpan di `<firebase_uid>/<uuid>.jpg`. Throw kalau user
  /// belum login.
  Future<String> upload(File localFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Tidak bisa upload: user belum login.');
    }
    final ext = p.extension(localFile.path).toLowerCase();
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final remotePath = '$uid/${const Uuid().v4()}$safeExt';

    await _client.storage.from(_bucket).upload(
          remotePath,
          localFile,
          fileOptions: const FileOptions(upsert: false),
        );

    return _client.storage.from(_bucket).getPublicUrl(remotePath);
  }

  /// Hapus file berdasarkan URL publik (extract object path dari URL).
  Future<void> deleteByUrl(String publicUrl) async {
    final marker = '/$_bucket/';
    final idx = publicUrl.indexOf(marker);
    if (idx == -1) return;
    final objectPath = publicUrl.substring(idx + marker.length);
    await _client.storage.from(_bucket).remove([objectPath]);
  }

  /// `true` kalau URL ini dari Supabase Storage (bukan local file path).
  static bool isRemoteUrl(String path) =>
      path.startsWith('http://') || path.startsWith('https://');
}
