library;
//lib/features/calculators/domain/calculators/tier1_hemodynamics.dart
/// Tier 1: Critical Hemodynamics Calculators
/// These are essential ICU/ED calculators for vital signs and critical assessments.

import 'dart:math';
import '../models/calculator_types.dart';

/// Mean Arterial Pressure Calculator
/// MAP = (SBP + 2 × DBP) / 3
class MapCalculator extends MedicalCalculator {
  @override
  String get id => 'map';

  @override
  String get shortName => 'MAP';

  @override
  String get fullName => 'Mean Arterial Pressure';

  @override
  String get description =>
      'Calculates mean arterial pressure from systolic and diastolic blood pressure.';

  @override
  String get category => 'Hemodynamics';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'sbp',
      label: 'Systolic BP',
      type: InputTypeInteger(),
      unitHint: 'mmHg',
      placeholder: '120',
      minValue: 40,
      maxValue: 300,
    ),
    const InputSpec(
      key: 'dbp',
      label: 'Diastolic BP',
      type: InputTypeInteger(),
      unitHint: 'mmHg',
      placeholder: '80',
      minValue: 20,
      maxValue: 200,
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final sbp = getDouble(inputs, 'sbp');
    final dbp = getDouble(inputs, 'dbp');

    if (sbp == null || dbp == null) {
      return CalculationResult.awaiting(
        'Please enter both systolic and diastolic BP',
      );
    }

    final map = (sbp + 2 * dbp) / 3;

    String interpretation;
    if (map < 65) {
      interpretation = 'Low - May indicate hypoperfusion';
    } else if (map <= 100) {
      interpretation = 'Normal range';
    } else {
      interpretation = 'Elevated';
    }

    return CalculationResult.success(
      value: map,
      unit: 'mmHg',
      interpretation: interpretation,
      normalRange: '70-100 mmHg',
    );
  }
}

/// Glasgow Coma Scale Calculator
/// Sum of Eye + Verbal + Motor responses
class GcsCalculator extends MedicalCalculator {
  @override
  String get id => 'gcs';

  @override
  String get shortName => 'GCS';

  @override
  String get fullName => 'Glasgow Coma Scale';

  @override
  String get description =>
      'Assesses level of consciousness after brain injury.';

  @override
  String get category => 'Hemodynamics';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'eye',
      label: 'Eye Response',
      type: InputTypeOptions([
        'None (1)',
        'To Pain (2)',
        'To Voice (3)',
        'Spontaneous (4)',
      ]),
    ),
    const InputSpec(
      key: 'verbal',
      label: 'Verbal Response',
      type: InputTypeOptions([
        'None (1)',
        'Incomprehensible (2)',
        'Inappropriate (3)',
        'Confused (4)',
        'Oriented (5)',
      ]),
    ),
    const InputSpec(
      key: 'motor',
      label: 'Motor Response',
      type: InputTypeOptions([
        'None (1)',
        'Extension (2)',
        'Flexion (3)',
        'Withdrawal (4)',
        'Localizes (5)',
        'Obeys Commands (6)',
      ]),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final eye = getOptionIndex(inputs, 'eye') + 1; // 1-4
    final verbal = getOptionIndex(inputs, 'verbal') + 1; // 1-5
    final motor = getOptionIndex(inputs, 'motor') + 1; // 1-6

    final gcs = eye + verbal + motor;

    String interpretation;
    if (gcs <= 8) {
      interpretation = 'Severe brain injury - Consider intubation';
    } else if (gcs <= 12) {
      interpretation = 'Moderate brain injury';
    } else {
      interpretation = 'Mild brain injury or normal';
    }

    return CalculationResult.success(
      value: gcs.toDouble(),
      unit: 'points',
      interpretation: interpretation,
      normalRange: '15 (fully alert)',
    );
  }
}

/// Creatinine Clearance Calculator (Cockcroft-Gault)
/// Base = (140 - Age) × Weight / (72 × SCr)
/// Female: Multiply by 0.85
class CrClCalculator extends MedicalCalculator {
  @override
  String get id => 'crcl';

  @override
  String get shortName => 'CrCl';

  @override
  String get fullName => 'Creatinine Clearance (Cockcroft-Gault)';

  @override
  String get description => 'Estimates creatinine clearance for drug dosing.';

  @override
  String get category => 'Renal & Fluids';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'age',
      label: 'Age',
      type: InputTypeInteger(),
      unitHint: 'years',
      placeholder: '60',
    ),
    const InputSpec(
      key: 'weight',
      label: 'Weight',
      type: InputTypeDecimal(),
      unitHint: 'kg',
      placeholder: '70',
    ),
    const InputSpec(
      key: 'scr',
      label: 'Serum Creatinine',
      type: InputTypeDecimal(),
      unitHint: 'mg/dL',
      placeholder: '1.0',
    ),
    const InputSpec(
      key: 'sex',
      label: 'Sex',
      type: InputTypeOptions(['Male', 'Female']),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final age = getDouble(inputs, 'age');
    final weight = getDouble(inputs, 'weight');
    final scr = getDouble(inputs, 'scr');
    final sex = getOptionIndex(inputs, 'sex');

    if (age == null || weight == null || scr == null) {
      return CalculationResult.awaiting('Please enter all required values');
    }

    if (scr <= 0) {
      return CalculationResult.error('Creatinine must be greater than 0');
    }

    double crcl = (140 - age) * weight / (72 * scr);

    // Female adjustment
    if (sex == 1) {
      crcl *= 0.85;
    }

    String interpretation;
    if (crcl >= 90) {
      interpretation = 'Normal kidney function';
    } else if (crcl >= 60) {
      interpretation = 'Mildly reduced (CKD Stage 2)';
    } else if (crcl >= 30) {
      interpretation = 'Moderately reduced (CKD Stage 3)';
    } else if (crcl >= 15) {
      interpretation = 'Severely reduced (CKD Stage 4)';
    } else {
      interpretation = 'Kidney failure (CKD Stage 5)';
    }

    return CalculationResult.success(
      value: crcl,
      unit: 'mL/min',
      interpretation: interpretation,
      normalRange: '≥90 mL/min',
    );
  }
}

/// Anion Gap Calculator
/// AG = Na - (Cl + HCO3)
class AnionGapCalculator extends MedicalCalculator {
  @override
  String get id => 'anion_gap';

  @override
  String get shortName => 'AG';

  @override
  String get fullName => 'Anion Gap';

  @override
  String get description =>
      'Calculates anion gap for metabolic acidosis workup.';

  @override
  String get category => 'Renal & Fluids';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'na',
      label: 'Sodium (Na)',
      type: InputTypeInteger(),
      unitHint: 'mEq/L',
      placeholder: '140',
    ),
    const InputSpec(
      key: 'cl',
      label: 'Chloride (Cl)',
      type: InputTypeInteger(),
      unitHint: 'mEq/L',
      placeholder: '100',
    ),
    const InputSpec(
      key: 'hco3',
      label: 'Bicarbonate (HCO3)',
      type: InputTypeInteger(),
      unitHint: 'mEq/L',
      placeholder: '24',
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final na = getDouble(inputs, 'na');
    final cl = getDouble(inputs, 'cl');
    final hco3 = getDouble(inputs, 'hco3');

    if (na == null || cl == null || hco3 == null) {
      return CalculationResult.awaiting('Please enter all electrolyte values');
    }

    final ag = na - (cl + hco3);

    String interpretation;
    if (ag < 8) {
      interpretation = 'Low anion gap - Consider hypoalbuminemia';
    } else if (ag <= 12) {
      interpretation = 'Normal anion gap';
    } else {
      interpretation =
          'Elevated - Consider MUDPILES (Methanol, Uremia, DKA, Propylene glycol, INH, Lactic acidosis, Ethylene glycol, Salicylates)';
    }

    return CalculationResult.success(
      value: ag,
      unit: 'mEq/L',
      interpretation: interpretation,
      normalRange: '8-12 mEq/L',
    );
  }
}

/// Corrected Calcium Calculator
/// Corrected Ca = Ca + 0.8 × (4.0 - Albumin)
class CorrectedCalciumCalculator extends MedicalCalculator {
  @override
  String get id => 'corrected_ca';

  @override
  String get shortName => 'Ca Corr';

  @override
  String get fullName => 'Corrected Calcium';

  @override
  String get description => 'Corrects serum calcium for albumin level.';

  @override
  String get category => 'Renal & Fluids';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'ca',
      label: 'Serum Calcium',
      type: InputTypeDecimal(),
      unitHint: 'mg/dL',
      placeholder: '9.0',
    ),
    const InputSpec(
      key: 'alb',
      label: 'Albumin',
      type: InputTypeDecimal(),
      unitHint: 'g/dL',
      placeholder: '4.0',
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final ca = getDouble(inputs, 'ca');
    final alb = getDouble(inputs, 'alb');

    if (ca == null || alb == null) {
      return CalculationResult.awaiting(
        'Please enter calcium and albumin values',
      );
    }

    final correctedCa = ca + 0.8 * (4.0 - alb);

    String interpretation;
    if (correctedCa < 8.5) {
      interpretation = 'Hypocalcemia';
    } else if (correctedCa <= 10.5) {
      interpretation = 'Normal';
    } else {
      interpretation = 'Hypercalcemia';
    }

    return CalculationResult.success(
      value: correctedCa,
      unit: 'mg/dL',
      interpretation: interpretation,
      normalRange: '8.5-10.5 mg/dL',
    );
  }
}

/// Corrected Sodium Calculator
/// Corrected Na = Na + 1.6 × ((Glucose - 100) / 100)
class CorrectedSodiumCalculator extends MedicalCalculator {
  @override
  String get id => 'corrected_na';

  @override
  String get shortName => 'Na Corr';

  @override
  String get fullName => 'Corrected Sodium';

  @override
  String get description => 'Corrects serum sodium for hyperglycemia.';

  @override
  String get category => 'Renal & Fluids';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'na',
      label: 'Serum Sodium',
      type: InputTypeInteger(),
      unitHint: 'mEq/L',
      placeholder: '135',
    ),
    const InputSpec(
      key: 'glucose',
      label: 'Glucose',
      type: InputTypeInteger(),
      unitHint: 'mg/dL',
      placeholder: '400',
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final na = getDouble(inputs, 'na');
    final glucose = getDouble(inputs, 'glucose');

    if (na == null || glucose == null) {
      return CalculationResult.awaiting(
        'Please enter sodium and glucose values',
      );
    }

    final correctedNa = na + 1.6 * ((glucose - 100) / 100);

    String interpretation;
    if (correctedNa < 135) {
      interpretation = 'Hyponatremia';
    } else if (correctedNa <= 145) {
      interpretation = 'Normal';
    } else {
      interpretation = 'Hypernatremia';
    }

    return CalculationResult.success(
      value: correctedNa,
      unit: 'mEq/L',
      interpretation: interpretation,
      normalRange: '135-145 mEq/L',
    );
  }
}

/// SIRS Criteria Calculator
/// Sum of criteria met (Temperature, HR, RR, WBC)
class SirsCalculator extends MedicalCalculator {
  @override
  String get id => 'sirs';

  @override
  String get shortName => 'SIRS';

  @override
  String get fullName => 'SIRS Criteria';

  @override
  String get description => 'Systemic Inflammatory Response Syndrome criteria.';

  @override
  String get category => 'Hemodynamics';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'temp',
      label: 'Temp >38°C or <36°C',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'hr',
      label: 'Heart Rate >90 bpm',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'rr',
      label: 'RR >20 or PaCO2 <32',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'wbc',
      label: 'WBC >12k or <4k or >10% bands',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;
    if (getBool(inputs, 'temp')) score++;
    if (getBool(inputs, 'hr')) score++;
    if (getBool(inputs, 'rr')) score++;
    if (getBool(inputs, 'wbc')) score++;

    String interpretation;
    if (score < 2) {
      interpretation = 'SIRS criteria NOT met';
    } else {
      interpretation =
          'SIRS criteria MET ($score/4) - If infection suspected, consider sepsis';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'criteria',
      interpretation: interpretation,
      normalRange: '<2 criteria',
    );
  }
}

/// SOFA Score Calculator
/// Sequential Organ Failure Assessment
class SofaCalculator extends MedicalCalculator {
  @override
  String get id => 'sofa';

  @override
  String get shortName => 'SOFA';

  @override
  String get fullName => 'SOFA Score';

  @override
  String get description =>
      'Sequential Organ Failure Assessment for ICU mortality prediction.';

  @override
  String get category => 'Major Clinical Scores';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'pao2fio2',
      label: 'PaO2/FiO2 Ratio',
      type: InputTypeOptions([
        '≥400 (0)',
        '<400 (1)',
        '<300 (2)',
        '<200 with vent (3)',
        '<100 with vent (4)',
      ]),
    ),
    const InputSpec(
      key: 'platelets',
      label: 'Platelets (×10³/µL)',
      type: InputTypeOptions([
        '≥150 (0)',
        '<150 (1)',
        '<100 (2)',
        '<50 (3)',
        '<20 (4)',
      ]),
    ),
    const InputSpec(
      key: 'bilirubin',
      label: 'Bilirubin (mg/dL)',
      type: InputTypeOptions([
        '<1.2 (0)',
        '1.2-1.9 (1)',
        '2.0-5.9 (2)',
        '6.0-11.9 (3)',
        '≥12.0 (4)',
      ]),
    ),
    const InputSpec(
      key: 'cardiovascular',
      label: 'Cardiovascular',
      type: InputTypeOptions([
        'MAP ≥70 (0)',
        'MAP <70 (1)',
        'Dopamine ≤5 (2)',
        'Dopamine >5 or Epi ≤0.1 (3)',
        'Dopamine >15 or Epi >0.1 (4)',
      ]),
    ),
    const InputSpec(
      key: 'gcs',
      label: 'Glasgow Coma Scale',
      type: InputTypeOptions([
        '15 (0)',
        '13-14 (1)',
        '10-12 (2)',
        '6-9 (3)',
        '<6 (4)',
      ]),
    ),
    const InputSpec(
      key: 'creatinine',
      label: 'Creatinine (mg/dL)',
      type: InputTypeOptions([
        '<1.2 (0)',
        '1.2-1.9 (1)',
        '2.0-3.4 (2)',
        '3.5-4.9 (3)',
        '≥5.0 (4)',
      ]),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;
    score += getOptionIndex(inputs, 'pao2fio2');
    score += getOptionIndex(inputs, 'platelets');
    score += getOptionIndex(inputs, 'bilirubin');
    score += getOptionIndex(inputs, 'cardiovascular');
    score += getOptionIndex(inputs, 'gcs');
    score += getOptionIndex(inputs, 'creatinine');

    String interpretation;
    String mortality;
    if (score <= 1) {
      mortality = '<3.3%';
      interpretation = 'Low mortality risk';
    } else if (score <= 3) {
      mortality = '~6.4%';
      interpretation = 'Low-moderate mortality risk';
    } else if (score <= 5) {
      mortality = '~13.5%';
      interpretation = 'Moderate mortality risk';
    } else if (score <= 7) {
      mortality = '~21.8%';
      interpretation = 'Moderate-high mortality risk';
    } else if (score <= 9) {
      mortality = '~33.3%';
      interpretation = 'High mortality risk';
    } else if (score <= 11) {
      mortality = '~50%';
      interpretation = 'Very high mortality risk';
    } else {
      mortality = '>95%';
      interpretation = 'Extremely high mortality risk';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: '$interpretation (ICU mortality: $mortality)',
      normalRange: '0 points',
    );
  }
}

/// QTc Calculator (Bazett Formula)
/// QTc = QT / √(60/HR) = QT / √(RR interval)
class QtcCalculator extends MedicalCalculator {
  @override
  String get id => 'qtc';

  @override
  String get shortName => 'QTc';

  @override
  String get fullName => 'Corrected QT Interval';

  @override
  String get description =>
      'Calculates heart rate-corrected QT interval using Bazett formula.';

  @override
  String get category => 'Hemodynamics';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'qt',
      label: 'QT Interval',
      type: InputTypeInteger(),
      unitHint: 'ms',
      placeholder: '400',
    ),
    const InputSpec(
      key: 'hr',
      label: 'Heart Rate',
      type: InputTypeInteger(),
      unitHint: 'bpm',
      placeholder: '70',
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final qt = getDouble(inputs, 'qt');
    final hr = getDouble(inputs, 'hr');

    if (qt == null || hr == null) {
      return CalculationResult.awaiting(
        'Please enter QT interval and heart rate',
      );
    }

    if (hr <= 0) {
      return CalculationResult.error('Heart rate must be greater than 0');
    }

    // Bazett formula: QTc = QT / √(RR)
    // RR interval in seconds = 60/HR
    final rrSeconds = 60 / hr;
    final qtc = qt / sqrt(rrSeconds);

    String interpretation;
    if (qtc < 350) {
      interpretation = 'Short QTc - Consider genetic syndromes';
    } else if (qtc <= 440) {
      interpretation = 'Normal QTc';
    } else if (qtc <= 500) {
      interpretation = 'Prolonged QTc - Monitor and review medications';
    } else {
      interpretation = 'Markedly prolonged - HIGH RISK for Torsades de Pointes';
    }

    return CalculationResult.success(
      value: qtc,
      unit: 'ms',
      interpretation: interpretation,
      normalRange: '350-440 ms',
    );
  }
}
