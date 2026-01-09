import 'package:hive/hive.dart';

/// Simple hierarchy storage:
/// - hospitals list stored under key: "hospitals"
/// - units per hospital stored under key: "units:`<hospitalId>`"
///
/// Data is stored as `List<String>` in a Hive box (no adapters needed).
class HierarchyRepository {
  static const _boxName = 'hierarchy_data_v1';

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<dynamic>(_boxName);
    return Hive.openBox<dynamic>(_boxName);
  }

  String normalizeId(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\-]'), '');
  }

  // ---------------- Hospitals ----------------
  Future<List<String>> listHospitals() async {
    final b = await _box();
    final v = b.get('hospitals');
    if (v is List) {
      return v
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Future<void> addHospital(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;

    final b = await _box();
    final list = await listHospitals();
    if (list.any((x) => x.toLowerCase() == n.toLowerCase())) return;

    list.insert(0, n);
    await b.put('hospitals', list);
  }

  Future<void> deleteHospital(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;

    final b = await _box();
    final list = await listHospitals();
    list.removeWhere((x) => x.toLowerCase() == n.toLowerCase());
    await b.put('hospitals', list);

    // delete units bucket too
    final id = normalizeId(n);
    await b.delete('units:$id');
  }

  // ---------------- Units ----------------
  Future<List<String>> listUnits(String hospitalName) async {
    final b = await _box();
    final id = normalizeId(hospitalName);
    final v = b.get('units:$id');
    if (v is List) {
      return v
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Future<void> addUnit(String hospitalName, String unitName) async {
    final h = hospitalName.trim();
    final u = unitName.trim();
    if (h.isEmpty || u.isEmpty) return;

    final b = await _box();
    final id = normalizeId(h);
    final list = await listUnits(h);
    if (list.any((x) => x.toLowerCase() == u.toLowerCase())) return;

    list.insert(0, u);
    await b.put('units:$id', list);
  }

  Future<void> deleteUnit(String hospitalName, String unitName) async {
    final h = hospitalName.trim();
    final u = unitName.trim();
    if (h.isEmpty || u.isEmpty) return;

    final b = await _box();
    final id = normalizeId(h);
    final list = await listUnits(h);
    list.removeWhere((x) => x.toLowerCase() == u.toLowerCase());
    await b.put('units:$id', list);
  }
}
