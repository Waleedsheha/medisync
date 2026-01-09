//lib/features/dashboard/data/global_search_provider.dart
// lib/features/dashboard/data/global_search_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../hierarchy/data/hierarchy_providers.dart';
import '../../patients/data/patients_repository.dart';

/// Types of search results.
enum SearchResultType { hospital, unit, patient }

/// A single search result.
class SearchResult {
  final SearchResultType type;
  final String title;
  final String subtitle;

  /// Route to navigate to when tapped.
  final String route;

  const SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

/// Provider holding the current search query.
final globalSearchQueryProvider =
    NotifierProvider<GlobalSearchQueryNotifier, String>(
      () => GlobalSearchQueryNotifier(),
    );

class GlobalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

/// Provider that computes search results based on the query.
final globalSearchResultsProvider = FutureProvider<List<SearchResult>>((
  ref,
) async {
  final query = ref.watch(globalSearchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return [];

  final results = <SearchResult>[];

  // 1. Search Hospitals
  final hierarchyRepo = ref.read(hierarchyRepositoryProvider);
  final hospitals = await hierarchyRepo.loadHospitals();
  for (final h in hospitals) {
    if (h.name.toLowerCase().contains(query)) {
      final encodedHospital = Uri.encodeComponent(h.name);
      results.add(
        SearchResult(
          type: SearchResultType.hospital,
          title: h.name,
          subtitle: h.subtitle,
          route: '/departments?hospital=$encodedHospital',
        ),
      );
    }

      // 2. Search Departments within each hospital
      final departments = await hierarchyRepo.loadDepartments(h.id);
      for (final d in departments) {
        if (d.name.toLowerCase().contains(query)) {
          final encodedHospital = Uri.encodeComponent(h.name);
          final encodedDepartmentName = Uri.encodeComponent(d.name);
          results.add(
            SearchResult(
              type: SearchResultType.unit,
              title: d.name,
              subtitle: 'Department in ${h.name}',
              route:
                  '/rooms?hospital=$encodedHospital&hospitalId=${h.id}&departmentId=${d.id}&departmentName=$encodedDepartmentName',
            ),
          );
        }
      }
  }

  // 3. Search Patients (from Hive box directly)
  final patientsBox = await _openPatientsBox();
  for (final key in patientsBox.keys) {
    final raw = patientsBox.get(key);
    if (raw is Map) {
      final p = PatientRecord.fromJson(raw);
      if (p.name.toLowerCase().contains(query) ||
          p.mrn.toLowerCase().contains(query)) {
        // Build route with query params that match the router
        final encodedName = Uri.encodeComponent(p.name);
        final encodedMrn = Uri.encodeComponent(p.mrn);
        final encodedHospital = Uri.encodeComponent(p.hospitalName);
        final encodedUnit = Uri.encodeComponent(p.unitName);
        results.add(
          SearchResult(
            type: SearchResultType.patient,
            title: p.name,
            subtitle: 'MRN: ${p.mrn} • ${p.unitName}, ${p.hospitalName}',
            route:
                '/patient?name=$encodedName&mrn=$encodedMrn&hospital=$encodedHospital&room=$encodedUnit',
          ),
        );
      }
    }
  }

  return results;
});

Future<Box> _openPatientsBox() async {
  const boxName = 'patients_box_v1';
  if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
  return Hive.openBox(boxName);
}
