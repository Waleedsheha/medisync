//lib/core/models/drug.dart
import 'package:hive/hive.dart';

part 'drug.g.dart';

/// Main Drug model with Hive persistence - Single table schema
@HiveType(typeId: 20)
class Drug extends HiveObject {
  @HiveField(0)
  final String id; // RxCUI from RxNorm

  @HiveField(1)
  final String genericName;

  @HiveField(2)
  final List<String> tradeNames;

  @HiveField(14)
  final List<String> sideEffects; // All side effects

  @HiveField(15)
  final List<String> commonSideEffects; // >1% occurrence

  @HiveField(16)
  final List<String> rareSideEffects; // <0.1% occurrence

  @HiveField(17)
  final List<String> seriousSideEffects; // Life-threatening

  @HiveField(3)
  final String? drugClass;

  @HiveField(4)
  final String? mechanism;

  @HiveField(5)
  final List<String> indications;

  @HiveField(6)
  final List<String> contraindications;

  @HiveField(7)
  final List<String> warnings;

  @HiveField(8)
  final List<String> blackBoxWarnings;

  @HiveField(10)
  final List<String> interactsWith; // List of drug IDs that interact

  // Standard Dosing (flattened from DosageInfo)
  @HiveField(18)
  final String? standardDoseIndication;

  @HiveField(19)
  final String? standardDoseRoute;

  @HiveField(20)
  final String? standardDose;

  @HiveField(21)
  final String? standardDoseFrequency;

  @HiveField(22)
  final String? standardDoseDuration;

  @HiveField(23)
  final String? standardDoseNotes;

  // Special Populations
  @HiveField(24)
  final String? geriatricNotes;

  @HiveField(25)
  final String? maxDailyDose;

  // Renal Dosing (flattened)
  @HiveField(26)
  final String? renalCrclGt50;

  @HiveField(27)
  final String? renalCrcl30_50;

  @HiveField(28)
  final String? renalCrcl10_30;

  @HiveField(29)
  final String? renalCrclLt10;

  @HiveField(30)
  final String? renalDialysis;

  @HiveField(31)
  final String? renalNotes;

  // Hepatic Dosing (flattened)
  @HiveField(32)
  final String? hepaticChildPughA;

  @HiveField(33)
  final String? hepaticChildPughB;

  @HiveField(34)
  final String? hepaticChildPughC;

  @HiveField(35)
  final String? hepaticNotes;

  // Pediatric Dosing (flattened)
  @HiveField(36)
  final String? pediatricNeonates;

  @HiveField(37)
  final String? pediatricInfants;

  @HiveField(38)
  final String? pediatricChildren;

  @HiveField(39)
  final String? pediatricAdolescents;

  @HiveField(40)
  final String? pediatricWeightBased;

  @HiveField(41)
  final String? pediatricNotes;

  @HiveField(42)
  final DosageInfo? dosageInfo;

  @HiveField(11)
  final DateTime cachedAt;

  Drug({
    required this.id,
    required this.genericName,
    this.tradeNames = const [],
    this.sideEffects = const [],
    this.commonSideEffects = const [],
    this.rareSideEffects = const [],
    this.seriousSideEffects = const [],
    this.drugClass,
    this.mechanism,
    this.indications = const [],
    this.contraindications = const [],
    this.warnings = const [],
    this.blackBoxWarnings = const [],
    this.interactsWith = const [],
    // Standard dosing
    String? standardDoseIndication,
    String? standardDoseRoute,
    String? standardDose,
    String? standardDoseFrequency,
    String? standardDoseDuration,
    String? standardDoseNotes,
    // Special populations
    String? geriatricNotes,
    String? maxDailyDose,
    // Renal
    String? renalCrclGt50,
    String? renalCrcl30_50,
    String? renalCrcl10_30,
    String? renalCrclLt10,
    String? renalDialysis,
    String? renalNotes,
    // Hepatic
    String? hepaticChildPughA,
    String? hepaticChildPughB,
    String? hepaticChildPughC,
    String? hepaticNotes,
    // Pediatric
    String? pediatricNeonates,
    String? pediatricInfants,
    String? pediatricChildren,
    String? pediatricAdolescents,
    String? pediatricWeightBased,
    String? pediatricNotes,
    this.dosageInfo,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now(),
       standardDoseIndication =
           standardDoseIndication ??
           (dosageInfo != null && dosageInfo.standardDoses.isNotEmpty
               ? dosageInfo.standardDoses.first.indication
               : null),
       standardDoseRoute =
           standardDoseRoute ??
           (dosageInfo != null && dosageInfo.standardDoses.isNotEmpty
               ? dosageInfo.standardDoses.first.route
               : null),
       standardDose =
           standardDose ??
           (dosageInfo != null && dosageInfo.standardDoses.isNotEmpty
               ? dosageInfo.standardDoses.first.dose
               : null),
       standardDoseFrequency =
           standardDoseFrequency ??
           (dosageInfo != null && dosageInfo.standardDoses.isNotEmpty
               ? dosageInfo.standardDoses.first.frequency
               : null),
       standardDoseDuration =
           standardDoseDuration ??
           (dosageInfo != null && dosageInfo.standardDoses.isNotEmpty
               ? dosageInfo.standardDoses.first.duration
               : null),
       standardDoseNotes =
           standardDoseNotes ??
           (dosageInfo != null && dosageInfo.standardDoses.isNotEmpty
               ? dosageInfo.standardDoses.first.notes
               : null),
       geriatricNotes = geriatricNotes ?? dosageInfo?.geriatricNotes,
       maxDailyDose = maxDailyDose ?? dosageInfo?.maxDailyDose,
       renalCrclGt50 = renalCrclGt50 ?? dosageInfo?.renalDosing?.crClGreater50,
       renalCrcl30_50 = renalCrcl30_50 ?? dosageInfo?.renalDosing?.crCl30to50,
       renalCrcl10_30 = renalCrcl10_30 ?? dosageInfo?.renalDosing?.crCl10to30,
       renalCrclLt10 = renalCrclLt10 ?? dosageInfo?.renalDosing?.crClLess10,
       renalDialysis = renalDialysis ?? dosageInfo?.renalDosing?.dialysis,
       renalNotes = renalNotes ?? dosageInfo?.renalDosing?.notes,
       hepaticChildPughA =
           hepaticChildPughA ?? dosageInfo?.hepaticDosing?.childPughA,
       hepaticChildPughB =
           hepaticChildPughB ?? dosageInfo?.hepaticDosing?.childPughB,
       hepaticChildPughC =
           hepaticChildPughC ?? dosageInfo?.hepaticDosing?.childPughC,
       hepaticNotes = hepaticNotes ?? dosageInfo?.hepaticDosing?.notes,
       pediatricNeonates =
           pediatricNeonates ?? dosageInfo?.pediatricDosing?.neonates,
       pediatricInfants =
           pediatricInfants ?? dosageInfo?.pediatricDosing?.infants,
       pediatricChildren =
           pediatricChildren ?? dosageInfo?.pediatricDosing?.children,
       pediatricAdolescents =
           pediatricAdolescents ?? dosageInfo?.pediatricDosing?.adolescents,
       pediatricWeightBased =
           pediatricWeightBased ?? dosageInfo?.pediatricDosing?.weightBased,
       pediatricNotes = pediatricNotes ?? dosageInfo?.pediatricDosing?.notes;

  /// Check if cache is stale (older than 30 days)
  bool get isStale => DateTime.now().difference(cachedAt).inDays > 30;

  /// Search-friendly string
  String get searchText => '$genericName ${tradeNames.join(' ')}'.toLowerCase();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'genericName': genericName,
      'tradeNames': tradeNames,
      'sideEffects': sideEffects,
      'commonSideEffects': commonSideEffects,
      'rareSideEffects': rareSideEffects,
      'seriousSideEffects': seriousSideEffects,
      'drugClass': drugClass,
      'mechanism': mechanism,
      'indications': indications,
      'contraindications': contraindications,
      'warnings': warnings,
      'blackBoxWarnings': blackBoxWarnings,
      'interactsWith': interactsWith,
      'standardDoseIndication': standardDoseIndication,
      'standardDoseRoute': standardDoseRoute,
      'standardDose': standardDose,
      'standardDoseFrequency': standardDoseFrequency,
      'standardDoseDuration': standardDoseDuration,
      'standardDoseNotes': standardDoseNotes,
      'geriatricNotes': geriatricNotes,
      'maxDailyDose': maxDailyDose,
      'renalCrclGt50': renalCrclGt50,
      'renalCrcl30_50': renalCrcl30_50,
      'renalCrcl10_30': renalCrcl10_30,
      'renalCrclLt10': renalCrclLt10,
      'renalDialysis': renalDialysis,
      'renalNotes': renalNotes,
      'hepaticChildPughA': hepaticChildPughA,
      'hepaticChildPughB': hepaticChildPughB,
      'hepaticChildPughC': hepaticChildPughC,
      'hepaticNotes': hepaticNotes,
      'pediatricNeonates': pediatricNeonates,
      'pediatricInfants': pediatricInfants,
      'pediatricChildren': pediatricChildren,
      'pediatricAdolescents': pediatricAdolescents,
      'pediatricWeightBased': pediatricWeightBased,
      'pediatricNotes': pediatricNotes,
      'dosageInfo': dosageInfo?.toJson(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  factory Drug.fromJson(Map<String, dynamic> json) {
    return Drug(
      id: json['id'],
      genericName: json['genericName'] ?? json['generic_name'] ?? '',
      tradeNames: List<String>.from(
        json['tradeNames'] ?? json['brandNames'] ?? json['trade_names'] ?? [],
      ),
      sideEffects: List<String>.from(
        json['sideEffects'] ?? json['side_effects'] ?? [],
      ),
      commonSideEffects: List<String>.from(
        json['commonSideEffects'] ?? json['common_side_effects'] ?? [],
      ),
      rareSideEffects: List<String>.from(
        json['rareSideEffects'] ?? json['rare_side_effects'] ?? [],
      ),
      seriousSideEffects: List<String>.from(
        json['seriousSideEffects'] ?? json['serious_side_effects'] ?? [],
      ),
      drugClass: json['drugClass'] ?? json['drug_class'],
      mechanism: json['mechanism'],
      indications: List<String>.from(json['indications'] ?? []),
      contraindications: List<String>.from(json['contraindications'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      blackBoxWarnings: List<String>.from(
        json['blackBoxWarnings'] ?? json['black_box_warnings'] ?? [],
      ),
      interactsWith: List<String>.from(
        json['interactsWith'] ?? json['interacts_with'] ?? [],
      ),
      standardDoseIndication:
          json['standardDoseIndication'] ?? json['standard_dose_indication'],
      standardDoseRoute:
          json['standardDoseRoute'] ?? json['standard_dose_route'],
      standardDose: json['standardDose'] ?? json['standard_dose'],
      standardDoseFrequency:
          json['standardDoseFrequency'] ?? json['standard_dose_frequency'],
      standardDoseDuration:
          json['standardDoseDuration'] ?? json['standard_dose_duration'],
      standardDoseNotes:
          json['standardDoseNotes'] ?? json['standard_dose_notes'],
      geriatricNotes: json['geriatricNotes'] ?? json['geriatric_notes'],
      maxDailyDose: json['maxDailyDose'] ?? json['max_daily_dose'],
      renalCrclGt50: json['renalCrclGt50'] ?? json['renal_crcl_gt_50'],
      renalCrcl30_50: json['renalCrcl30_50'] ?? json['renal_crcl_30_50'],
      renalCrcl10_30: json['renalCrcl10_30'] ?? json['renal_crcl_10_30'],
      renalCrclLt10: json['renalCrclLt10'] ?? json['renal_crcl_lt_10'],
      renalDialysis: json['renalDialysis'] ?? json['renal_dialysis'],
      renalNotes: json['renalNotes'] ?? json['renal_notes'],
      hepaticChildPughA:
          json['hepaticChildPughA'] ?? json['hepatic_child_pugh_a'],
      hepaticChildPughB:
          json['hepaticChildPughB'] ?? json['hepatic_child_pugh_b'],
      hepaticChildPughC:
          json['hepaticChildPughC'] ?? json['hepatic_child_pugh_c'],
      hepaticNotes: json['hepaticNotes'] ?? json['hepatic_notes'],
      pediatricNeonates:
          json['pediatricNeonates'] ?? json['pediatric_neonates'],
      pediatricInfants: json['pediatricInfants'] ?? json['pediatric_infants'],
      pediatricChildren:
          json['pediatricChildren'] ?? json['pediatric_children'],
      pediatricAdolescents:
          json['pediatricAdolescents'] ?? json['pediatric_adolescents'],
      pediatricWeightBased:
          json['pediatricWeightBased'] ?? json['pediatric_weight_based'],
      pediatricNotes: json['pediatricNotes'] ?? json['pediatric_notes'],
      dosageInfo: json['dosageInfo'] != null
          ? DosageInfo.fromJson(json['dosageInfo'])
          : null,
      cachedAt: json['cachedAt'] != null || json['cached_at'] != null
          ? DateTime.parse(json['cachedAt'] ?? json['cached_at'])
          : DateTime.now(),
    );
  }
}

/// Complete dosage information
@HiveType(typeId: 21)
class DosageInfo extends HiveObject {
  @HiveField(0)
  final List<StandardDose> standardDoses;

  @HiveField(1)
  final RenalDosing? renalDosing;

  @HiveField(2)
  final HepaticDosing? hepaticDosing;

  @HiveField(3)
  final PediatricDosing? pediatricDosing;

  @HiveField(4)
  final String? geriatricNotes;

  @HiveField(5)
  final String? maxDailyDose;

  DosageInfo({
    this.standardDoses = const [],
    this.renalDosing,
    this.hepaticDosing,
    this.pediatricDosing,
    this.geriatricNotes,
    this.maxDailyDose,
  });

  Map<String, dynamic> toJson() {
    return {
      'standardDoses': standardDoses.map((e) => e.toJson()).toList(),
      'renalDosing': renalDosing?.toJson(),
      'hepaticDosing': hepaticDosing?.toJson(),
      'pediatricDosing': pediatricDosing?.toJson(),
      'geriatricNotes': geriatricNotes,
      'maxDailyDose': maxDailyDose,
    };
  }

  factory DosageInfo.fromJson(Map<String, dynamic> json) {
    return DosageInfo(
      standardDoses:
          (json['standardDoses'] as List?)
              ?.map((e) => StandardDose.fromJson(e))
              .toList() ??
          [],
      renalDosing: json['renalDosing'] != null
          ? RenalDosing.fromJson(json['renalDosing'])
          : null,
      hepaticDosing: json['hepaticDosing'] != null
          ? HepaticDosing.fromJson(json['hepaticDosing'])
          : null,
      pediatricDosing: json['pediatricDosing'] != null
          ? PediatricDosing.fromJson(json['pediatricDosing'])
          : null,
      geriatricNotes: json['geriatricNotes'],
      maxDailyDose: json['maxDailyDose'],
    );
  }
}

/// Standard dosing by indication
@HiveType(typeId: 22)
class StandardDose extends HiveObject {
  @HiveField(0)
  final String indication; // e.g., "Hypertension"

  @HiveField(1)
  final String route; // e.g., "Oral", "IV", "IM"

  @HiveField(2)
  final String dose; // e.g., "5-10mg"

  @HiveField(3)
  final String frequency; // e.g., "Once daily", "BID", "TID"

  @HiveField(4)
  final String? duration; // e.g., "7-14 days"

  @HiveField(5)
  final String? notes;

  StandardDose({
    required this.indication,
    required this.route,
    required this.dose,
    required this.frequency,
    this.duration,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'indication': indication,
      'route': route,
      'dose': dose,
      'frequency': frequency,
      'duration': duration,
      'notes': notes,
    };
  }

  factory StandardDose.fromJson(Map<String, dynamic> json) {
    return StandardDose(
      indication: json['indication'],
      route: json['route'],
      dose: json['dose'],
      frequency: json['frequency'],
      duration: json['duration'],
      notes: json['notes'],
    );
  }
}

/// Renal dosing adjustments by GFR
@HiveType(typeId: 23)
class RenalDosing extends HiveObject {
  @HiveField(0)
  final String crClGreater50; // Normal/Mild: CrCl > 50 mL/min

  @HiveField(1)
  final String crCl30to50; // Moderate: CrCl 30-50 mL/min

  @HiveField(2)
  final String crCl10to30; // Severe: CrCl 10-30 mL/min

  @HiveField(3)
  final String crClLess10; // ESRD: CrCl < 10 mL/min

  @HiveField(4)
  final String? dialysis; // HD/PD dosing

  @HiveField(5)
  final String? notes;

  RenalDosing({
    this.crClGreater50 = '-',
    this.crCl30to50 = '-',
    this.crCl10to30 = '-',
    this.crClLess10 = '-',
    this.dialysis,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'crClGreater50': crClGreater50,
      'crCl30to50': crCl30to50,
      'crCl10to30': crCl10to30,
      'crClLess10': crClLess10,
      'dialysis': dialysis,
      'notes': notes,
    };
  }

  factory RenalDosing.fromJson(Map<String, dynamic> json) {
    return RenalDosing(
      crClGreater50: json['crClGreater50'] ?? '-',
      crCl30to50: json['crCl30to50'] ?? '-',
      crCl10to30: json['crCl10to30'] ?? '-',
      crClLess10: json['crClLess10'] ?? '-',
      dialysis: json['dialysis'],
      notes: json['notes'],
    );
  }
}

/// Hepatic dosing by Child-Pugh class
@HiveType(typeId: 24)
class HepaticDosing extends HiveObject {
  @HiveField(0)
  final String childPughA; // Mild impairment

  @HiveField(1)
  final String childPughB; // Moderate impairment

  @HiveField(2)
  final String childPughC; // Severe impairment

  @HiveField(3)
  final String? notes;

  HepaticDosing({
    required this.childPughA,
    required this.childPughB,
    required this.childPughC,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'childPughA': childPughA,
      'childPughB': childPughB,
      'childPughC': childPughC,
      'notes': notes,
    };
  }

  factory HepaticDosing.fromJson(Map<String, dynamic> json) {
    return HepaticDosing(
      childPughA: json['childPughA'],
      childPughB: json['childPughB'],
      childPughC: json['childPughC'],
      notes: json['notes'],
    );
  }
}

/// Pediatric dosing by age group
@HiveType(typeId: 25)
class PediatricDosing extends HiveObject {
  @HiveField(0)
  final String? neonates; // 0-28 days

  @HiveField(1)
  final String? infants; // 1-12 months

  @HiveField(2)
  final String? children; // 1-12 years

  @HiveField(3)
  final String? adolescents; // 12-18 years

  @HiveField(4)
  final String? weightBased; // mg/kg dosing formula

  @HiveField(5)
  final String? notes;

  PediatricDosing({
    this.neonates,
    this.infants,
    this.children,
    this.adolescents,
    this.weightBased,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'neonates': neonates,
      'infants': infants,
      'children': children,
      'adolescents': adolescents,
      'weightBased': weightBased,
      'notes': notes,
    };
  }

  factory PediatricDosing.fromJson(Map<String, dynamic> json) {
    return PediatricDosing(
      neonates: json['neonates'],
      infants: json['infants'],
      children: json['children'],
      adolescents: json['adolescents'],
      weightBased: json['weightBased'],
      notes: json['notes'],
    );
  }
}
