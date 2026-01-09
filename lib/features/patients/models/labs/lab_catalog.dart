// lib/features/patients/models/labs/lab_catalog.dart
//
// Central place for lab definitions (units + reference ranges + critical thresholds).
// NOTE: Ranges vary by lab/assay; these are sensible defaults for adults.
// You can override per hospital/unit via LabRangesRepository.

enum LabStatus { normal, warning, critical, missing }

class LabRange {
  final double? normalLow;
  final double? normalHigh;

  final double? criticalLow;
  final double? criticalHigh;

  const LabRange({
    required this.normalLow,
    required this.normalHigh,
    required this.criticalLow,
    required this.criticalHigh,
  });

  LabRange copyWith({
    double? normalLow,
    double? normalHigh,
    double? criticalLow,
    double? criticalHigh,
  }) {
    return LabRange(
      normalLow: normalLow ?? this.normalLow,
      normalHigh: normalHigh ?? this.normalHigh,
      criticalLow: criticalLow ?? this.criticalLow,
      criticalHigh: criticalHigh ?? this.criticalHigh,
    );
  }

  Map<String, dynamic> toJson() => {
        'normalLow': normalLow,
        'normalHigh': normalHigh,
        'criticalLow': criticalLow,
        'criticalHigh': criticalHigh,
      };

  static LabRange fromJson(Map<String, dynamic> json) {
    double? d(dynamic x) => (x == null) ? null : (x as num).toDouble();
    return LabRange(
      normalLow: d(json['normalLow']),
      normalHigh: d(json['normalHigh']),
      criticalLow: d(json['criticalLow']),
      criticalHigh: d(json['criticalHigh']),
    );
  }

  String normalText({String unit = ''}) {
    if (normalLow == null && normalHigh == null) return '—';
    if (normalLow != null && normalHigh != null) {
      return '${_fmt(normalLow!)}–${_fmt(normalHigh!)}${unit.isEmpty ? '' : ' $unit'}';
    }
    if (normalLow != null) return '≥ ${_fmt(normalLow!)}${unit.isEmpty ? '' : ' $unit'}';
    return '≤ ${_fmt(normalHigh!)}${unit.isEmpty ? '' : ' $unit'}';
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
    return s.replaceAll(RegExp(r'\.?0+$'), '');
  }
}

class LabDef {
  /// "key" MUST be stable to store values (e.g., "HB", "Na", "K").
  final String key;
  final String group;
  final String label;
  final String unit;

  /// Sex-specific ranges if available.
  final LabRange? male;
  final LabRange? female;

  /// Fallback when sex unknown.
  final LabRange range;

  const LabDef({
    required this.key,
    required this.group,
    required this.label,
    required this.unit,
    required this.range,
    this.male,
    this.female,
  });

  LabRange rangeForGender(String gender) {
    final g = gender.trim().toLowerCase();
    final isFemale = g == 'f' || g == 'female' || g.contains('female') || g.contains('أنث') || g.contains('انث');
    final isMale = g == 'm' || g == 'male' || g.contains('male') || g.contains('ذكر');

    if (isFemale && female != null) return female!;
    if (isMale && male != null) return male!;
    return range;
  }
}

class LabGroupDef {
  final String title;
  final List<LabDef> tests;

  const LabGroupDef({required this.title, required this.tests});
}

class LabCatalog {
  static final List<LabGroupDef> groups = [
    LabGroupDef(
      title: 'CBC',
      tests: [
        LabDef(
          key: 'HB',
          group: 'CBC',
          label: 'Hemoglobin (HB)',
          unit: 'g/dL',
          range: const LabRange(normalLow: 11.0, normalHigh: 18.0, criticalLow: 7.0, criticalHigh: 21.0),
          male: const LabRange(normalLow: 13.0, normalHigh: 17.7, criticalLow: 7.0, criticalHigh: 21.0),
          female: const LabRange(normalLow: 11.1, normalHigh: 15.9, criticalLow: 7.0, criticalHigh: 21.0),
        ),
        LabDef(
          key: 'TLC',
          group: 'CBC',
          label: 'WBC (TLC)',
          unit: '×10⁹/L',
          range: const LabRange(normalLow: 4.0, normalHigh: 11.0, criticalLow: 2.0, criticalHigh: 30.0),
        ),
        LabDef(
          key: 'PLT',
          group: 'CBC',
          label: 'Platelets (PLT)',
          unit: '×10⁹/L',
          range: const LabRange(normalLow: 150, normalHigh: 450, criticalLow: 20, criticalHigh: 1000),
        ),
        LabDef(
          key: 'LYMPH',
          group: 'CBC',
          label: 'Lymphocytes (LYMPH)',
          unit: '%',
          range: const LabRange(normalLow: 20, normalHigh: 40, criticalLow: 5, criticalHigh: 70),
        ),
      ],
    ),
    LabGroupDef(
      title: 'Coagulation',
      tests: [
        LabDef(
          key: 'PT',
          group: 'Coagulation',
          label: 'PT',
          unit: 'sec',
          range: const LabRange(normalLow: 11.0, normalHigh: 13.5, criticalLow: null, criticalHigh: 50),
        ),
        LabDef(
          key: 'PTT',
          group: 'Coagulation',
          label: 'aPTT (PTT)',
          unit: 'sec',
          range: const LabRange(normalLow: 24.0, normalHigh: 33.0, criticalLow: null, criticalHigh: 100),
        ),
        LabDef(
          key: 'INR',
          group: 'Coagulation',
          label: 'INR',
          unit: '',
          range: const LabRange(normalLow: 0.9, normalHigh: 1.2, criticalLow: null, criticalHigh: 5.0),
        ),
      ],
    ),
    LabGroupDef(
      title: 'KFT / Electrolytes',
      tests: [
        LabDef(
          key: 'UREA',
          group: 'KFT',
          label: 'Urea',
          unit: 'mg/dL',
          range: const LabRange(normalLow: 15, normalHigh: 45, criticalLow: null, criticalHigh: 200),
        ),
        LabDef(
          key: 'CREAT',
          group: 'KFT',
          label: 'Creatinine',
          unit: 'mg/dL',
          range: const LabRange(normalLow: 0.6, normalHigh: 1.3, criticalLow: null, criticalHigh: 7.0),
          male: const LabRange(normalLow: 0.74, normalHigh: 1.35, criticalLow: null, criticalHigh: 7.0),
          female: const LabRange(normalLow: 0.59, normalHigh: 1.04, criticalLow: null, criticalHigh: 7.0),
        ),
        LabDef(
          key: 'Na',
          group: 'KFT',
          label: 'Sodium (Na⁺)',
          unit: 'mmol/L',
          range: const LabRange(normalLow: 134, normalHigh: 144, criticalLow: 120, criticalHigh: 160),
        ),
        LabDef(
          key: 'K',
          group: 'KFT',
          label: 'Potassium (K⁺)',
          unit: 'mmol/L',
          range: const LabRange(normalLow: 3.5, normalHigh: 5.2, criticalLow: 2.5, criticalHigh: 6.5),
        ),
        LabDef(
          key: 'Ca',
          group: 'KFT',
          label: 'Calcium (Ca)',
          unit: 'mg/dL',
          range: const LabRange(normalLow: 8.7, normalHigh: 10.2, criticalLow: 6.0, criticalHigh: 13.0),
        ),
        LabDef(
          key: 'Mg',
          group: 'KFT',
          label: 'Magnesium (Mg)',
          unit: 'mg/dL',
          range: const LabRange(normalLow: 1.6, normalHigh: 2.3, criticalLow: 1.0, criticalHigh: 4.0),
        ),
        LabDef(
          key: 'PO4',
          group: 'KFT',
          label: 'Phosphate (PO₄)',
          unit: 'mg/dL',
          range: const LabRange(normalLow: 2.5, normalHigh: 4.5, criticalLow: 2.5, criticalHigh: 10.0),
        ),
      ],
    ),
    LabGroupDef(
      title: 'LFT',
      tests: [
        LabDef(
          key: 'ALB',
          group: 'LFT',
          label: 'Albumin (ALB)',
          unit: 'g/dL',
          range: const LabRange(normalLow: 3.8, normalHigh: 4.9, criticalLow: 2.0, criticalHigh: null),
        ),
        LabDef(
          key: 'ALT',
          group: 'LFT',
          label: 'ALT',
          unit: 'U/L',
          range: const LabRange(normalLow: 0, normalHigh: 44, criticalLow: null, criticalHigh: 1000),
        ),
        LabDef(
          key: 'AST',
          group: 'LFT',
          label: 'AST',
          unit: 'U/L',
          range: const LabRange(normalLow: 0, normalHigh: 40, criticalLow: null, criticalHigh: 1000),
        ),
        LabDef(
          key: 'BILT',
          group: 'LFT',
          label: 'Bilirubin Total (BIL T)',
          unit: 'mg/dL',
          range: const LabRange(normalLow: 0.0, normalHigh: 1.2, criticalLow: null, criticalHigh: 15.0),
        ),
        LabDef(
          key: 'BILD',
          group: 'LFT',
          label: 'Bilirubin Direct (BIL D)',
          unit: 'mg/dL',
          range: const LabRange(normalLow: 0.0, normalHigh: 0.3, criticalLow: null, criticalHigh: 10.0),
        ),
      ],
    ),
    LabGroupDef(
      title: 'Cardio',
      tests: [
        LabDef(
          key: 'TROP',
          group: 'Cardio',
          label: 'Troponin',
          unit: 'ng/mL',
          range: const LabRange(normalLow: 0.0, normalHigh: 0.04, criticalLow: null, criticalHigh: 1.0),
        ),
        LabDef(
          key: 'CKMB',
          group: 'Cardio',
          label: 'CK-MB',
          unit: 'ng/mL',
          range: const LabRange(normalLow: 0.0, normalHigh: 5.0, criticalLow: null, criticalHigh: 50.0),
        ),
        LabDef(
          key: 'CK',
          group: 'Cardio',
          label: 'CK (Total)',
          unit: 'U/L',
          range: const LabRange(normalLow: 20, normalHigh: 200, criticalLow: null, criticalHigh: 1000),
        ),
      ],
    ),
    LabGroupDef(
      title: 'Thyroid',
      tests: [
        LabDef(
          key: 'TSH',
          group: 'Thyroid',
          label: 'TSH',
          unit: 'µIU/mL',
          range: const LabRange(normalLow: 0.45, normalHigh: 4.5, criticalLow: null, criticalHigh: 20),
        ),
        LabDef(
          key: 'FT3',
          group: 'Thyroid',
          label: 'Free T3 (FT3)',
          unit: 'pg/mL',
          range: const LabRange(normalLow: 2.0, normalHigh: 4.4, criticalLow: null, criticalHigh: 10),
        ),
        LabDef(
          key: 'FT4',
          group: 'Thyroid',
          label: 'Free T4 (FT4)',
          unit: 'ng/dL',
          range: const LabRange(normalLow: 0.82, normalHigh: 1.77, criticalLow: null, criticalHigh: 5),
        ),
        LabDef(
          key: 'PTH',
          group: 'Thyroid',
          label: 'PTH',
          unit: 'pg/mL',
          range: const LabRange(normalLow: 15, normalHigh: 65, criticalLow: null, criticalHigh: 500),
        ),
      ],
    ),
    LabGroupDef(
      title: 'Inflammation / Other',
      tests: [
        LabDef(
          key: 'UA',
          group: 'Other',
          label: 'Uric acid (UA)',
          unit: 'mg/dL',
          range: const LabRange(normalLow: 3.4, normalHigh: 7.0, criticalLow: null, criticalHigh: 12),
        ),
        LabDef(
          key: 'CRP',
          group: 'Other',
          label: 'CRP',
          unit: 'mg/L',
          range: const LabRange(normalLow: 0, normalHigh: 10, criticalLow: null, criticalHigh: 200),
        ),
        LabDef(
          key: 'ESR',
          group: 'Other',
          label: 'ESR',
          unit: 'mm/hr',
          range: const LabRange(normalLow: 0, normalHigh: 20, criticalLow: null, criticalHigh: 100),
        ),
        LabDef(
          key: 'LDH',
          group: 'Other',
          label: 'LDH',
          unit: 'U/L',
          range: const LabRange(normalLow: 140, normalHigh: 280, criticalLow: null, criticalHigh: 1000),
        ),
        LabDef(
          key: 'GGT',
          group: 'Other',
          label: 'GGT',
          unit: 'U/L',
          range: const LabRange(normalLow: 0, normalHigh: 60, criticalLow: null, criticalHigh: 1000),
        ),
        LabDef(
          key: 'AMYL',
          group: 'Other',
          label: 'Amylase',
          unit: 'U/L',
          range: const LabRange(normalLow: 30, normalHigh: 110, criticalLow: null, criticalHigh: 500),
        ),
        LabDef(
          key: 'LIP',
          group: 'Other',
          label: 'Lipase',
          unit: 'U/L',
          range: const LabRange(normalLow: 0, normalHigh: 160, criticalLow: null, criticalHigh: 600),
        ),
        LabDef(
          key: 'DD',
          group: 'Other',
          label: 'D-Dimer',
          unit: 'mg/L FEU',
          range: const LabRange(normalLow: 0.0, normalHigh: 0.5, criticalLow: null, criticalHigh: 5.0),
        ),
      ],
    ),
    LabGroupDef(
      title: 'ABG',
      tests: [
        LabDef(
          key: 'PH',
          group: 'ABG',
          label: 'pH',
          unit: '',
          range: const LabRange(normalLow: 7.35, normalHigh: 7.45, criticalLow: 7.20, criticalHigh: 7.60),
        ),
        LabDef(
          key: 'PCO2',
          group: 'ABG',
          label: 'PaCO₂',
          unit: 'mmHg',
          range: const LabRange(normalLow: 35, normalHigh: 45, criticalLow: 20, criticalHigh: 60),
        ),
        LabDef(
          key: 'PO2',
          group: 'ABG',
          label: 'PaO₂',
          unit: 'mmHg',
          range: const LabRange(normalLow: 75, normalHigh: 100, criticalLow: 55, criticalHigh: null),
        ),
        LabDef(
          key: 'LAC',
          group: 'ABG',
          label: 'Lactate (LAC)',
          unit: 'mmol/L',
          range: const LabRange(normalLow: 0.5, normalHigh: 2.0, criticalLow: null, criticalHigh: 4.0),
        ),
        LabDef(
          key: 'HCO3',
          group: 'ABG',
          label: 'HCO₃⁻',
          unit: 'mmol/L',
          range: const LabRange(normalLow: 22, normalHigh: 26, criticalLow: 10, criticalHigh: 40),
        ),
      ],
    ),
    LabGroupDef(
      title: 'Fluid Balance (Optional)',
      tests: [
        LabDef(
          key: 'IN',
          group: 'Fluid',
          label: 'IN',
          unit: 'mL',
          range: const LabRange(normalLow: null, normalHigh: null, criticalLow: null, criticalHigh: null),
        ),
        LabDef(
          key: 'OUT',
          group: 'Fluid',
          label: 'OUT',
          unit: 'mL',
          range: const LabRange(normalLow: null, normalHigh: null, criticalLow: null, criticalHigh: null),
        ),
        LabDef(
          key: 'CVP',
          group: 'Fluid',
          label: 'CVP',
          unit: 'mmHg',
          range: const LabRange(normalLow: 2, normalHigh: 6, criticalLow: 0, criticalHigh: 20),
        ),
      ],
    ),
  ];

  static final Map<String, LabDef> byKey = {
    for (final g in groups)
      for (final t in g.tests) t.key: t,
  };

  static LabStatus evaluate({
    required LabDef def,
    required String gender,
    required double? value,
  }) {
    if (value == null) return LabStatus.missing;

    final r = def.rangeForGender(gender);

    final cl = r.criticalLow;
    final ch = r.criticalHigh;
    if (cl != null && value < cl) return LabStatus.critical;
    if (ch != null && value > ch) return LabStatus.critical;

    final nl = r.normalLow;
    final nh = r.normalHigh;
    if (nl != null && value < nl) return LabStatus.warning;
    if (nh != null && value > nh) return LabStatus.warning;

    if (nl == null && nh == null) return LabStatus.missing;
    return LabStatus.normal;
  }

  static LabRange effectiveRange({
    required LabDef def,
    required String gender,
    required Map<String, LabRange> overrides,
  }) {
    return overrides[def.key] ?? def.rangeForGender(gender);
  }

  static LabStatus evaluateWithRange({
    required LabRange range,
    required double? value,
  }) {
    if (value == null) return LabStatus.missing;

    final cl = range.criticalLow;
    final ch = range.criticalHigh;
    if (cl != null && value < cl) return LabStatus.critical;
    if (ch != null && value > ch) return LabStatus.critical;

    final nl = range.normalLow;
    final nh = range.normalHigh;
    if (nl != null && value < nl) return LabStatus.warning;
    if (nh != null && value > nh) return LabStatus.warning;

    if (nl == null && nh == null) return LabStatus.missing;
    return LabStatus.normal;
  }
}

// Patient-side stored lab entry (one date, many results).
class LabEntryUi {
  final DateTime date;
  final Map<String, double> values; // key -> numeric value

  const LabEntryUi({required this.date, required this.values});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'values': values,
      };

  static LabEntryUi fromJson(Map<dynamic, dynamic> json) {
    final rawValues = json['values'];
    final map = <String, double>{};
    if (rawValues is Map) {
      rawValues.forEach((k, v) {
        final key = k.toString();
        final numVal = (v is num) ? v.toDouble() : double.tryParse(v.toString());
        if (numVal != null) map[key] = numVal;
      });
    }
    return LabEntryUi(
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      values: map,
    );
  }
}

const String kCustomLabPrefix = 'custom::';

String slugGroupId(String title) =>
    title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'-+'), '-');

String encodeCustomLabKey({
  required String groupId,
  required String label,
  required String unit,
}) {
  final g = groupId.trim().isEmpty ? 'other' : groupId.trim();
  final l = label.trim();
  final u = unit.trim();
  return '$kCustomLabPrefix$g::$l::$u';
}

bool isCustomLabKey(String key) => key.startsWith(kCustomLabPrefix);

({String groupId, String label, String unit})? parseCustomLabKey(String key) {
  if (!isCustomLabKey(key)) return null;
  final rest = key.substring(kCustomLabPrefix.length);
  final parts = rest.split('::');
  if (parts.length < 2) return null;
  final groupId = parts[0].trim().isEmpty ? 'other' : parts[0].trim();
  final label = parts[1].trim();
  final unit = parts.length >= 3 ? parts[2].trim() : '';
  if (label.isEmpty) return null;
  return (groupId: groupId, label: label, unit: unit);
}
