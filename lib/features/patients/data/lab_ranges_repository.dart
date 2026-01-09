// lib/features/patients/data/lab_ranges_repository.dart

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/labs/lab_catalog.dart';
import 'facility_resolver.dart';

class LabRangesRepository {
  static const String _boxName = 'lab_ranges_overrides_v1';

  final SupabaseClient _client = Supabase.instance.client;
  late final FacilityResolver _resolver = FacilityResolver(_client);

  Future<Box> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  String _cacheKey({required String hospitalName, required String unitName}) {
    final h = hospitalName.trim();
    final u = unitName.trim();
    return '$h|$u';
  }

  Future<Map<String, LabRange>> loadOverrides({
    required String hospitalName,
    required String unitName,
  }) async {
    final box = await _box();
    final key = _cacheKey(hospitalName: hospitalName, unitName: unitName);

    Map<String, LabRange> cached = {};
    final raw = box.get(key);
    if (raw is Map) {
      final out = <String, LabRange>{};
      raw.forEach((k, v) {
        if (k is! String) return;
        if (v is! Map) return;
        out[k] = LabRange.fromJson(Map<String, dynamic>.from(v));
      });
      cached = out;
    }

    // Try remote (Supabase). If it fails (offline), return cached.
    try {
      final user = _client.auth.currentUser;
      if (user == null) return cached;

      final hName = hospitalName.trim();
      final uName = unitName.trim().isEmpty ? 'General' : unitName.trim();

      final hospitalId = await _resolver.getOrCreateHospitalId(
        ownerId: user.id,
        hospitalName: hName,
      );
      final clinicId = await _resolver.getOrCreateClinicId(
        hospitalId: hospitalId,
        clinicName: uName,
      );

      final row = await _client
          .from('lab_range_overrides')
          .select('overrides')
          .eq('hospital_id', hospitalId)
          .eq('clinic_id', clinicId)
          .maybeSingle();

      final remote = row?['overrides'];
      if (remote is Map) {
        final out = <String, LabRange>{};
        remote.forEach((k, v) {
          if (k is! String) return;
          if (v is! Map) return;
          out[k] = LabRange.fromJson(Map<String, dynamic>.from(v));
        });
        await box.put(key, remote);
        return out;
      }

      return cached;
    } catch (_) {
      return cached;
    }
  }

  Future<void> saveOverrides({
    required String hospitalName,
    required String unitName,
    required Map<String, LabRange> overrides,
  }) async {
    final box = await _box();
    final map = overrides.map((k, v) => MapEntry(k, v.toJson()));
    final key = _cacheKey(hospitalName: hospitalName, unitName: unitName);
    await box.put(key, map);

    // Best effort remote sync.
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final hName = hospitalName.trim();
      final uName = unitName.trim().isEmpty ? 'General' : unitName.trim();

      final hospitalId = await _resolver.getOrCreateHospitalId(
        ownerId: user.id,
        hospitalName: hName,
      );
      final clinicId = await _resolver.getOrCreateClinicId(
        hospitalId: hospitalId,
        clinicName: uName,
      );

      await _client.from('lab_range_overrides').upsert(
        {
          'hospital_id': hospitalId,
          'clinic_id': clinicId,
          'overrides': map,
        },
        onConflict: 'hospital_id,clinic_id',
      );
    } catch (_) {
      // Offline: keep local cache.
    }
  }

  Future<void> clearOverrides({
    required String hospitalName,
    required String unitName,
  }) async {
    final box = await _box();
    final key = _cacheKey(hospitalName: hospitalName, unitName: unitName);
    await box.delete(key);

    // Best effort remote sync.
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final hospitalId = await _resolver.findHospitalIdByName(hospitalName.trim());
      if (hospitalId == null) return;

      final uName = unitName.trim().isEmpty ? 'General' : unitName.trim();
      final clinicId = await _resolver.findClinicIdByName(
        hospitalId: hospitalId,
        clinicName: uName,
      );
      if (clinicId == null) return;

      await _client
          .from('lab_range_overrides')
          .delete()
          .eq('hospital_id', hospitalId)
          .eq('clinic_id', clinicId);
    } catch (_) {
      // ignore
    }
  }
}
