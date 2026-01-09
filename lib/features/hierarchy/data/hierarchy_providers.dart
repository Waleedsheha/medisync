// lib/features/hierarchy/data/hierarchy_providers.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';


class HospitalItem {
  final String id;
  final String name;
  final String subtitle;

  const HospitalItem({
    required this.id,
    required this.name,
    required this.subtitle,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'subtitle': subtitle};

  static HospitalItem fromJson(Map<String, dynamic> j) => HospitalItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
      );
}

class UnitItem {
  final String id;
  final String name;

  const UnitItem({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static UnitItem fromJson(Map<String, dynamic> j) => UnitItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
      );
}

class DepartmentItem {
  final String id;
  final String name;

  const DepartmentItem({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static DepartmentItem fromJson(Map<String, dynamic> j) => DepartmentItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
      );
}

class RoomItem {
  final String id;
  final String name;

  const RoomItem({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static RoomItem fromJson(Map<String, dynamic> j) => RoomItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
      );
}

class HierarchyRepository {
  static const _boxName = 'hierarchy_repo_v1';
  static const _hospitalsKey = 'hospitals';
  final SupabaseClient _client = Supabase.instance.client;
  static const _uuid = Uuid();

  Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<String>(_boxName);
    return Hive.openBox<String>(_boxName);
  }

  String _unitsKey(String hospitalId) => 'units:$hospitalId';

  String _departmentsKey(String hospitalId) => 'departments:$hospitalId';

  String _roomsKey(String departmentId) => 'rooms:$departmentId';

  bool _looksLikeUuid(String s) {
    final v = s.trim();
    if (v.length != 36) return false;
    return RegExp(r'^[0-9a-fA-F\-]{36}$').hasMatch(v);
  }

  Future<void> _migrateLegacyIdsIfNeeded() async {
    final b = await _box();

    final rawHospitals = (b.get(_hospitalsKey) ?? '').trim();
    if (rawHospitals.isEmpty) return;

    List<dynamic> list;
    try {
      list = (jsonDecode(rawHospitals) as List).cast<dynamic>();
    } catch (_) {
      return;
    }

    var changed = false;
    final hospitals = <HospitalItem>[];

    for (final e in list) {
      if (e is! Map) continue;
      final h = HospitalItem.fromJson(e.cast<String, dynamic>());
      var id = h.id.trim();
      if (!_looksLikeUuid(id)) {
        final newId = _uuid.v4();
        // move units bucket if present
        final oldUnitsKey = _unitsKey(id);
        final newUnitsKey = _unitsKey(newId);
        final oldUnitsRaw = (b.get(oldUnitsKey) ?? '').trim();
        if (oldUnitsRaw.isNotEmpty && (b.get(newUnitsKey) ?? '').trim().isEmpty) {
          await b.put(newUnitsKey, oldUnitsRaw);
        }
        await b.delete(oldUnitsKey);

        id = newId;
        changed = true;
      }
      hospitals.add(HospitalItem(id: id, name: h.name, subtitle: h.subtitle));
    }

    // migrate unit ids too
    for (final h in hospitals) {
      final unitsRaw = (b.get(_unitsKey(h.id)) ?? '').trim();
      if (unitsRaw.isEmpty) continue;

      List<dynamic> uList;
      try {
        uList = (jsonDecode(unitsRaw) as List).cast<dynamic>();
      } catch (_) {
        continue;
      }

      var uChanged = false;
      final units = <UnitItem>[];
      for (final ue in uList) {
        if (ue is! Map) continue;
        final u = UnitItem.fromJson(ue.cast<String, dynamic>());
        var uid = u.id.trim();
        if (!_looksLikeUuid(uid)) {
          uid = _uuid.v4();
          uChanged = true;
        }
        units.add(UnitItem(id: uid, name: u.name));
      }
      if (uChanged) {
        await b.put(_unitsKey(h.id), jsonEncode(units.map((e) => e.toJson()).toList()));
        changed = true;
      }
    }

    if (changed) {
      await b.put(_hospitalsKey, jsonEncode(hospitals.map((e) => e.toJson()).toList()));
    }
  }

  Future<List<HospitalItem>> loadHospitals() async {
    await _migrateLegacyIdsIfNeeded();
    final b = await _box();
    final raw = (b.get(_hospitalsKey) ?? '').trim();
    final cached = <HospitalItem>[];
    if (raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<dynamic>();
        cached.addAll(
          list
              .whereType<dynamic>()
              .map((e) => HospitalItem.fromJson((e as Map).cast<String, dynamic>()))
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

      dynamic hospitalsRows;
      try {
        hospitalsRows = await _client
            .from('hospitals')
            .select('id,name')
        .isFilter('archived_at', null)
            .order('name', ascending: true);
      } catch (_) {
        hospitalsRows = await _client
            .from('hospitals')
            .select('id,name')
            .order('name', ascending: true);
      }

      final hospitals = (hospitalsRows as List)
          .map((r) => (
                id: (r['id'] ?? '').toString(),
                name: (r['name'] ?? '').toString(),
              ))
          .where((h) => h.id.trim().isNotEmpty)
          .toList();

      // Pull all active departments once to compute counts + seed departments cache
      dynamic departmentsRows;
      try {
        departmentsRows = await _client
            .from('departments')
            .select('id,name,hospital_id')
            .isFilter('archived_at', null)
            .order('name', ascending: true);
      } catch (_) {
        departmentsRows = await _client
            .from('departments')
            .select('id,name,hospital_id')
            .order('name', ascending: true);
      }

      final departmentsByHospital = <String, List<DepartmentItem>>{};
      for (final r in (departmentsRows as List)) {
        final hospitalId = (r['hospital_id'] ?? '').toString();
        final departmentId = (r['id'] ?? '').toString();
        if (hospitalId.trim().isEmpty || departmentId.trim().isEmpty) continue;
        departmentsByHospital.putIfAbsent(hospitalId, () => <DepartmentItem>[]).add(
              DepartmentItem(
                id: departmentId,
                name: (r['name'] ?? '').toString(),
              ),
            );
      }

      final out = <HospitalItem>[];
      for (final h in hospitals) {
        final departments = departmentsByHospital[h.id] ?? const <DepartmentItem>[];
        await saveDepartments(h.id, departments);

        final departmentCount = departments.length;
        final deptStr = departmentCount == 1 ? 'department' : 'departments';
        out.add(
          HospitalItem(
            id: h.id,
            name: h.name,
            subtitle: '$departmentCount $deptStr • 0 patients',
          ),
        );
      }

      // IMPORTANT: do not drop local-only items when remote returns empty/partial.
      // This can happen when Supabase insert/RLS blocks writes or when the user is offline.
      final mergedById = <String, HospitalItem>{
        for (final h in cached) h.id: h,
        for (final h in out) h.id: h,
      };

      final merged = mergedById.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      await saveHospitals(merged);
      return merged;
    } catch (_) {
      return cached;
    }
  }

  Future<void> saveHospitals(List<HospitalItem> hospitals) async {
    final b = await _box();
    await b.put(_hospitalsKey, jsonEncode(hospitals.map((e) => e.toJson()).toList()));
  }

  Future<List<UnitItem>> loadUnits(String hospitalId) async {
    await _migrateLegacyIdsIfNeeded();
    final b = await _box();
    final raw = (b.get(_unitsKey(hospitalId)) ?? '').trim();
    final cached = <UnitItem>[];
    if (raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<dynamic>();
        cached.addAll(
          list
              .whereType<dynamic>()
              .map((e) => UnitItem.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
        );
      } catch (_) {
        // ignore
      }
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) return cached;

      dynamic rows;
      try {
        rows = await _client
            .from('clinics')
            .select('id,name,hospital_id')
            .eq('hospital_id', hospitalId)
        .isFilter('archived_at', null)
            .order('name', ascending: true);
      } catch (_) {
        rows = await _client
            .from('clinics')
            .select('id,name,hospital_id')
            .eq('hospital_id', hospitalId)
            .order('name', ascending: true);
      }

      final out = (rows as List)
          .map(
            (r) => UnitItem(
              id: (r['id'] ?? '').toString(),
              name: (r['name'] ?? '').toString(),
            ),
          )
          .where((u) => u.id.trim().isNotEmpty)
          .toList();

      await saveUnits(hospitalId, out);
      return out;
    } catch (_) {
      return cached;
    }
  }

  Future<void> saveUnits(String hospitalId, List<UnitItem> units) async {
    final b = await _box();
    await b.put(_unitsKey(hospitalId), jsonEncode(units.map((e) => e.toJson()).toList()));
  }

  Future<List<DepartmentItem>> loadDepartments(String hospitalId) async {
    final b = await _box();
    final raw = (b.get(_departmentsKey(hospitalId)) ?? '').trim();
    final cached = <DepartmentItem>[];
    if (raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<dynamic>();
        cached.addAll(
          list
              .whereType<dynamic>()
              .map((e) => DepartmentItem.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
        );
      } catch (_) {
        // ignore
      }
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) return cached;

      dynamic rows;
      try {
        rows = await _client
            .from('departments')
            .select('id,name,hospital_id')
            .eq('hospital_id', hospitalId)
            .isFilter('archived_at', null)
            .order('name', ascending: true);
      } catch (_) {
        rows = await _client
            .from('departments')
            .select('id,name,hospital_id')
            .eq('hospital_id', hospitalId)
            .order('name', ascending: true);
      }

      final out = (rows as List)
          .map(
            (r) => DepartmentItem(
              id: (r['id'] ?? '').toString(),
              name: (r['name'] ?? '').toString(),
            ),
          )
          .where((d) => d.id.trim().isNotEmpty)
          .toList();

      final mergedById = <String, DepartmentItem>{
        for (final d in cached) d.id: d,
        for (final d in out) d.id: d,
      };

      final merged = mergedById.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      await saveDepartments(hospitalId, merged);
      return merged;
    } catch (_) {
      return cached;
    }
  }

  Future<void> saveDepartments(String hospitalId, List<DepartmentItem> departments) async {
    final b = await _box();
    await b.put(
      _departmentsKey(hospitalId),
      jsonEncode(departments.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<RoomItem>> loadRooms({
    required String hospitalId,
    required String departmentId,
  }) async {
    final b = await _box();
    final raw = (b.get(_roomsKey(departmentId)) ?? '').trim();
    final cached = <RoomItem>[];
    if (raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<dynamic>();
        cached.addAll(
          list
              .whereType<dynamic>()
              .map((e) => RoomItem.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
        );
      } catch (_) {
        // ignore
      }
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) return cached;

      dynamic rows;
      try {
        rows = await _client
            .from('rooms')
            .select('id,name,hospital_id,department_id')
            .eq('hospital_id', hospitalId)
            .eq('department_id', departmentId)
            .isFilter('archived_at', null)
            .order('name', ascending: true);
      } catch (_) {
        rows = await _client
            .from('rooms')
            .select('id,name,hospital_id,department_id')
            .eq('hospital_id', hospitalId)
            .eq('department_id', departmentId)
            .order('name', ascending: true);
      }

      final out = (rows as List)
          .map(
            (r) => RoomItem(
              id: (r['id'] ?? '').toString(),
              name: (r['name'] ?? '').toString(),
            ),
          )
          .where((d) => d.id.trim().isNotEmpty)
          .toList();

      final mergedById = <String, RoomItem>{
        for (final r in cached) r.id: r,
        for (final r in out) r.id: r,
      };

      final merged = mergedById.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      await saveRooms(departmentId, merged);
      return merged;
    } catch (_) {
      return cached;
    }
  }

  Future<void> saveRooms(String departmentId, List<RoomItem> rooms) async {
    final b = await _box();
    await b.put(_roomsKey(departmentId), jsonEncode(rooms.map((e) => e.toJson()).toList()));
  }

  String newHospitalId(String name) => _uuid.v4();

  String newUnitId(String name) => _uuid.v4();

  String newDepartmentId(String name) => _uuid.v4();

  String newRoomId(String name) => _uuid.v4();

  Future<void> upsertHospital({required HospitalItem item, required String ownerId}) async {
    try {
      await _client.from('hospitals').upsert(
        {
          'id': item.id,
          'owner_id': ownerId,
          'name': item.name.trim(),
          'archived_at': null,
        },
        onConflict: 'id',
      );

      // Shared model: ensure the creator is also a member.
      try {
        await _client.from('hospital_members').upsert(
          {
            'hospital_id': item.id,
            'user_id': ownerId,
            'role': 'staff',
          },
          onConflict: 'hospital_id,user_id',
        );
      } catch (_) {
        // ignore (offline / RLS / table missing)
      }
    } catch (_) {
      // offline
    }
  }

  Future<void> upsertClinic({
    required String hospitalId,
    required UnitItem unit,
  }) async {
    try {
      await _client.from('clinics').upsert(
        {
          'id': unit.id,
          'hospital_id': hospitalId,
          'name': unit.name.trim(),
          'archived_at': null,
        },
        onConflict: 'id',
      );
    } catch (_) {
      // offline
    }
  }

  Future<void> upsertDepartment({
    required String hospitalId,
    required DepartmentItem department,
  }) async {
    try {
      await _client.from('departments').upsert(
        {
          'id': department.id,
          'hospital_id': hospitalId,
          'name': department.name.trim(),
          'archived_at': null,
        },
        onConflict: 'id',
      );
    } catch (_) {
      // offline
    }
  }

  Future<void> upsertRoom({
    required String hospitalId,
    required String departmentId,
    required RoomItem room,
  }) async {
    try {
      await _client.from('rooms').upsert(
        {
          'id': room.id,
          'hospital_id': hospitalId,
          'department_id': departmentId,
          'name': room.name.trim(),
          'archived_at': null,
        },
        onConflict: 'id',
      );
    } catch (_) {
      // offline
    }
  }

  Future<void> archiveHospital(String hospitalId) async {
    try {
      await _client
          .from('hospitals')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('id', hospitalId);
    } catch (_) {
      // offline
    }
  }

  Future<void> archiveClinic(String clinicId) async {
    try {
      await _client
          .from('clinics')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('id', clinicId);
    } catch (_) {
      // offline
    }
  }

  Future<void> archiveDepartment(String departmentId) async {
    try {
      await _client
          .from('departments')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('id', departmentId);
    } catch (_) {
      // offline
    }
  }

  Future<void> archiveRoom(String roomId) async {
    try {
      await _client
          .from('rooms')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('id', roomId);
    } catch (_) {
      // offline
    }
  }
}

final hierarchyRepositoryProvider = Provider<HierarchyRepository>((ref) => HierarchyRepository());

final hospitalsControllerProvider =
    AsyncNotifierProvider<HospitalsController, List<HospitalItem>>(HospitalsController.new);

class HospitalsController extends AsyncNotifier<List<HospitalItem>> {
  late final HierarchyRepository _repo = ref.read(hierarchyRepositoryProvider);

  @override
  Future<List<HospitalItem>> build() async {
    final hospitals = await _repo.loadHospitals();
    // Ensure subtitle reflects cached department counts (remote loadHospitals already tries)
    final withCounts = <HospitalItem>[];
    for (final h in hospitals) {
      final departments = await _repo.loadDepartments(h.id);
      final departmentCount = departments.length;
      final deptStr = departmentCount == 1 ? 'department' : 'departments';
      withCounts.add(
        HospitalItem(
          id: h.id,
          name: h.name,
          subtitle: '$departmentCount $deptStr • 0 patients',
        ),
      );
    }
    return withCounts;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }

  /// Adds a hospital. Returns `true` if added, `false` if a duplicate was detected.
  Future<bool> addHospital(String name) async {
    final current = [...(state.value ?? await _repo.loadHospitals())];
    final id = _repo.newHospitalId(name);

    // prevent duplicates by id
    if (current.any((h) => h.id == id)) return false;

    final item = HospitalItem(
      id: id,
      name: name.trim(),
      subtitle: '0 units • 0 patients',
    );

    current.insert(0, item);
    await _repo.saveHospitals(current);
    state = AsyncData(current);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _repo.upsertHospital(item: item, ownerId: user.id);
    }
    return true;
  }

  Future<void> deleteHospital(String hospitalId) async {
    final current = [...(state.value ?? await _repo.loadHospitals())];
    current.removeWhere((h) => h.id == hospitalId);
    await _repo.saveHospitals(current);
    state = AsyncData(current);

    // Soft-archive remotely (Archive screen can restore / delete permanently)
    await _repo.archiveHospital(hospitalId);
  }
}

final departmentsControllerProvider = AsyncNotifierProvider.family<
    DepartmentsController, List<DepartmentItem>, String>(DepartmentsController.new);

class DepartmentsController extends AsyncNotifier<List<DepartmentItem>> {
  DepartmentsController(this.hospitalId);

  final String hospitalId;
  late final HierarchyRepository _repo = ref.read(hierarchyRepositoryProvider);

  @override
  Future<List<DepartmentItem>> build() async {
    return _repo.loadDepartments(hospitalId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _repo.loadDepartments(hospitalId));
  }

  Future<bool> addDepartment(String name) async {
    final current = [...(state.value ?? await _repo.loadDepartments(hospitalId))];
    final id = _repo.newDepartmentId(name);
    if (current.any((d) => d.id == id)) return false;

    current.insert(0, DepartmentItem(id: id, name: name.trim()));
    await _repo.saveDepartments(hospitalId, current);
    state = AsyncData(current);
    ref.invalidate(hospitalsControllerProvider);

    await _repo.upsertDepartment(
      hospitalId: hospitalId,
      department: DepartmentItem(id: id, name: name.trim()),
    );
    return true;
  }

  Future<void> deleteDepartment(String departmentId) async {
    final current = [...(state.value ?? await _repo.loadDepartments(hospitalId))];
    current.removeWhere((d) => d.id == departmentId);
    await _repo.saveDepartments(hospitalId, current);
    state = AsyncData(current);
    ref.invalidate(hospitalsControllerProvider);
    await _repo.archiveDepartment(departmentId);
  }

  Future<void> renameDepartment({
    required String departmentId,
    required String newName,
  }) async {
    final current = [...(state.value ?? await _repo.loadDepartments(hospitalId))];
    final i = current.indexWhere((d) => d.id == departmentId);
    if (i == -1) return;
    current[i] = DepartmentItem(id: current[i].id, name: newName.trim());
    await _repo.saveDepartments(hospitalId, current);
    state = AsyncData(current);

    await _repo.upsertDepartment(hospitalId: hospitalId, department: current[i]);
  }
}

final roomsControllerProvider = AsyncNotifierProvider.family<
    RoomsController, List<RoomItem>, ({String hospitalId, String departmentId})>(RoomsController.new);

class RoomsController extends AsyncNotifier<List<RoomItem>> {
  RoomsController(this.arg);

  final ({String hospitalId, String departmentId}) arg;
  late final HierarchyRepository _repo = ref.read(hierarchyRepositoryProvider);

  @override
  Future<List<RoomItem>> build() async {
    return _repo.loadRooms(hospitalId: arg.hospitalId, departmentId: arg.departmentId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(
      await _repo.loadRooms(hospitalId: arg.hospitalId, departmentId: arg.departmentId),
    );
  }

  Future<bool> addRoom(String name) async {
    final current = [...(state.value ?? await build())];
    final id = _repo.newRoomId(name);
    if (current.any((r) => r.id == id)) return false;

    current.insert(0, RoomItem(id: id, name: name.trim()));
    await _repo.saveRooms(arg.departmentId, current);
    state = AsyncData(current);

    await _repo.upsertRoom(
      hospitalId: arg.hospitalId,
      departmentId: arg.departmentId,
      room: RoomItem(id: id, name: name.trim()),
    );
    return true;
  }

  Future<void> deleteRoom(String roomId) async {
    final current = [...(state.value ?? await build())];
    current.removeWhere((r) => r.id == roomId);
    await _repo.saveRooms(arg.departmentId, current);
    state = AsyncData(current);
    await _repo.archiveRoom(roomId);
  }

  Future<void> renameRoom({required String roomId, required String newName}) async {
    final current = [...(state.value ?? await build())];
    final i = current.indexWhere((r) => r.id == roomId);
    if (i == -1) return;
    current[i] = RoomItem(id: current[i].id, name: newName.trim());
    await _repo.saveRooms(arg.departmentId, current);
    state = AsyncData(current);

    await _repo.upsertRoom(
      hospitalId: arg.hospitalId,
      departmentId: arg.departmentId,
      room: current[i],
    );
  }
}

final unitsControllerProvider = AsyncNotifierProvider.family<
    UnitsController, List<UnitItem>, String>(UnitsController.new);

class UnitsController extends AsyncNotifier<List<UnitItem>> {
  UnitsController(this.arg);
  
  final String arg;
  late final HierarchyRepository _repo = ref.read(hierarchyRepositoryProvider);

  @override
  Future<List<UnitItem>> build() async {
    return _repo.loadUnits(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _repo.loadUnits(arg));
  }

  /// Adds a unit. Returns `true` if added, `false` if a duplicate was detected.
  Future<bool> addUnit(String name) async {
    final current = [...(state.value ?? await _repo.loadUnits(arg))];
    final id = _repo.newUnitId(name);

    if (current.any((u) => u.id == id)) return false;

    current.insert(0, UnitItem(id: id, name: name.trim()));
    await _repo.saveUnits(arg, current);
    state = AsyncData(current);
    ref.invalidate(hospitalsControllerProvider);

    // Best-effort remote upsert
    await _repo.upsertClinic(hospitalId: arg, unit: UnitItem(id: id, name: name.trim()));
    return true;
  }

  Future<void> deleteUnit(String unitId) async {
    final current = [...(state.value ?? await _repo.loadUnits(arg))];
    current.removeWhere((u) => u.id == unitId);
    await _repo.saveUnits(arg, current);
    state = AsyncData(current);
    ref.invalidate(hospitalsControllerProvider);

    await _repo.archiveClinic(unitId);
  }

  Future<void> renameUnit({required String unitId, required String newName}) async {
    final current = [...(state.value ?? await _repo.loadUnits(arg))];
    final i = current.indexWhere((u) => u.id == unitId);
    if (i == -1) return;

    current[i] = UnitItem(id: current[i].id, name: newName.trim());
    await _repo.saveUnits(arg, current);
    state = AsyncData(current);

    await _repo.upsertClinic(hospitalId: arg, unit: current[i]);
  }
}
