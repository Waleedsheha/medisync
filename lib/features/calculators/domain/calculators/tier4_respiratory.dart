//lib/features/calculators/domain/calculators/tier4_respiratory.dart
library;

/// Tier 4: Respiratory Calculators
/// Pneumonia severity and sleep apnea risk assessment.

import '../models/calculator_types.dart';

/// CURB-65 Score for Pneumonia Severity
class Curb65Calculator extends MedicalCalculator {
  @override
  String get id => 'curb65';

  @override
  String get shortName => 'CURB-65';

  @override
  String get fullName => 'CURB-65 Score';

  @override
  String get description =>
      'Severity assessment for community-acquired pneumonia.';

  @override
  String get category => 'Respiratory';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'confusion',
      label: 'Confusion (new onset)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'bun',
      label: 'BUN >19 mg/dL (or Urea >7 mmol/L)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'rr',
      label: 'Respiratory rate ≥30/min',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'bp',
      label: 'Blood pressure: SBP <90 or DBP ≤60',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'age',
      label: 'Age ≥65 years',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    if (getBool(inputs, 'confusion')) score++;
    if (getBool(inputs, 'bun')) score++;
    if (getBool(inputs, 'rr')) score++;
    if (getBool(inputs, 'bp')) score++;
    if (getBool(inputs, 'age')) score++;

    String interpretation;
    String mortality;
    String disposition;
    if (score <= 1) {
      mortality = '0.6-2.7%';
      disposition = 'Outpatient';
      interpretation = 'Low severity - Consider outpatient treatment';
    } else if (score == 2) {
      mortality = '6.8%';
      disposition = 'Admit/Observe';
      interpretation = 'Moderate severity - Consider hospital admission';
    } else {
      mortality = '14-27%';
      disposition = 'ICU';
      interpretation = 'High severity - ICU admission likely needed';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation:
          '$interpretation. Management: $disposition. (30-day mortality: $mortality)',
      normalRange: '0-1 = Low risk',
    );
  }
}

/// STOP-BANG Score for Obstructive Sleep Apnea
class StopBangCalculator extends MedicalCalculator {
  @override
  String get id => 'stop_bang';

  @override
  String get shortName => 'STOP-BANG';

  @override
  String get fullName => 'STOP-BANG Score';

  @override
  String get description =>
      'Screening questionnaire for obstructive sleep apnea.';

  @override
  String get category => 'Respiratory';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'snoring',
      label: 'S - Snoring loudly',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'tired',
      label: 'T - Tired/fatigued/sleepy during day',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'observed',
      label: 'O - Observed to stop breathing during sleep',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'pressure',
      label: 'P - Pressure (treated for high BP)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'bmi',
      label: 'B - BMI >35 kg/m²',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'age',
      label: 'A - Age >50 years',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'neck',
      label: 'N - Neck circumference >40 cm (16 in)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'gender',
      label: 'G - Gender male',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    if (getBool(inputs, 'snoring')) score++;
    if (getBool(inputs, 'tired')) score++;
    if (getBool(inputs, 'observed')) score++;
    if (getBool(inputs, 'pressure')) score++;
    if (getBool(inputs, 'bmi')) score++;
    if (getBool(inputs, 'age')) score++;
    if (getBool(inputs, 'neck')) score++;
    if (getBool(inputs, 'gender')) score++;

    String interpretation;
    if (score <= 2) {
      interpretation = 'Low risk for OSA';
    } else if (score <= 4) {
      interpretation = 'Intermediate risk for OSA - Consider sleep study';
    } else {
      interpretation = 'High risk for OSA - Sleep study strongly recommended';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: interpretation,
      normalRange: '≤2 = Low risk',
    );
  }
}
