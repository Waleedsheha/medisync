library;
//lib/features/calculators/domain/calculators/tier5_liver_gi.dart
/// Tier 5: Liver & GI Calculators
/// Liver disease severity and fibrosis assessment.

import 'dart:math';
import '../models/calculator_types.dart';

/// Child-Pugh Score for Cirrhosis
class ChildPughCalculator extends MedicalCalculator {
  @override
  String get id => 'child_pugh';

  @override
  String get shortName => 'Child-Pugh';

  @override
  String get fullName => 'Child-Pugh Score';

  @override
  String get description =>
      'Classifies severity of cirrhosis and predicts survival.';

  @override
  String get category => 'Liver';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'bilirubin',
      label: 'Total Bilirubin (mg/dL)',
      type: InputTypeOptions([
        '<2 (1 point)',
        '2-3 (2 points)',
        '>3 (3 points)',
      ]),
    ),
    const InputSpec(
      key: 'albumin',
      label: 'Albumin (g/dL)',
      type: InputTypeOptions([
        '>3.5 (1 point)',
        '2.8-3.5 (2 points)',
        '<2.8 (3 points)',
      ]),
    ),
    const InputSpec(
      key: 'inr',
      label: 'INR',
      type: InputTypeOptions([
        '<1.7 (1 point)',
        '1.7-2.3 (2 points)',
        '>2.3 (3 points)',
      ]),
    ),
    const InputSpec(
      key: 'ascites',
      label: 'Ascites',
      type: InputTypeOptions([
        'None (1 point)',
        'Slight/Controlled (2 points)',
        'Moderate/Severe (3 points)',
      ]),
    ),
    const InputSpec(
      key: 'encephalopathy',
      label: 'Hepatic Encephalopathy',
      type: InputTypeOptions([
        'None (1 point)',
        'Grade 1-2 (2 points)',
        'Grade 3-4 (3 points)',
      ]),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    // Each option index (0, 1, 2) corresponds to 1, 2, 3 points
    int score = 0;
    score += getOptionIndex(inputs, 'bilirubin') + 1;
    score += getOptionIndex(inputs, 'albumin') + 1;
    score += getOptionIndex(inputs, 'inr') + 1;
    score += getOptionIndex(inputs, 'ascites') + 1;
    score += getOptionIndex(inputs, 'encephalopathy') + 1;

    String classLabel;
    String survival;
    String interpretation;

    if (score <= 6) {
      classLabel = 'A';
      survival = '100% 1-year, 85% 2-year';
      interpretation = 'Well-compensated disease';
    } else if (score <= 9) {
      classLabel = 'B';
      survival = '81% 1-year, 57% 2-year';
      interpretation = 'Significant functional compromise';
    } else {
      classLabel = 'C';
      survival = '45% 1-year, 35% 2-year';
      interpretation = 'Decompensated disease';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation:
          'Class $classLabel: $interpretation (Survival: $survival)',
      normalRange: '5-6 = Class A',
    );
  }
}

/// MELD-Na Score
/// For liver transplant prioritization and mortality prediction
class MeldNaCalculator extends MedicalCalculator {
  @override
  String get id => 'meld_na';

  @override
  String get shortName => 'MELD-Na';

  @override
  String get fullName => 'MELD-Na Score';

  @override
  String get description =>
      'Model for End-Stage Liver Disease with sodium correction.';

  @override
  String get category => 'Liver';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'bilirubin',
      label: 'Bilirubin',
      type: InputTypeDecimal(),
      unitHint: 'mg/dL',
      placeholder: '2.0',
    ),
    const InputSpec(
      key: 'inr',
      label: 'INR',
      type: InputTypeDecimal(),
      placeholder: '1.5',
    ),
    const InputSpec(
      key: 'creatinine',
      label: 'Creatinine',
      type: InputTypeDecimal(),
      unitHint: 'mg/dL',
      placeholder: '1.0',
    ),
    const InputSpec(
      key: 'sodium',
      label: 'Sodium',
      type: InputTypeInteger(),
      unitHint: 'mEq/L',
      placeholder: '138',
    ),
    const InputSpec(
      key: 'dialysis',
      label: 'Dialysis (≥2 times in past week)',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    var bilirubin = getDouble(inputs, 'bilirubin');
    var inr = getDouble(inputs, 'inr');
    var creatinine = getDouble(inputs, 'creatinine');
    var sodium = getDouble(inputs, 'sodium');
    final dialysis = getBool(inputs, 'dialysis');

    if (bilirubin == null ||
        inr == null ||
        creatinine == null ||
        sodium == null) {
      return CalculationResult.awaiting('Please enter all values');
    }

    // Apply floor values
    if (bilirubin < 1) bilirubin = 1;
    if (inr < 1) inr = 1;
    if (creatinine < 1) creatinine = 1;
    if (creatinine > 4 || dialysis) creatinine = 4; // Cap at 4

    // Bound sodium
    if (sodium < 125) sodium = 125;
    if (sodium > 137) sodium = 137;

    // MELD(i) calculation
    final meldI =
        0.957 * log(creatinine) +
        0.378 * log(bilirubin) +
        1.120 * log(inr) +
        0.643;

    final meldBase = (meldI * 10).roundToDouble();

    // MELD-Na calculation
    final meldNa =
        meldBase + 1.32 * (137 - sodium) - (0.033 * meldBase * (137 - sodium));

    // Bound final score
    final finalScore = meldNa.clamp(6, 40);

    String interpretation;
    if (finalScore < 10) {
      interpretation = '3-month mortality ~2%';
    } else if (finalScore < 20) {
      interpretation = '3-month mortality ~6%';
    } else if (finalScore < 30) {
      interpretation = '3-month mortality ~20%';
    } else if (finalScore < 40) {
      interpretation = '3-month mortality ~53%';
    } else {
      interpretation = '3-month mortality ~71%';
    }

    return CalculationResult.success(
      value: finalScore.toDouble(),
      unit: 'points',
      interpretation: interpretation,
      normalRange: '<10 = Low mortality',
    );
  }
}

/// FIB-4 Score for Liver Fibrosis
class Fib4Calculator extends MedicalCalculator {
  @override
  String get id => 'fib4';

  @override
  String get shortName => 'FIB-4';

  @override
  String get fullName => 'FIB-4 Index';

  @override
  String get description => 'Non-invasive estimate of liver fibrosis.';

  @override
  String get category => 'Liver';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'age',
      label: 'Age',
      type: InputTypeInteger(),
      unitHint: 'years',
      placeholder: '55',
    ),
    const InputSpec(
      key: 'ast',
      label: 'AST',
      type: InputTypeInteger(),
      unitHint: 'U/L',
      placeholder: '45',
    ),
    const InputSpec(
      key: 'alt',
      label: 'ALT',
      type: InputTypeInteger(),
      unitHint: 'U/L',
      placeholder: '40',
    ),
    const InputSpec(
      key: 'platelets',
      label: 'Platelets',
      type: InputTypeInteger(),
      unitHint: '×10⁹/L',
      placeholder: '180',
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final age = getDouble(inputs, 'age');
    final ast = getDouble(inputs, 'ast');
    final alt = getDouble(inputs, 'alt');
    final platelets = getDouble(inputs, 'platelets');

    if (age == null || ast == null || alt == null || platelets == null) {
      return CalculationResult.awaiting('Please enter all values');
    }

    if (alt <= 0 || platelets <= 0) {
      return CalculationResult.error('ALT and platelets must be > 0');
    }

    // FIB-4 = (Age × AST) / (Platelets × √ALT)
    final fib4 = (age * ast) / (platelets * sqrt(alt));

    String interpretation;
    if (fib4 < 1.30) {
      interpretation = 'Low probability of advanced fibrosis (F0-F2)';
    } else if (fib4 <= 2.67) {
      interpretation = 'Indeterminate - Consider liver biopsy or elastography';
    } else {
      interpretation = 'High probability of advanced fibrosis (F3-F4)';
    }

    return CalculationResult.success(
      value: fib4,
      unit: '',
      interpretation: interpretation,
      normalRange: '<1.30 = Low fibrosis risk',
    );
  }
}
