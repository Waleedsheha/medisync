// lib/features/patients/data/lab_ranges_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/labs/lab_catalog.dart';
import 'lab_ranges_repository.dart';

final labRangesRepositoryProvider = Provider<LabRangesRepository>((ref) {
  return LabRangesRepository();
});

typedef LabRangeScopeArgs = ({String hospitalName, String unitName});

final labRangesForScopeProvider = NotifierProvider.family<LabRangesNotifier, Map<String, LabRange>, LabRangeScopeArgs>(LabRangesNotifier.new);

class LabRangesNotifier extends Notifier<Map<String, LabRange>> {
  LabRangesNotifier(this._args);

  final LabRangeScopeArgs _args;
  late final LabRangesRepository _repo;

  @override
  Map<String, LabRange> build() {
    _repo = ref.read(labRangesRepositoryProvider);
    _load();
    return {};
  }

  Future<void> _load() async {
    final loaded = await _repo.loadOverrides(
      hospitalName: _args.hospitalName,
      unitName: _args.unitName,
    );
    state = loaded;
  }

  Future<void> setOverride(String labKey, LabRange range) async {
    final next = {...state, labKey: range};
    state = next;
    await _repo.saveOverrides(
      hospitalName: _args.hospitalName,
      unitName: _args.unitName,
      overrides: next,
    );
  }

  Future<void> removeOverride(String labKey) async {
    if (!state.containsKey(labKey)) return;
    final next = {...state}..remove(labKey);
    state = next;
    await _repo.saveOverrides(
      hospitalName: _args.hospitalName,
      unitName: _args.unitName,
      overrides: next,
    );
  }

  Future<void> resetAll() async {
    state = {};
    await _repo.clearOverrides(
      hospitalName: _args.hospitalName,
      unitName: _args.unitName,
    );
  }
}
