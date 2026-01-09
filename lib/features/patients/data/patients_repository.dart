import 'dart:async';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'facility_resolver.dart';

class PatientRecord {
  final String key; // hospital|unit|mrn
  final String mrn;
  final String name;
  final String hospitalName;
  final String unitName;

  final String phone;
  final String age;
  final String gender;

  const PatientRecord({
    required this.key,
    required this.mrn,
    required this.name,
    required this.hospitalName,
    required this.unitName,
    required this.phone,
    required this.age,
    required this.gender,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'mrn': mrn,
        'name': name,
        'hospitalName': hospitalName,
        'unitName': unitName,
        'phone': phone,
        'age': age,
        'gender': gender,
      };

  static PatientRecord fromJson(Map<dynamic, dynamic> json) => PatientRecord(
        key: (json['key'] ?? '').toString(),
        mrn: (json['mrn'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        hospitalName: (json['hospitalName'] ?? '').toString(),
        unitName: (json['unitName'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        age: (json['age'] ?? '').toString(),
        gender: (json['gender'] ?? '').toString(),
      );
}

class PatientsRepository {
  final SupabaseClient _client = Supabase.instance.client;
  late final FacilityResolver _resolver = FacilityResolver(_client);

  static const String _cacheBoxName = 'patients_box_v1';

  Future<Box> _cacheBox() async {
    if (Hive.isBoxOpen(_cacheBoxName)) return Hive.box(_cacheBoxName);
    return Hive.openBox(_cacheBoxName);
  }

  static String makeKey({
    required String hospitalName,
    required String unitName,
    required String mrn,
  }) {
    final h = hospitalName.trim();
    final u = unitName.trim();
    final m = mrn.trim();
    return '$h|$u|$m';
  }

  Stream<List<PatientRecord>> watchByLocation({
    required String hospitalName,
    required String unitName,
  }) async* {
    final hName = hospitalName.trim();
    final uName = unitName.trim();

    final cache = await _cacheBox();

    List<PatientRecord> readCached() {
      final out = <PatientRecord>[];
      for (final k in cache.keys) {
        final raw = cache.get(k);
        if (raw is! Map) continue;
        final p = PatientRecord.fromJson(raw);
        if (p.hospitalName.trim() == hName && p.unitName.trim() == uName) {
          out.add(p);
        }
      }
      out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return out;
    }

    final controller = StreamController<List<PatientRecord>>();
    StreamSubscription? hiveSub;
    StreamSubscription? supaSub;

    Future<void> ensureRemoteFacility() async {
      final user = _client.auth.currentUser;
      if (user == null) return;

      var hospitalId = await _resolver.findHospitalIdByName(hName);
      hospitalId ??= await _resolver.getOrCreateHospitalId(
        ownerId: user.id,
        hospitalName: hName,
      );

      // Clinics pathway (legacy): create/ensure the placeholder clinic row.
      if (uName == '_clinic') {
        await _resolver.getOrCreateClinicId(hospitalId: hospitalId, clinicName: uName);
      }

      // Rooms should be created from Rooms screen (department context).
      // Here we only ensure the hospital exists.
    }

    Future<void> syncFromSupabaseOnce() async {
      final hospitalId = await _resolver.findHospitalIdByName(hName);
      if (hospitalId == null) return;

      // Clinics pathway (legacy)
      if (uName == '_clinic') {
        final clinicId = await _resolver.findClinicIdByName(
          hospitalId: hospitalId,
          clinicName: uName,
        );
        if (clinicId == null) return;

        final rows = await _client
            .from('patients')
            .select('mrn,name,phone,age,gender,hospital_id,clinic_id')
            .eq('hospital_id', hospitalId)
            .eq('clinic_id', clinicId)
            .order('name', ascending: true);

        for (final r in (rows as List)) {
          final h = (r['hospital_id'] ?? '').toString();
          if (h != hospitalId) continue;

          final mrn = (r['mrn'] ?? '').toString();
          if (mrn.trim().isEmpty) continue;

          final key = PatientsRepository.makeKey(
            hospitalName: hName,
            unitName: uName,
            mrn: mrn,
          );

          await cache.put(
            key,
            PatientRecord(
              key: key,
              mrn: mrn,
              name: (r['name'] ?? '').toString(),
              hospitalName: hName,
              unitName: uName,
              phone: (r['phone'] ?? '').toString(),
              age: (r['age'] ?? '').toString(),
              gender: (r['gender'] ?? '').toString(),
            ).toJson(),
          );
        }

        return;
      }

      final roomId = await _resolver.findRoomIdByName(
        hospitalId: hospitalId,
        roomName: uName,
      );
      if (roomId == null) return;

      final rows = await _client
          .from('patients')
          .select('mrn,name,phone,age,gender,hospital_id,room_id')
          .eq('hospital_id', hospitalId)
          .eq('room_id', roomId)
          .order('name', ascending: true);

      for (final r in (rows as List)) {
        final h = (r['hospital_id'] ?? '').toString();
        if (h != hospitalId) continue;

        final mrn = (r['mrn'] ?? '').toString();
        if (mrn.trim().isEmpty) continue;

        final key = PatientsRepository.makeKey(
          hospitalName: hName,
          unitName: uName,
          mrn: mrn,
        );

        await cache.put(
          key,
          PatientRecord(
            key: key,
            mrn: mrn,
            name: (r['name'] ?? '').toString(),
            hospitalName: hName,
            unitName: uName,
            phone: (r['phone'] ?? '').toString(),
            age: (r['age'] ?? '').toString(),
            gender: (r['gender'] ?? '').toString(),
          ).toJson(),
        );
      }
    }

    controller.onListen = () async {
      controller.add(readCached());

      hiveSub = cache.watch().listen((_) {
        if (!controller.isClosed) controller.add(readCached());
      });

      // Best effort: ensure hospital/clinic exist, then pull remote -> cache.
      try {
        await ensureRemoteFacility();
        await syncFromSupabaseOnce();
      } catch (_) {
        // Offline / auth / missing table: keep cached data.
      }

      // Live updates from Supabase (unfiltered API in this version, so filter client-side)
      try {
        final hospitalId = await _resolver.findHospitalIdByName(hName);
        if (hospitalId == null) return;

        if (uName == '_clinic') {
          final clinicId = await _resolver.findClinicIdByName(
            hospitalId: hospitalId,
            clinicName: uName,
          );
          if (clinicId == null) return;

          supaSub = _client
              .from('patients')
              .stream(primaryKey: const ['id'])
              .listen((rows) async {
            for (final r in rows) {
              final h = (r['hospital_id'] ?? '').toString();
              final cid = (r['clinic_id'] ?? '').toString();
              if (h != hospitalId) continue;
              if (cid != clinicId) continue;

              final mrn = (r['mrn'] ?? '').toString();
              if (mrn.trim().isEmpty) continue;

              final key = PatientsRepository.makeKey(
                hospitalName: hName,
                unitName: uName,
                mrn: mrn,
              );

              await cache.put(
                key,
                PatientRecord(
                  key: key,
                  mrn: mrn,
                  name: (r['name'] ?? '').toString(),
                  hospitalName: hName,
                  unitName: uName,
                  phone: (r['phone'] ?? '').toString(),
                  age: (r['age'] ?? '').toString(),
                  gender: (r['gender'] ?? '').toString(),
                ).toJson(),
              );
            }
          });

          return;
        }

        final roomId = await _resolver.findRoomIdByName(
          hospitalId: hospitalId,
          roomName: uName,
        );
        if (roomId == null) return;

        supaSub = _client
            .from('patients')
            .stream(primaryKey: const ['id'])
            .listen((rows) async {
          for (final r in rows) {
            final h = (r['hospital_id'] ?? '').toString();
            final rid = (r['room_id'] ?? '').toString();
            if (h != hospitalId) continue;
            if (rid != roomId) continue;

            final mrn = (r['mrn'] ?? '').toString();
            if (mrn.trim().isEmpty) continue;

            final key = PatientsRepository.makeKey(
              hospitalName: hName,
              unitName: uName,
              mrn: mrn,
            );

            await cache.put(
              key,
              PatientRecord(
                key: key,
                mrn: mrn,
                name: (r['name'] ?? '').toString(),
                hospitalName: hName,
                unitName: uName,
                phone: (r['phone'] ?? '').toString(),
                age: (r['age'] ?? '').toString(),
                gender: (r['gender'] ?? '').toString(),
              ).toJson(),
            );
          }
        });
      } catch (_) {
        // ignore
      }
    };

    controller.onCancel = () async {
      await hiveSub?.cancel();
      await supaSub?.cancel();
    };

    yield* controller.stream;
  }

  Future<void> upsert(PatientRecord p) async {
    final user = _client.auth.currentUser;
    // Always cache locally (offline-first)
    final cache = await _cacheBox();
    await cache.put(p.key, p.toJson());

    if (user == null) return;

    final hName = p.hospitalName.trim();
    final uName = p.unitName.trim();

    final hospitalId = await _resolver.getOrCreateHospitalId(
      ownerId: user.id,
      hospitalName: hName,
    );

    // Clinics pathway (legacy)
    if (uName == '_clinic') {
      final clinicId = await _resolver.getOrCreateClinicId(
        hospitalId: hospitalId,
        clinicName: uName,
      );

      try {
        await _client.from('patients').upsert(
          {
            'hospital_id': hospitalId,
            'clinic_id': clinicId,
            'room_id': null,
            'mrn': p.mrn.trim(),
            'name': p.name.trim(),
            'phone': p.phone.trim().isEmpty ? null : p.phone.trim(),
            'age': p.age.trim().isEmpty ? null : p.age.trim(),
            'gender': p.gender.trim().isEmpty ? null : p.gender.trim(),
          },
          onConflict: 'hospital_id,mrn',
        );
      } catch (_) {
        // Offline: keep local cache.
      }
      return;
    }

    final roomId = uName.isEmpty
      ? null
      : await _resolver.findRoomIdByName(
        hospitalId: hospitalId,
        roomName: uName,
        );

    // If the room isn't created yet (should be created from Rooms screen),
    // keep it local-only instead of inserting a mismatched record remotely.
    if (uName.isNotEmpty && (roomId == null || roomId.trim().isEmpty)) return;

    try {
      await _client.from('patients').upsert(
        {
          'hospital_id': hospitalId,
          'clinic_id': null,
          'room_id': roomId,
          'mrn': p.mrn.trim(),
          'name': p.name.trim(),
          'phone': p.phone.trim().isEmpty ? null : p.phone.trim(),
          'age': p.age.trim().isEmpty ? null : p.age.trim(),
          'gender': p.gender.trim().isEmpty ? null : p.gender.trim(),
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

class PatientsRepositoryKey {
  final String hospitalName;
  final String unitName;
  final String mrn;

  const PatientsRepositoryKey({
    required this.hospitalName,
    required this.unitName,
    required this.mrn,
  });

  static PatientsRepositoryKey? tryParse(String key) {
    final parts = key.split('|');
    if (parts.length != 3) return null;
    return PatientsRepositoryKey(
      hospitalName: parts[0].trim(),
      unitName: parts[1].trim(),
      mrn: parts[2].trim(),
    );
  }
}

