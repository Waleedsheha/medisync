import 'package:flutter/foundation.dart';

import 'labs/lab_catalog.dart';

@immutable
class PlanUi {
  final String title;
  final DateTime scheduledAt;

  const PlanUi({required this.title, required this.scheduledAt});

  String get whenText =>
      '${scheduledAt.day.toString().padLeft(2, '0')}/${scheduledAt.month.toString().padLeft(2, '0')}/${scheduledAt.year}';

  Map<String, dynamic> toJson() => {
        'title': title,
        'scheduledAt': scheduledAt.toIso8601String(),
      };

  static PlanUi fromJson(Map<dynamic, dynamic> json) => PlanUi(
        title: (json['title'] ?? '').toString(),
        scheduledAt: DateTime.tryParse((json['scheduledAt'] ?? '').toString()) ?? DateTime.now(),
      );
}

@immutable
class MedicationUi {
  final String name;
  final DateTime? startDate;
  final DateTime? stopDate;

  const MedicationUi({required this.name, this.startDate, this.stopDate});

  MedicationUi copyWith({DateTime? stopDate}) => MedicationUi(
        name: name,
        startDate: startDate,
        stopDate: stopDate ?? this.stopDate,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'startDate': startDate?.toIso8601String(),
        'stopDate': stopDate?.toIso8601String(),
      };

  static MedicationUi fromJson(Map<dynamic, dynamic> json) => MedicationUi(
        name: (json['name'] ?? '').toString(),
        startDate: _dt(json['startDate']),
        stopDate: _dt(json['stopDate']),
      );

  static DateTime? _dt(dynamic v) {
    final s = (v ?? '').toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

@immutable
class RadiologyStudyUi {
  final String title;
  final DateTime date;

  const RadiologyStudyUi({required this.title, required this.date});

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date.toIso8601String(),
      };

  static RadiologyStudyUi fromJson(Map<dynamic, dynamic> json) => RadiologyStudyUi(
        title: (json['title'] ?? '').toString(),
        date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      );
}

@immutable
class NoteUi {
  final String text;
  final DateTime createdAt;

  const NoteUi({required this.text, required this.createdAt});

  Map<String, dynamic> toJson() => {
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  static NoteUi fromJson(Map<dynamic, dynamic> json) => NoteUi(
        text: (json['text'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      );
}

@immutable
class PatientDetailsUiModel {
  final String name;
  final String mrn;

  final String patientId;
  final String phone;
  final String age;
  final String gender;
  final String admissionDate;
  final String dischargeDate;

  final String complaint;
  final String presentHistory;

  final List<String> provisionalDiagnosis;
  final List<String> finalDiagnosis;

  final List<String> pastHistory;
  final List<String> hospitalCourse;
  final List<String> consultations;

  final List<PlanUi> plans;

  final List<MedicationUi> meds;
  final List<MedicationUi> discontinuedMeds;

  final List<RadiologyStudyUi> radiologyStudies;
  final List<String> radiologyImages;

  final List<LabEntryUi> labs;
  final List<NoteUi> notes;

  const PatientDetailsUiModel({
    required this.name,
    required this.mrn,
    required this.patientId,
    required this.phone,
    required this.age,
    required this.gender,
    required this.admissionDate,
    required this.dischargeDate,
    required this.complaint,
    required this.presentHistory,
    required this.provisionalDiagnosis,
    required this.finalDiagnosis,
    required this.pastHistory,
    required this.hospitalCourse,
    required this.consultations,
    required this.plans,
    required this.meds,
    required this.discontinuedMeds,
    required this.radiologyStudies,
    required this.radiologyImages,
    required this.labs,
    required this.notes,
  });

  PatientDetailsUiModel copyWith({
    // existing
    List<MedicationUi>? meds,
    List<MedicationUi>? discontinuedMeds,
    List<RadiologyStudyUi>? radiologyStudies,
    List<String>? radiologyImages,
    List<PlanUi>? plans,
    List<NoteUi>? notes,
    List<LabEntryUi>? labs,

    // ✅ new: support diagnosis/history/courses lists
    String? complaint,
    String? presentHistory,
    List<String>? provisionalDiagnosis,
    List<String>? finalDiagnosis,
    List<String>? pastHistory,
    List<String>? hospitalCourse,
    List<String>? consultations,
  }) {
    return PatientDetailsUiModel(
      name: name,
      mrn: mrn,
      patientId: patientId,
      phone: phone,
      age: age,
      gender: gender,
      admissionDate: admissionDate,
      dischargeDate: dischargeDate,
      complaint: complaint ?? this.complaint,
      presentHistory: presentHistory ?? this.presentHistory,

      provisionalDiagnosis: provisionalDiagnosis ?? this.provisionalDiagnosis,
      finalDiagnosis: finalDiagnosis ?? this.finalDiagnosis,
      pastHistory: pastHistory ?? this.pastHistory,
      hospitalCourse: hospitalCourse ?? this.hospitalCourse,
      consultations: consultations ?? this.consultations,

      plans: plans ?? this.plans,
      meds: meds ?? this.meds,
      discontinuedMeds: discontinuedMeds ?? this.discontinuedMeds,
      radiologyStudies: radiologyStudies ?? this.radiologyStudies,
      radiologyImages: radiologyImages ?? this.radiologyImages,
      labs: labs ?? this.labs,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'mrn': mrn,
        'patientId': patientId,
        'phone': phone,
        'age': age,
        'gender': gender,
        'admissionDate': admissionDate,
        'dischargeDate': dischargeDate,
        'complaint': complaint,
        'presentHistory': presentHistory,
        'provisionalDiagnosis': provisionalDiagnosis,
        'finalDiagnosis': finalDiagnosis,
        'pastHistory': pastHistory,
        'hospitalCourse': hospitalCourse,
        'consultations': consultations,
        'plans': plans.map((e) => e.toJson()).toList(),
        'meds': meds.map((e) => e.toJson()).toList(),
        'discontinuedMeds': discontinuedMeds.map((e) => e.toJson()).toList(),
        'radiologyStudies': radiologyStudies.map((e) => e.toJson()).toList(),
        'radiologyImages': radiologyImages,
        'labs': labs.map((e) => e.toJson()).toList(),
        'notes': notes.map((e) => e.toJson()).toList(),
      };

  static PatientDetailsUiModel fromJson(Map<dynamic, dynamic> json) => PatientDetailsUiModel(
        name: (json['name'] ?? '').toString(),
        mrn: (json['mrn'] ?? '').toString(),
        patientId: (json['patientId'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        age: (json['age'] ?? '').toString(),
        gender: (json['gender'] ?? '').toString(),
        admissionDate: (json['admissionDate'] ?? '').toString(),
        dischargeDate: (json['dischargeDate'] ?? '').toString(),
        complaint: (json['complaint'] ?? '').toString(),
        presentHistory: (json['presentHistory'] ?? '').toString(),
        provisionalDiagnosis: _strList(json['provisionalDiagnosis']),
        finalDiagnosis: _strList(json['finalDiagnosis']),
        pastHistory: _strList(json['pastHistory']),
        hospitalCourse: _strList(json['hospitalCourse']),
        consultations: _strList(json['consultations']),
        plans: _mapList(json['plans']).map(PlanUi.fromJson).toList(),
        meds: _mapList(json['meds']).map(MedicationUi.fromJson).toList(),
        discontinuedMeds: _mapList(json['discontinuedMeds']).map(MedicationUi.fromJson).toList(),
        radiologyStudies: _mapList(json['radiologyStudies']).map(RadiologyStudyUi.fromJson).toList(),
        radiologyImages: _strList(json['radiologyImages']),
        labs: _mapList(json['labs']).map(LabEntryUi.fromJson).toList(),
        notes: _mapList(json['notes']).map(NoteUi.fromJson).toList(),
      );

  static List<String> _strList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const <String>[];
  }

  static List<Map<dynamic, dynamic>> _mapList(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => Map<dynamic, dynamic>.from(e)).toList();
    }
    return const <Map<dynamic, dynamic>>[];
  }
}
