import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'patients_repository.dart';

final patientsRepositoryProvider = Provider<PatientsRepository>((ref) {
  return PatientsRepository();
});

final patientsForLocationProvider = StreamProvider.autoDispose
    .family<List<PatientRecord>, ({String hospitalName, String unitName})>((ref, args) {
  final repo = ref.watch(patientsRepositoryProvider);
  return repo.watchByLocation(
    hospitalName: args.hospitalName,
    unitName: args.unitName,
  );
});

