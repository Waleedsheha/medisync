library;
//lib/features/calculators/domain/calculators/tier7_clinical_scores.dart
/// Tier 7: Major Clinical Scores
/// Critical scoring systems for risk stratification and clinical decision-making.

import '../models/calculator_types.dart';

/// TIMI Risk Score for UA/NSTEMI
class TimiNstemiCalculator extends MedicalCalculator {
  @override
  String get id => 'timi_nstemi';

  @override
  String get shortName => 'TIMI';

  @override
  String get fullName => 'TIMI Risk Score (UA/NSTEMI)';

  @override
  String get description =>
      'Predicts cardiac events in unstable angina/NSTEMI patients.';

  @override
  String get category => 'Major Clinical Scores';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'age_65',
      label: 'Age ≥65 years',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'cad_risk_factors',
      label: '≥3 CAD Risk Factors (HTN, Lipids, DM, Smoking, FHx)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'known_cad',
      label: 'Known CAD (stenosis ≥50%)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'aspirin',
      label: 'Aspirin use in past 7 days',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'severe_angina',
      label: 'Severe angina (≥2 episodes in 24h)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'st_deviation',
      label: 'ST-segment deviation ≥0.5mm',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'elevated_markers',
      label: 'Elevated cardiac markers (troponin)',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    if (getBool(inputs, 'age_65')) score++;
    if (getBool(inputs, 'cad_risk_factors')) score++;
    if (getBool(inputs, 'known_cad')) score++;
    if (getBool(inputs, 'aspirin')) score++;
    if (getBool(inputs, 'severe_angina')) score++;
    if (getBool(inputs, 'st_deviation')) score++;
    if (getBool(inputs, 'elevated_markers')) score++;

    String interpretation;
    String risk;
    if (score <= 2) {
      risk = '3-8%';
      interpretation = 'Low Risk - Consider early discharge pathway';
    } else if (score <= 4) {
      risk = '13-20%';
      interpretation =
          'Intermediate Risk - Admit, serial troponins, consider early invasive strategy';
    } else {
      risk = '26-41%';
      interpretation = 'High Risk - Early invasive strategy recommended';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: '$interpretation (14-day event risk: $risk)',
      normalRange: '0-2 = Low risk',
    );
  }
}

/// Revised Geneva Score for PE
class GenevaCalculator extends MedicalCalculator {
  @override
  String get id => 'geneva_revised';

  @override
  String get shortName => 'Geneva';

  @override
  String get fullName => 'Revised Geneva Score';

  @override
  String get description => 'Clinical prediction rule for pulmonary embolism.';

  @override
  String get category => 'Major Clinical Scores';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'age_65',
      label: 'Age >65 years (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'previous_dvt_pe',
      label: 'Previous DVT or PE (+3)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'surgery_fracture',
      label: 'Surgery or fracture within 1 month (+2)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'malignancy',
      label: 'Active malignancy (+2)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'unilateral_pain',
      label: 'Unilateral lower limb pain (+3)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'hemoptysis',
      label: 'Hemoptysis (+2)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'dvt_palpation',
      label: 'Pain on deep vein palpation (+4)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'heart_rate',
      label: 'Heart Rate',
      type: InputTypeOptions(['<75 bpm (0)', '75-94 bpm (+3)', '≥95 bpm (+5)']),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    if (getBool(inputs, 'age_65')) score += 1;
    if (getBool(inputs, 'previous_dvt_pe')) score += 3;
    if (getBool(inputs, 'surgery_fracture')) score += 2;
    if (getBool(inputs, 'malignancy')) score += 2;
    if (getBool(inputs, 'unilateral_pain')) score += 3;
    if (getBool(inputs, 'hemoptysis')) score += 2;
    if (getBool(inputs, 'dvt_palpation')) score += 4;

    // Heart rate scoring
    final hrIndex = getOptionIndex(inputs, 'heart_rate');
    if (hrIndex == 1) {
      score += 3;
    } else if (hrIndex == 2) {
      score += 5;
    }

    String interpretation;
    String probability;
    if (score <= 3) {
      probability = '8%';
      interpretation = 'Low Probability - Consider D-dimer';
    } else if (score <= 10) {
      probability = '29%';
      interpretation = 'Intermediate Probability - D-dimer or CT-PA';
    } else {
      probability = '74%';
      interpretation = 'High Probability - CT-PA recommended';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: '$interpretation (PE probability: $probability)',
      normalRange: '0-3 = Low probability',
    );
  }
}

/// qSOFA Score (Quick SOFA)
class QsofaCalculator extends MedicalCalculator {
  @override
  String get id => 'qsofa';

  @override
  String get shortName => 'qSOFA';

  @override
  String get fullName => 'Quick SOFA Score';

  @override
  String get description => 'Rapid bedside sepsis screening tool.';

  @override
  String get category => 'Major Clinical Scores';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'altered_mentation',
      label: 'Altered Mentation (GCS <15)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'sbp_low',
      label: 'Systolic BP ≤100 mmHg',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'rr_high',
      label: 'Respiratory Rate ≥22/min',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    if (getBool(inputs, 'altered_mentation')) score++;
    if (getBool(inputs, 'sbp_low')) score++;
    if (getBool(inputs, 'rr_high')) score++;

    String interpretation;
    if (score < 2) {
      interpretation = 'Low risk - Continue monitoring';
    } else {
      interpretation =
          'High risk of poor outcome - Assess for organ dysfunction, consider ICU';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: interpretation,
      normalRange: '<2 = Low risk',
    );
  }
}
