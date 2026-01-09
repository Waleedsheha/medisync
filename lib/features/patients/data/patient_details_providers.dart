//lib/features/patients/data/patient_details_providers.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_details_ui_models.dart';
import '../models/labs/lab_catalog.dart';
import 'patient_details_repository.dart';
import 'patients_repository.dart';

typedef PatientDetailsArgs = ({
  String patientName,
  String mrn,
  String hospitalName,
  String unitName,
});

final patientDetailsRepositoryProvider = Provider<PatientDetailsRepository>((ref) {
  return PatientDetailsRepository();
});

final patientDetailsControllerProvider = AsyncNotifierProvider.autoDispose.family<
    PatientDetailsController, PatientDetailsUiModel, PatientDetailsArgs>(PatientDetailsController.new);

class PatientDetailsController extends AsyncNotifier<PatientDetailsUiModel> {
  PatientDetailsController(this._args);
  
  late final PatientDetailsArgs _args;
  late final PatientDetailsRepository _repo;
  late final String _key;

  @override
  Future<PatientDetailsUiModel> build() async {
    _repo = ref.read(patientDetailsRepositoryProvider);

    _key = PatientsRepository.makeKey(
      hospitalName: _args.hospitalName,
      unitName: _args.unitName,
      mrn: _args.mrn,
    );

    final saved = await _repo.getByKey(_key);
    if (saved != null) return saved;

    final fresh = PatientDetailsUiModel(
      name: _args.patientName,
      mrn: _args.mrn,
      patientId: _args.mrn,
      phone: '',
      age: '',
      gender: '',
      admissionDate: '',
      dischargeDate: '',
      complaint: '',
      presentHistory: '',
      provisionalDiagnosis: const [],
      finalDiagnosis: const [],
      pastHistory: const [],
      hospitalCourse: const [],
      consultations: const [],
      plans: const [],
      meds: const [],
      discontinuedMeds: const [],
      radiologyStudies: const [],
      radiologyImages: const [],
      labs: const [],
      notes: const [],
    );

    // seed once
    unawaited(_repo.upsertByKey(_key, fresh));
    return fresh;
  }

  void _setAndSave(PatientDetailsUiModel next) {
    state = AsyncData(next);
    unawaited(_repo.upsertByKey(_key, next));
  }

  String _clean(String s) => s.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  String _fmtNow(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString().padLeft(4, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$mi';
  }

  // -------- Diagnosis / History / Course / Consultations --------

  void addProvisionalDiagnosisItem(String text) {
    final v = _clean(text);
    if (v.isEmpty) return;
    final cur = state.value!;
    _setAndSave(cur.copyWith(provisionalDiagnosis: [...cur.provisionalDiagnosis, v]));
  }

  void addFinalDiagnosisItem(String text) {
    final v = _clean(text);
    if (v.isEmpty) return;
    final cur = state.value!;
    _setAndSave(cur.copyWith(finalDiagnosis: [...cur.finalDiagnosis, v]));
  }

  void addPastHistoryItem(String text) {
    final v = _clean(text);
    if (v.isEmpty) return;
    final cur = state.value!;
    _setAndSave(cur.copyWith(pastHistory: [...cur.pastHistory, v]));
  }

  /// ✅ must include date/time automatically
  void addHospitalCourseItem(String text) {
    final v = _clean(text);
    if (v.isEmpty) return;

    final stamped = '$v • ${_fmtNow(DateTime.now())}';

    final cur = state.value!;
    _setAndSave(cur.copyWith(hospitalCourse: [...cur.hospitalCourse, stamped]));
  }

  void addConsultationItem(String text) {
    final v = _clean(text);
    if (v.isEmpty) return;
    final cur = state.value!;
    _setAndSave(cur.copyWith(consultations: [...cur.consultations, v]));
  }

  // -------- Plans --------
  void addPlan(PlanUi p) {
    final cur = state.value!;
    _setAndSave(cur.copyWith(plans: [...cur.plans, p]));
  }

  // -------- Labs --------
  void addLabEntry(LabEntryUi entry) {
    final cur = state.value!;
    final next = [entry, ...cur.labs]..sort((a, b) => b.date.compareTo(a.date));
    _setAndSave(cur.copyWith(labs: next));
  }

  void deleteLabEntry(int index) {
    final cur = state.value!;
    final list = [...cur.labs];
    if (index >= 0 && index < list.length) list.removeAt(index);
    _setAndSave(cur.copyWith(labs: list));
  }

  // -------- Radiology --------
  void addRadiologyStudy(RadiologyStudyUi s) {
    final cur = state.value!;
    _setAndSave(cur.copyWith(radiologyStudies: [...cur.radiologyStudies, s]));
  }

  void removeRadiologyStudy(int index) {
    final cur = state.value!;
    final list = [...cur.radiologyStudies];
    if (index >= 0 && index < list.length) list.removeAt(index);
    _setAndSave(cur.copyWith(radiologyStudies: list));
  }

  void addRadiologyImage(String path) {
    final cur = state.value!;
    _setAndSave(cur.copyWith(radiologyImages: [...cur.radiologyImages, path]));
  }

  void addRadiologyImages(List<String> paths) {
    if (paths.isEmpty) return;
    final cur = state.value!;
    final next = [...cur.radiologyImages, ...paths];
    _setAndSave(cur.copyWith(radiologyImages: next));
  }

  void removeRadiologyImage(int index) {
    final cur = state.value!;
    final list = [...cur.radiologyImages];
    if (index >= 0 && index < list.length) list.removeAt(index);
    _setAndSave(cur.copyWith(radiologyImages: list));
  }

  void removeRadiologyImageAt(int index) {
    final cur = state.value!;
    final list = [...cur.radiologyImages];
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    _setAndSave(cur.copyWith(radiologyImages: list));
  }

  // -------- Meds --------
  void addMedication(MedicationUi m) {
    final cur = state.value!;
    _setAndSave(cur.copyWith(meds: [...cur.meds, m]));
  }

  void discontinueMedication(MedicationUi m) {
    final cur = state.value!;
    final active = [...cur.meds]..remove(m);
    final disc = [...cur.discontinuedMeds, m.copyWith(stopDate: DateTime.now())];
    _setAndSave(cur.copyWith(meds: active, discontinuedMeds: disc));
  }

  void deleteMedication(MedicationUi m) {
    final cur = state.value!;
    final active = [...cur.meds]..remove(m);
    final disc = [...cur.discontinuedMeds]..remove(m);
    _setAndSave(cur.copyWith(meds: active, discontinuedMeds: disc));
  }

  // -------- Notes --------
  void addNote(NoteUi n) {
    final cur = state.value!;
    _setAndSave(cur.copyWith(notes: [...cur.notes, n]));
  }

  void deleteNote(int index) {
    final cur = state.value!;
    final list = [...cur.notes];
    if (index >= 0 && index < list.length) list.removeAt(index);
    _setAndSave(cur.copyWith(notes: list));
  }

  // -------- Basic info (for later edit screen) --------
  void setBasicInfo({String? phone, String? age, String? gender}) {
    final cur = state.value!;
    _setAndSave(
      PatientDetailsUiModel(
        name: cur.name,
        mrn: cur.mrn,
        patientId: cur.patientId,
        phone: phone ?? cur.phone,
        age: age ?? cur.age,
        gender: gender ?? cur.gender,
        admissionDate: cur.admissionDate,
        dischargeDate: cur.dischargeDate,
        complaint: cur.complaint,
        presentHistory: cur.presentHistory,
        provisionalDiagnosis: cur.provisionalDiagnosis,
        finalDiagnosis: cur.finalDiagnosis,
        pastHistory: cur.pastHistory,
        hospitalCourse: cur.hospitalCourse,
        consultations: cur.consultations,
        plans: cur.plans,
        meds: cur.meds,
        discontinuedMeds: cur.discontinuedMeds,
        radiologyStudies: cur.radiologyStudies,
        radiologyImages: cur.radiologyImages,
        labs: cur.labs,
        notes: cur.notes,
      ),
    );
  }

  // -------- Update all medical details --------
  void updateAll(PatientDetailsUiModel updated) {
    _setAndSave(updated);
  }

  // -------- Single Field Updates --------
  void updateComplaint(String text) {
    final cur = state.value!;
    _setAndSave(cur.copyWith(complaint: _clean(text)));
  }

  void updatePresentHistory(String text) {
    final cur = state.value!;
    _setAndSave(cur.copyWith(presentHistory: _clean(text)));
  }
}
