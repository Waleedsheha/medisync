import 'package:supabase_flutter/supabase_flutter.dart';

class FacilityResolver {
  FacilityResolver(this._client);

  final SupabaseClient _client;

  Future<String?> findHospitalIdByName(String hospitalName) async {
    final name = hospitalName.trim();
    if (name.isEmpty) return null;

    try {
      try {
        final row = await _client
            .from('hospitals')
            .select('id')
            .eq('name', name)
          .isFilter('archived_at', null)
            .maybeSingle();

        if (row == null) return null;
        return (row['id'] ?? '').toString();
      } catch (_) {
        final row = await _client
            .from('hospitals')
            .select('id')
            .eq('name', name)
            .maybeSingle();

        if (row == null) return null;
        return (row['id'] ?? '').toString();
      }
    } catch (_) {
      return null;
    }
  }

  Future<String> getOrCreateHospitalId({
    required String ownerId,
    required String hospitalName,
  }) async {
    final name = hospitalName.trim();
    if (name.isEmpty) throw Exception('Hospital name is required');

    final existing = await findHospitalIdByName(name);
    if (existing != null && existing.isNotEmpty) return existing;

    // If it exists but archived, restore it.
    try {
      final archived = await _client
          .from('hospitals')
          .select('id,archived_at')
          .eq('owner_id', ownerId)
          .eq('name', name)
          .maybeSingle();

      if (archived != null) {
        final id = (archived['id'] ?? '').toString();
        if (id.trim().isNotEmpty) {
          await _client
              .from('hospitals')
              .update({'archived_at': null})
              .eq('id', id);

          // Best-effort: ensure membership exists for current user.
          try {
            await _client.from('hospital_members').upsert(
              {
                'hospital_id': id,
                'user_id': ownerId,
                'role': 'staff',
              },
              onConflict: 'hospital_id,user_id',
            );
          } catch (_) {
            // ignore
          }
          return id;
        }
      }
    } catch (_) {
      // ignore
    }

    try {
      try {
        final inserted = await _client
            .from('hospitals')
            .insert({
              'owner_id': ownerId,
              'name': name,
              'archived_at': null,
            })
            .select('id')
            .single();

        final id = (inserted['id'] ?? '').toString();
        if (id.trim().isNotEmpty) {
          try {
            await _client.from('hospital_members').upsert(
              {
                'hospital_id': id,
                'user_id': ownerId,
                'role': 'staff',
              },
              onConflict: 'hospital_id,user_id',
            );
          } catch (_) {
            // ignore
          }
        }
        return id;
      } catch (_) {
        final inserted = await _client
            .from('hospitals')
            .insert({
              'owner_id': ownerId,
              'name': name,
            })
            .select('id')
            .single();

        final id = (inserted['id'] ?? '').toString();
        if (id.trim().isNotEmpty) {
          try {
            await _client.from('hospital_members').upsert(
              {
                'hospital_id': id,
                'user_id': ownerId,
                'role': 'staff',
              },
              onConflict: 'hospital_id,user_id',
            );
          } catch (_) {
            // ignore
          }
        }
        return id;
      }
    } catch (_) {
      final retry = await findHospitalIdByName(name);
      if (retry != null && retry.isNotEmpty) return retry;
      rethrow;
    }
  }

  Future<String?> findClinicIdByName({
    required String hospitalId,
    required String clinicName,
  }) async {
    final name = clinicName.trim();
    if (hospitalId.trim().isEmpty || name.isEmpty) return null;

    try {
      try {
        final row = await _client
            .from('clinics')
            .select('id')
            .eq('hospital_id', hospitalId)
            .eq('name', name)
          .isFilter('archived_at', null)
            .maybeSingle();

        if (row == null) return null;
        return (row['id'] ?? '').toString();
      } catch (_) {
        final row = await _client
            .from('clinics')
            .select('id')
            .eq('hospital_id', hospitalId)
            .eq('name', name)
            .maybeSingle();

        if (row == null) return null;
        return (row['id'] ?? '').toString();
      }
    } catch (_) {
      return null;
    }
  }

  Future<String> getOrCreateClinicId({
    required String hospitalId,
    required String clinicName,
    String? kind,
  }) async {
    final name = clinicName.trim();
    if (hospitalId.trim().isEmpty) throw Exception('Hospital id is required');
    if (name.isEmpty) throw Exception('Clinic name is required');

    final existing = await findClinicIdByName(
      hospitalId: hospitalId,
      clinicName: name,
    );
    if (existing != null && existing.isNotEmpty) return existing;

    // If it exists but archived, restore it.
    try {
      final archived = await _client
          .from('clinics')
          .select('id,archived_at')
          .eq('hospital_id', hospitalId)
          .eq('name', name)
          .maybeSingle();
      if (archived != null) {
        final id = (archived['id'] ?? '').toString();
        if (id.trim().isNotEmpty) {
          await _client
              .from('clinics')
              .update({'archived_at': null})
              .eq('id', id);
          return id;
        }
      }
    } catch (_) {
      // ignore
    }

    try {
      try {
        final inserted = await _client
            .from('clinics')
            .insert({
              'hospital_id': hospitalId,
              'name': name,
              'archived_at': null,
              if (kind != null && kind.trim().isNotEmpty) 'kind': kind.trim(),
            })
            .select('id')
            .single();

        return (inserted['id'] ?? '').toString();
      } catch (_) {
        final inserted = await _client
            .from('clinics')
            .insert({
              'hospital_id': hospitalId,
              'name': name,
              if (kind != null && kind.trim().isNotEmpty) 'kind': kind.trim(),
            })
            .select('id')
            .single();

        return (inserted['id'] ?? '').toString();
      }
    } catch (_) {
      final retry = await findClinicIdByName(
        hospitalId: hospitalId,
        clinicName: name,
      );
      if (retry != null && retry.isNotEmpty) return retry;
      rethrow;
    }
  }

  Future<String?> findRoomIdByName({
    required String hospitalId,
    required String roomName,
  }) async {
    final name = roomName.trim();
    if (hospitalId.trim().isEmpty || name.isEmpty) return null;

    try {
      try {
        final row = await _client
            .from('rooms')
            .select('id')
            .eq('hospital_id', hospitalId)
            .eq('name', name)
            .isFilter('archived_at', null)
            .maybeSingle();

        if (row == null) return null;
        return (row['id'] ?? '').toString();
      } catch (_) {
        final row = await _client
            .from('rooms')
            .select('id')
            .eq('hospital_id', hospitalId)
            .eq('name', name)
            .maybeSingle();

        if (row == null) return null;
        return (row['id'] ?? '').toString();
      }
    } catch (_) {
      return null;
    }
  }

  Future<String> getOrCreateRoomId({
    required String hospitalId,
    required String departmentId,
    required String roomName,
  }) async {
    final name = roomName.trim();
    if (hospitalId.trim().isEmpty) throw Exception('Hospital id is required');
    if (departmentId.trim().isEmpty) throw Exception('Department id is required');
    if (name.isEmpty) throw Exception('Room name is required');

    final existing = await findRoomIdByName(hospitalId: hospitalId, roomName: name);
    if (existing != null && existing.isNotEmpty) return existing;

    // If it exists but archived, restore it.
    try {
      final archived = await _client
          .from('rooms')
          .select('id,archived_at')
          .eq('hospital_id', hospitalId)
          .eq('name', name)
          .maybeSingle();
      if (archived != null) {
        final id = (archived['id'] ?? '').toString();
        if (id.trim().isNotEmpty) {
          await _client.from('rooms').update({'archived_at': null}).eq('id', id);
          return id;
        }
      }
    } catch (_) {
      // ignore
    }

    final inserted = await _client
        .from('rooms')
        .insert({
          'hospital_id': hospitalId,
          'department_id': departmentId,
          'name': name,
          'archived_at': null,
        })
        .select('id')
        .single();

    return (inserted['id'] ?? '').toString();
  }
}
