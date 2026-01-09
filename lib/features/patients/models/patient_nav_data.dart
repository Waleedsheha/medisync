/// PatientNavData
/// ----------------
/// كلاس بسيط لنقل بيانات المريض بين الشاشات.
/// - الأساس: نمرّر الداتا عن طريق GoRouter extra (أفضل وأسرع)
/// - احتياطي: من query parameters (لو حد فتح لينك قديم)
class PatientNavData {
  final String patientName;
  final String mrn;

  final String hospitalName;
  final String unitName;

  const PatientNavData({
    required this.patientName,
    required this.mrn,
    required this.hospitalName,
    required this.unitName,
  });

  /// ✅ Fallback: يبني الداتا من queryParameters
  /// مفيد لو فيه لينك قديم:
  /// /patient?name=...&mrn=...&hospital=...&room=...
  /// (or legacy: unit=...)
  factory PatientNavData.fromQuery(Map<String, String> qp) {
    final name = (qp['name'] ?? qp['patientName'] ?? 'Patient').trim();
    final mrn = (qp['mrn'] ?? 'MRN').trim();
    final hospital = (qp['hospital'] ?? qp['hospitalName'] ?? '').trim();
    final room = (qp['room'] ?? qp['roomName'] ?? '').trim();
    final unit = (qp['unit'] ?? qp['unitName'] ?? '').trim();

    return PatientNavData(
      patientName: name.isEmpty ? 'Patient' : name,
      mrn: mrn.isEmpty ? 'MRN' : mrn,
      hospitalName: hospital,
      unitName: room.isNotEmpty ? room : unit,
    );
  }

  /// ✅ Optional: يساعدنا بعدين نعمل Share Link بسهولة
  Map<String, String> toQuery() {
    return {
      'name': patientName,
      'mrn': mrn,
      if (hospitalName.trim().isNotEmpty) 'hospital': hospitalName,
      if (unitName.trim().isNotEmpty) 'room': unitName,
    };
  }

  PatientNavData copyWith({
    String? patientName,
    String? mrn,
    String? hospitalName,
    String? unitName,
  }) {
    return PatientNavData(
      patientName: patientName ?? this.patientName,
      mrn: mrn ?? this.mrn,
      hospitalName: hospitalName ?? this.hospitalName,
      unitName: unitName ?? this.unitName,
    );
  }
}
