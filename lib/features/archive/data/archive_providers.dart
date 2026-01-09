import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArchivedItem {
  final String id;
  final String name;
  final String type; // 'hospital', 'clinic', 'patient'
  final String parentId; // for patients: hospitalId or clinicId
  final String parentName;
  final DateTime archivedAt;

  const ArchivedItem({
    required this.id,
    required this.name,
    required this.type,
    required this.parentId,
    required this.parentName,
    required this.archivedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'parentId': parentId,
        'parentName': parentName,
        'archivedAt': archivedAt.toIso8601String(),
      };

  static ArchivedItem fromJson(Map<String, dynamic> j) => ArchivedItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        parentId: (j['parentId'] ?? '').toString(),
        parentName: (j['parentName'] ?? '').toString(),
        archivedAt: DateTime.tryParse(j['archivedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class ArchiveRepository {
  static const _boxName = 'archive_data_v1';
  static const _archiveKey = 'archived_items';

  final SupabaseClient _client = Supabase.instance.client;

  Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<String>(_boxName);
    return Hive.openBox<String>(_boxName);
  }

  Future<List<ArchivedItem>> loadArchived() async {
    final b = await _box();
    final raw = (b.get(_archiveKey) ?? '').trim();
    final cached = <ArchivedItem>[];
    if (raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<dynamic>();
        cached.addAll(
          list
              .map((e) => ArchivedItem.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
        );
      } catch (_) {
        // ignore cache parse errors
      }
    }

    // Best-effort remote sync
    try {
      final user = _client.auth.currentUser;
      if (user == null) return cached;

      final allHospitalsRows = await _client
          .from('hospitals')
          .select('id,name,archived_at')
          .order('name', ascending: true);

      final hospitalNameById = <String, String>{};
      final archivedHospitals = <ArchivedItem>[];
      for (final r in (allHospitalsRows as List)) {
        final id = (r['id'] ?? '').toString();
        final name = (r['name'] ?? '').toString();
        if (id.trim().isEmpty) continue;
        hospitalNameById[id] = name;

        final atRaw = r['archived_at'];
        final at = DateTime.tryParse((atRaw ?? '').toString());
        if (at == null) continue;

        archivedHospitals.add(
          ArchivedItem(
            id: id,
            name: name,
            type: 'hospital',
            parentId: '',
            parentName: '',
            archivedAt: at,
          ),
        );
      }

      final clinicsRows = await _client
          .from('clinics')
          .select('id,name,hospital_id,archived_at')
          .order('name', ascending: true);

      final archivedClinics = <ArchivedItem>[];
      for (final r in (clinicsRows as List)) {
        final id = (r['id'] ?? '').toString();
        final name = (r['name'] ?? '').toString();
        final hospitalId = (r['hospital_id'] ?? '').toString();
        if (id.trim().isEmpty || hospitalId.trim().isEmpty) continue;

        final atRaw = r['archived_at'];
        final at = DateTime.tryParse((atRaw ?? '').toString());
        if (at == null) continue;

        archivedClinics.add(
          ArchivedItem(
            id: id,
            name: name,
            type: 'clinic',
            parentId: hospitalId,
            parentName: hospitalNameById[hospitalId] ?? '',
            archivedAt: at,
          ),
        );
      }

      final merged = [...archivedHospitals, ...archivedClinics]
        ..sort((a, b) => b.archivedAt.compareTo(a.archivedAt));

      await saveArchived(merged);
      return merged;
    } catch (_) {
      return cached;
    }
  }

  Future<void> saveArchived(List<ArchivedItem> items) async {
    final b = await _box();
    await b.put(_archiveKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> setArchivedAt({
    required String id,
    required String type,
    DateTime? archivedAt,
  }) async {
    final at = archivedAt?.toIso8601String();
    try {
      if (type == 'hospital') {
        await _client.from('hospitals').update({'archived_at': at}).eq('id', id);
      } else if (type == 'clinic') {
        await _client.from('clinics').update({'archived_at': at}).eq('id', id);
      }
    } catch (_) {
      // offline
    }
  }

  Future<void> deleteRemote({required String id, required String type}) async {
    try {
      if (type == 'hospital') {
        await _client.from('hospitals').delete().eq('id', id);
      } else if (type == 'clinic') {
        await _client.from('clinics').delete().eq('id', id);
      }
    } catch (_) {
      // offline
    }
  }
}

final archiveRepositoryProvider = Provider<ArchiveRepository>((ref) => ArchiveRepository());

final archiveControllerProvider =
    AsyncNotifierProvider<ArchiveController, List<ArchivedItem>>(ArchiveController.new);

class ArchiveController extends AsyncNotifier<List<ArchivedItem>> {
  late final ArchiveRepository _repo = ref.read(archiveRepositoryProvider);

  @override
  Future<List<ArchivedItem>> build() async {
    return _repo.loadArchived();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }

  Future<void> archiveItem({
    required String id,
    required String name,
    required String type,
    String parentId = '',
    String parentName = '',
  }) async {
    final current = [...(state.value ?? await _repo.loadArchived())];
    
    // Prevent duplicates
    if (current.any((a) => a.id == id && a.type == type)) return;

    final item = ArchivedItem(
      id: id,
      name: name,
      type: type,
      parentId: parentId,
      parentName: parentName,
      archivedAt: DateTime.now(),
    );

    current.insert(0, item);
    await _repo.saveArchived(current);
    state = AsyncData(current);

    await _repo.setArchivedAt(id: id, type: type, archivedAt: item.archivedAt);
  }

  Future<void> restoreItem(String id, String type) async {
    final current = [...(state.value ?? await _repo.loadArchived())];
    current.removeWhere((a) => a.id == id && a.type == type);
    await _repo.saveArchived(current);
    state = AsyncData(current);

    await _repo.setArchivedAt(id: id, type: type, archivedAt: null);
  }

  Future<void> deleteFromArchive(String id, String type) async {
    final current = [...(state.value ?? await _repo.loadArchived())];
    current.removeWhere((a) => a.id == id && a.type == type);
    await _repo.saveArchived(current);
    state = AsyncData(current);

    await _repo.deleteRemote(id: id, type: type);
  }

  List<ArchivedItem> getByType(String type) {
    return (state.value ?? []).where((a) => a.type == type).toList();
  }
}
