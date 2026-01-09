// lib/features/hierarchy/data/hierarchy_meta_repository.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores optional metadata (name override + logo path + pin) for hospitals/units.
///
/// Storage keys:
/// - `<scope>:<id>:name`
/// - `<scope>:<id>:logoPath`
/// - `<scope>:<id>:pinnedAt`   (ISO string)
///
/// scope examples: hospitals, units
class HierarchyMetaRepository {
  static const String _boxName = 'hierarchy_meta_v1';
  static const String logoBucket = 'facility-logos';

  final SupabaseClient _client = Supabase.instance.client;

  Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<String>(_boxName);
    return Hive.openBox<String>(_boxName);
  }

  String normalizeId(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\-]'), '');
  }

  String _k(String scope, String id, String field) => '$scope:$id:$field';

  ({String bucket, String path})? _parseStorageRef(String value) {
    final v = value.trim();
    if (!v.startsWith('sb:')) return null;
    final rest = v.substring(3);
    final i = rest.indexOf(':');
    if (i <= 0 || i >= rest.length - 1) return null;
    final bucket = rest.substring(0, i);
    final path = rest.substring(i + 1);
    if (bucket.trim().isEmpty || path.trim().isEmpty) return null;
    return (bucket: bucket, path: path);
  }

  Future<String?> getNameOverride({
    required String scope,
    required String id,
  }) async {
    final b = await _box();
    return b.get(_k(scope, id, 'name'));
  }

  Future<void> setNameOverride({
    required String scope,
    required String id,
    String? name,
  }) async {
    final b = await _box();
    final key = _k(scope, id, 'name');
    final v = (name ?? '').trim();
    if (v.isEmpty) {
      await b.delete(key);
    } else {
      await b.put(key, v);
    }
  }

  Future<String?> getLogoPath({
    required String scope,
    required String id,
  }) async {
    final b = await _box();
    return b.get(_k(scope, id, 'logoPath'));
  }

  Future<void> setLogoPath({
    required String scope,
    required String id,
    String? path,
  }) async {
    final b = await _box();
    final key = _k(scope, id, 'logoPath');
    final v = (path ?? '').trim();
    if (v.isEmpty) {
      await b.delete(key);
    } else {
      await b.put(key, v);
    }
  }

  /// Uploads a logo image from a local file path to Supabase Storage.
  /// Returns a storage ref `sb:<bucket>:<path>` on success, or null on failure.
  Future<String?> uploadLogoFromFile({
    required String scope,
    required String id,
    required String filePath,
  }) async {
    final fp = filePath.trim();
    if (fp.isEmpty) return null;

    try {
      final f = File(fp);
      if (!await f.exists()) return null;

      final bytes = await f.readAsBytes();
      if (bytes.isEmpty) return null;

      final ext = p.extension(fp).toLowerCase();
      final safeExt = (ext == '.png' || ext == '.jpg' || ext == '.jpeg') ? ext : '.png';
      // Shared model: keep hospital_id in path so Storage RLS policies can enforce membership.
      // Convention: logos/<hospital_id>/<scope>/<facility_id>/logo.<ext>
      // For hospital logos: hospital_id == facility_id == id
      final objectPath = 'logos/$id/$scope/$id/logo$safeExt';

      String? contentType;
      if (safeExt == '.png') contentType = 'image/png';
      if (safeExt == '.jpg' || safeExt == '.jpeg') contentType = 'image/jpeg';

      await _client.storage.from(logoBucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      return 'sb:$logoBucket:$objectPath';
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> getPinnedAt({
    required String scope,
    required String id,
  }) async {
    final b = await _box();
    final raw = (b.get(_k(scope, id, 'pinnedAt')) ?? '').trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setPinnedAt({
    required String scope,
    required String id,
    DateTime? pinnedAt,
  }) async {
    final b = await _box();
    final key = _k(scope, id, 'pinnedAt');
    if (pinnedAt == null) {
      await b.delete(key);
    } else {
      await b.put(key, pinnedAt.toIso8601String());
    }
  }

  /// Returns ids pinned under a scope, optionally filtered by id prefix.
  /// Sorted by pinnedAt DESC (most recent first).
  Future<List<String>> listPinnedIds({
    required String scope,
    String idPrefix = '',
    int limit = 3,
  }) async {
    final b = await _box();
    final out = <({String id, DateTime at})>[];

    for (final k in b.keys) {
      if (k is! String) continue;
      if (!k.startsWith('$scope:')) continue;
      if (!k.endsWith(':pinnedAt')) continue;

      final parts = k.split(':');
      if (parts.length < 3) continue;
      final id = parts[1];

      if (idPrefix.isNotEmpty && !id.startsWith(idPrefix)) continue;

      final dt = DateTime.tryParse((b.get(k) ?? '').trim());
      if (dt == null) continue;

      out.add((id: id, at: dt));
    }

    out.sort((a, b) => b.at.compareTo(a.at));
    return out.take(limit).map((e) => e.id).toList();
  }

  /// Used by PDF: convert logoPath -> bytes (nullable).
  Future<Uint8List?> loadLogoBytesFromPath(String? path) async {
    final p = (path ?? '').trim();
    if (p.isEmpty) return null;

    final parsed = _parseStorageRef(p);
    if (parsed != null) {
      try {
        final bytes = await _client.storage.from(parsed.bucket).download(parsed.path);
        return bytes;
      } catch (_) {
        return null;
      }
    }

    try {
      final f = File(p);
      if (!await f.exists()) return null;
      return await f.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
