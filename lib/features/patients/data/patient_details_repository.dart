import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_details_ui_models.dart';
import 'facility_resolver.dart';
import 'patients_repository.dart';

class PatientDetailsRepository {
  final SupabaseClient _client = Supabase.instance.client;
  late final FacilityResolver _resolver = FacilityResolver(_client);

  static const String _cacheBoxName = 'patient_details_box_v1';

  Future<Box> _cacheBox() async {
    if (Hive.isBoxOpen(_cacheBoxName)) return Hive.box(_cacheBoxName);
    return Hive.openBox(_cacheBoxName);
  }

  Future<PatientDetailsUiModel?> getByKey(String key) async {
    final parsed = PatientsRepositoryKey.tryParse(key);
    if (parsed == null) return null;

    // 1) local cache first
    final cache = await _cacheBox();
    final cached = cache.get(key);
    if (cached is Map) {
      try {
        return PatientDetailsUiModel.fromJson(cached);
      } catch (_) {
        // fallthrough
      }
    }

    final hospitalId = await _resolver.findHospitalIdByName(parsed.hospitalName);
    if (hospitalId == null) return null;

    try {
      final row = await _client
          .from('patients')
          .select('details')
          .eq('hospital_id', hospitalId)
          .eq('mrn', parsed.mrn)
          .maybeSingle();

      if (row == null) return null;
      final details = row['details'];
      if (details is! Map) return null;

      final map = Map<dynamic, dynamic>.from(details);
      final mrn = (map['mrn'] ?? '').toString().trim();
      if (map.isEmpty || mrn.isEmpty) return null;

      final model = PatientDetailsUiModel.fromJson(map);
      await cache.put(key, model.toJson());
      return model;
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertByKey(String key, PatientDetailsUiModel model) async {
    final parsed = PatientsRepositoryKey.tryParse(key);
    if (parsed == null) throw Exception('Invalid patient key');

    // Always cache locally (offline-first)
    final cache = await _cacheBox();
    await cache.put(key, model.toJson());

    final user = _client.auth.currentUser;
    if (user == null) return;

    final hospitalId = await _resolver.getOrCreateHospitalId(
      ownerId: user.id,
      hospitalName: parsed.hospitalName,
    );

    // Clinics pathway (legacy)
    if (parsed.unitName.trim() == '_clinic') {
      final clinicId = await _resolver.getOrCreateClinicId(
        hospitalId: hospitalId,
        clinicName: parsed.unitName,
      );

      try {
        await _client.from('patients').upsert(
          {
            'hospital_id': hospitalId,
            'clinic_id': clinicId,
            'room_id': null,
            'mrn': parsed.mrn.trim(),
            'name': model.name.trim(),
            'phone': model.phone.trim().isEmpty ? null : model.phone.trim(),
            'age': model.age.trim().isEmpty ? null : model.age.trim(),
            'gender': model.gender.trim().isEmpty ? null : model.gender.trim(),
            'details': model.toJson(),
          },
          onConflict: 'hospital_id,mrn',
        );
      } catch (_) {
        // Offline: keep local cache.
      }
      return;
    }

    final roomId = parsed.unitName.trim().isEmpty
        ? null
        : await _resolver.findRoomIdByName(
            hospitalId: hospitalId,
            roomName: parsed.unitName,
          );

    if (parsed.unitName.trim().isNotEmpty && (roomId == null || roomId.trim().isEmpty)) {
      return;
    }

    try {
      await _client.from('patients').upsert(
        {
          'hospital_id': hospitalId,
          'clinic_id': null,
          'room_id': roomId,
          'mrn': parsed.mrn.trim(),
          'name': model.name.trim(),
          'phone': model.phone.trim().isEmpty ? null : model.phone.trim(),
          'age': model.age.trim().isEmpty ? null : model.age.trim(),
          'gender': model.gender.trim().isEmpty ? null : model.gender.trim(),
          'details': model.toJson(),
        },
        onConflict: 'hospital_id,mrn',
      );
    } catch (_) {
      // Offline: keep local cache.
    }
  }

  Future<void> deleteByKey(String key) async {
    final parsed = PatientsRepositoryKey.tryParse(key);
    if (parsed == null) return;

    final cache = await _cacheBox();
    await cache.delete(key);

    final hospitalId = await _resolver.findHospitalIdByName(parsed.hospitalName);
    if (hospitalId == null) return;

    // Delete the patient row (details are stored on the row)
    try {
      await _client
          .from('patients')
          .delete()
          .eq('hospital_id', hospitalId)
          .eq('mrn', parsed.mrn);
    } catch (_) {
      // Offline: local delete already done.
    }
  }
}

