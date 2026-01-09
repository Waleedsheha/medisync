import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class ClinicItem {
  final String id;
  final String name;
  final String subtitle;

  const ClinicItem({
    required this.id,
    required this.name,
    required this.subtitle,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'subtitle': subtitle};

  static ClinicItem fromJson(Map<String, dynamic> j) => ClinicItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
      );
}

class ClinicsRepository {
  static const _boxName = 'clinics_data_v1';
  static const _clinicsKey = 'clinics';

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

  Future<List<ClinicItem>> loadClinics() async {
    final b = await _box();
    final raw = (b.get(_clinicsKey) ?? '').trim();
    if (raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<dynamic>();
    return list.map((e) => ClinicItem.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<void> saveClinics(List<ClinicItem> clinics) async {
    final b = await _box();
    await b.put(_clinicsKey, jsonEncode(clinics.map((e) => e.toJson()).toList()));
  }

  String newClinicId(String name) => normalizeId(name);
}

final clinicsRepositoryProvider = Provider<ClinicsRepository>((ref) => ClinicsRepository());

final clinicsControllerProvider =
    AsyncNotifierProvider<ClinicsController, List<ClinicItem>>(ClinicsController.new);

class ClinicsController extends AsyncNotifier<List<ClinicItem>> {
  late final ClinicsRepository _repo = ref.read(clinicsRepositoryProvider);

  @override
  Future<List<ClinicItem>> build() async {
    return _repo.loadClinics();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }

  /// Adds a clinic. Returns `true` if added, `false` if a duplicate was detected.
  Future<bool> addClinic(String name) async {
    final current = [...(state.value ?? await _repo.loadClinics())];
    final id = _repo.newClinicId(name);

    if (current.any((c) => c.id == id)) return false;

    final item = ClinicItem(
      id: id,
      name: name.trim(),
      subtitle: '0 patients',
    );

    current.insert(0, item);
    await _repo.saveClinics(current);
    state = AsyncData(current);
    return true;
  }

  Future<void> deleteClinic(String clinicId) async {
    final current = [...(state.value ?? await _repo.loadClinics())];
    current.removeWhere((c) => c.id == clinicId);
    await _repo.saveClinics(current);
    state = AsyncData(current);
  }

  Future<void> renameClinic({required String clinicId, required String newName}) async {
    final current = [...(state.value ?? await _repo.loadClinics())];
    final i = current.indexWhere((c) => c.id == clinicId);
    if (i == -1) return;

    current[i] = ClinicItem(id: current[i].id, name: newName.trim(), subtitle: current[i].subtitle);
    await _repo.saveClinics(current);
    state = AsyncData(current);
  }
}
