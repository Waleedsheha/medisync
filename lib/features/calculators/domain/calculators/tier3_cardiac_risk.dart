library;
//lib/features/calculators/domain/calculators/tier3_cardiac_risk.dart
/// Tier 3: Cardiac Risk & Thromboembolism Calculators
/// PE/DVT risk stratification and cardiac risk assessment tools.

import '../models/calculator_types.dart';

/// Wells Score for Pulmonary Embolism
class WellsPeCalculator extends MedicalCalculator {
  @override
  String get id => 'wells_pe';

  @override
  String get shortName => 'Wells PE';

  @override
  String get fullName => 'Wells Score for PE';

  @override
  String get description =>
      'Clinical prediction rule for pulmonary embolism probability.';

  @override
  String get category => 'Major Clinical Scores';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'dvt_signs',
      label: 'Clinical signs of DVT (+3.0)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'pe_likely',
      label: 'PE is most likely diagnosis (+3.0)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'hr_100',
      label: 'Heart rate >100 (+1.5)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'immobilization',
      label: 'Immobilization/Surgery in past 4 weeks (+1.5)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'previous_pe_dvt',
      label: 'Previous PE or DVT (+1.5)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'hemoptysis',
      label: 'Hemoptysis (+1.0)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'malignancy',
      label: 'Malignancy (active or treated within 6 months) (+1.0)',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    double score = 0;

    if (getBool(inputs, 'dvt_signs')) score += 3.0;
    if (getBool(inputs, 'pe_likely')) score += 3.0;
    if (getBool(inputs, 'hr_100')) score += 1.5;
    if (getBool(inputs, 'immobilization')) score += 1.5;
    if (getBool(inputs, 'previous_pe_dvt')) score += 1.5;
    if (getBool(inputs, 'hemoptysis')) score += 1.0;
    if (getBool(inputs, 'malignancy')) score += 1.0;

    String interpretation;
    String probability;
    if (score <= 4) {
      probability = 'Low';
      interpretation = 'PE Unlikely - Consider D-dimer';
    } else {
      probability = 'High';
      interpretation = 'PE Likely - Consider CT-PA';
    }

    return CalculationResult.success(
      value: score,
      unit: 'points',
      interpretation: '$interpretation ($probability probability)',
      normalRange: '≤4 = PE Unlikely',
    );
  }
}

/// PERC Rule (Pulmonary Embolism Rule-out Criteria)
class PercCalculator extends MedicalCalculator {
  @override
  String get id => 'perc';

  @override
  String get shortName => 'PERC';

  @override
  String get fullName => 'PERC Rule';

  @override
  String get description =>
      'Rules out PE in low-risk patients without further testing.';

  @override
  String get category => 'Respiratory';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'age_50',
      label: 'Age ≥50 years',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'hr_100',
      label: 'Heart rate ≥100 bpm',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'sao2_95',
      label: 'O2 saturation <95% on room air',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'leg_swelling',
      label: 'Unilateral leg swelling',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'hemoptysis',
      label: 'Hemoptysis',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'surgery_trauma',
      label: 'Surgery or trauma within 4 weeks',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'prior_pe_dvt',
      label: 'Prior PE or DVT',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'estrogen',
      label: 'Estrogen use',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    if (getBool(inputs, 'age_50')) score++;
    if (getBool(inputs, 'hr_100')) score++;
    if (getBool(inputs, 'sao2_95')) score++;
    if (getBool(inputs, 'leg_swelling')) score++;
    if (getBool(inputs, 'hemoptysis')) score++;
    if (getBool(inputs, 'surgery_trauma')) score++;
    if (getBool(inputs, 'prior_pe_dvt')) score++;
    if (getBool(inputs, 'estrogen')) score++;

    String interpretation;
    if (score == 0) {
      interpretation =
          'PERC Negative - PE can be ruled out (<2% risk). No further workup needed.';
    } else {
      interpretation =
          'PERC Positive - Cannot rule out PE. Further testing required.';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'criteria',
      interpretation: interpretation,
      normalRange: '0 = PE ruled out',
    );
  }
}

/// Wells Score for DVT
class WellsDvtCalculator extends MedicalCalculator {
  @override
  String get id => 'wells_dvt';

  @override
  String get shortName => 'Wells DVT';

  @override
  String get fullName => 'Wells Score for DVT';

  @override
  String get description => 'Clinical prediction rule for DVT probability.';

  @override
  String get category => 'Major Clinical Scores';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'active_cancer',
      label: 'Active cancer (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'paralysis',
      label: 'Paralysis/paresis or recent cast (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'bedridden',
      label: 'Bedridden >3 days or major surgery <12 weeks (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'localized_tenderness',
      label: 'Localized tenderness along deep veins (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'entire_leg_swollen',
      label: 'Entire leg swollen (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'calf_swelling',
      label: 'Calf swelling >3cm compared to other leg (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'pitting_edema',
      label: 'Pitting edema in symptomatic leg (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'collateral_veins',
      label: 'Collateral superficial veins (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'previous_dvt',
      label: 'Previously documented DVT (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'alt_diagnosis',
      label: 'Alternative diagnosis as likely or greater (-2)',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    if (getBool(inputs, 'active_cancer')) score += 1;
    if (getBool(inputs, 'paralysis')) score += 1;
    if (getBool(inputs, 'bedridden')) score += 1;
    if (getBool(inputs, 'localized_tenderness')) score += 1;
    if (getBool(inputs, 'entire_leg_swollen')) score += 1;
    if (getBool(inputs, 'calf_swelling')) score += 1;
    if (getBool(inputs, 'pitting_edema')) score += 1;
    if (getBool(inputs, 'collateral_veins')) score += 1;
    if (getBool(inputs, 'previous_dvt')) score += 1;
    if (getBool(inputs, 'alt_diagnosis')) score -= 2;

    String interpretation;
    String risk;
    if (score <= 0) {
      risk = 'Low';
      interpretation = 'DVT Unlikely (~3% risk) - D-dimer may suffice';
    } else if (score <= 1) {
      risk = 'Moderate';
      interpretation = 'Moderate probability (~17% risk)';
    } else {
      risk = 'High';
      interpretation = 'DVT Likely (~53% risk) - Ultrasound recommended';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: '$interpretation ($risk risk)',
      normalRange: '≤1 = DVT Unlikely',
    );
  }
}

/// CHA₂DS₂-VASc Score
class Cha2ds2VascCalculator extends MedicalCalculator {
  @override
  String get id => 'cha2ds2_vasc';

  @override
  String get shortName => 'CHA₂DS₂-VASc';

  @override
  String get fullName => 'CHA₂DS₂-VASc Score';

  @override
  String get description =>
      'Stroke risk stratification in atrial fibrillation.';

  @override
  String get category => 'Major Clinical Scores';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'age',
      label: 'Age',
      type: InputTypeInteger(),
      unitHint: 'years',
      placeholder: '70',
    ),
    const InputSpec(
      key: 'sex',
      label: 'Sex',
      type: InputTypeOptions(['Male', 'Female']),
    ),
    const InputSpec(
      key: 'chf',
      label: 'CHF / LV dysfunction (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'hypertension',
      label: 'Hypertension (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'stroke_tia',
      label: 'Stroke/TIA/Thromboembolism (+2)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'vascular',
      label: 'Vascular disease (prior MI, PAD, aortic plaque) (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'diabetes',
      label: 'Diabetes mellitus (+1)',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final age = getDouble(inputs, 'age') ?? 0;
    final sex = getOptionIndex(inputs, 'sex');

    int score = 0;

    // Age scoring
    if (age >= 75) {
      score += 2;
    } else if (age >= 65) {
      score += 1;
    }

    // Sex (Female = +1)
    if (sex == 1) score += 1;

    // Other criteria
    if (getBool(inputs, 'chf')) score += 1;
    if (getBool(inputs, 'hypertension')) score += 1;
    if (getBool(inputs, 'stroke_tia')) score += 2;
    if (getBool(inputs, 'vascular')) score += 1;
    if (getBool(inputs, 'diabetes')) score += 1;

    String interpretation;
    String annualStrokeRisk;
    if (score == 0) {
      annualStrokeRisk = '0%';
      interpretation = 'Low risk - Anticoagulation generally not recommended';
    } else if (score == 1) {
      annualStrokeRisk = '1.3%';
      interpretation = 'Low-moderate risk - Consider anticoagulation';
    } else if (score == 2) {
      annualStrokeRisk = '2.2%';
      interpretation = 'Moderate risk - Anticoagulation recommended';
    } else {
      annualStrokeRisk = '≥3.2%';
      interpretation = 'High risk - Anticoagulation strongly recommended';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: '$interpretation (Annual stroke risk: $annualStrokeRisk)',
      normalRange: '0 = Low risk',
    );
  }
}

/// HAS-BLED Score
class HasBledCalculator extends MedicalCalculator {
  @override
  String get id => 'has_bled';

  @override
  String get shortName => 'HAS-BLED';

  @override
  String get fullName => 'HAS-BLED Score';

  @override
  String get description =>
      'Bleeding risk assessment for anticoagulation in AF.';

  @override
  String get category => 'Major Clinical Scores';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'hypertension',
      label: 'Hypertension (SBP >160) (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'renal',
      label: 'Abnormal renal function (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'liver',
      label: 'Abnormal liver function (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'stroke',
      label: 'Stroke history (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'bleeding',
      label: 'Bleeding history or predisposition (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'labile_inr',
      label: 'Labile INR (if on warfarin) (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'elderly',
      label: 'Elderly (age >65) (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'drugs',
      label: 'Drugs (antiplatelet, NSAIDs) (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'alcohol',
      label: 'Alcohol excess (+1)',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    if (getBool(inputs, 'hypertension')) score++;
    if (getBool(inputs, 'renal')) score++;
    if (getBool(inputs, 'liver')) score++;
    if (getBool(inputs, 'stroke')) score++;
    if (getBool(inputs, 'bleeding')) score++;
    if (getBool(inputs, 'labile_inr')) score++;
    if (getBool(inputs, 'elderly')) score++;
    if (getBool(inputs, 'drugs')) score++;
    if (getBool(inputs, 'alcohol')) score++;

    String interpretation;
    if (score <= 2) {
      interpretation = 'Low bleeding risk - Anticoagulation generally safe';
    } else {
      interpretation =
          'High bleeding risk - Caution with anticoagulation, address modifiable factors';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: interpretation,
      normalRange: '≤2 = Low risk',
    );
  }
}

/// HEART Score for Chest Pain
class HeartScoreCalculator extends MedicalCalculator {
  @override
  String get id => 'heart_score';

  @override
  String get shortName => 'HEART';

  @override
  String get fullName => 'HEART Score';

  @override
  String get description => 'Risk stratification for chest pain in the ED.';

  @override
  String get category => 'Cardiac Risk';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'history',
      label: 'History',
      type: InputTypeOptions([
        'Slightly suspicious (0)',
        'Moderately suspicious (1)',
        'Highly suspicious (2)',
      ]),
    ),
    const InputSpec(
      key: 'ecg',
      label: 'ECG',
      type: InputTypeOptions([
        'Normal (0)',
        'Nonspecific changes (1)',
        'Significant ST deviation (2)',
      ]),
    ),
    const InputSpec(
      key: 'age',
      label: 'Age',
      type: InputTypeOptions([
        '<45 years (0)',
        '45-64 years (1)',
        '≥65 years (2)',
      ]),
    ),
    const InputSpec(
      key: 'risk_factors',
      label: 'Risk Factors (HTN, DM, smoking, obesity, FHx)',
      type: InputTypeOptions([
        'None (0)',
        '1-2 risk factors (1)',
        '≥3 risk factors or known CAD (2)',
      ]),
    ),
    const InputSpec(
      key: 'troponin',
      label: 'Initial Troponin',
      type: InputTypeOptions([
        '≤Normal limit (0)',
        '1-3× normal (1)',
        '>3× normal (2)',
      ]),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    score += getOptionIndex(inputs, 'history');
    score += getOptionIndex(inputs, 'ecg');
    score += getOptionIndex(inputs, 'age');
    score += getOptionIndex(inputs, 'risk_factors');
    score += getOptionIndex(inputs, 'troponin');

    String interpretation;
    String maceRisk;
    if (score <= 3) {
      maceRisk = '0.9-1.7%';
      interpretation = 'Low risk - Consider early discharge';
    } else if (score <= 6) {
      maceRisk = '12-16.6%';
      interpretation = 'Moderate risk - Observation and further workup';
    } else {
      maceRisk = '50-65%';
      interpretation = 'High risk - Aggressive treatment/intervention';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: '$interpretation (6-week MACE risk: $maceRisk)',
      normalRange: '≤3 = Low risk',
    );
  }
}

/// Framingham Risk Score - Placeholder
class FraminghamCalculator extends MedicalCalculator {
  @override
  String get id => 'framingham';

  @override
  String get shortName => 'Framingham';

  @override
  String get fullName => 'Framingham Risk Score';

  @override
  String get description => '10-year cardiovascular risk prediction.';

  @override
  String get category => 'Cardiac Risk';

  @override
  List<InputSpec> get inputSpecs => [];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    return CalculationResult.error(
      'Framingham Risk Score requires complex coefficient tables. '
      'External calculator recommended (e.g., MDCalc, ACC Risk Estimator).',
    );
  }
}

/// ASCVD Risk Calculator - Placeholder
class AscvdCalculator extends MedicalCalculator {
  @override
  String get id => 'ascvd';

  @override
  String get shortName => 'ASCVD';

  @override
  String get fullName => 'ASCVD Risk Estimator';

  @override
  String get description =>
      '10-year atherosclerotic cardiovascular disease risk.';

  @override
  String get category => 'Cardiac Risk';

  @override
  List<InputSpec> get inputSpecs => [];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    return CalculationResult.error(
      'ASCVD Risk Estimator requires Pooled Cohort Equations with complex coefficients. '
      'External calculator recommended (e.g., ACC ASCVD Risk Estimator Plus).',
    );
  }
}

/// Revised Cardiac Risk Index (RCRI)
class RcriCalculator extends MedicalCalculator {
  @override
  String get id => 'rcri';

  @override
  String get shortName => 'RCRI';

  @override
  String get fullName => 'Revised Cardiac Risk Index';

  @override
  String get description =>
      'Perioperative cardiac risk for non-cardiac surgery.';

  @override
  String get category => 'Cardiac Risk';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'high_risk_surgery',
      label:
          'High-risk surgery (intraperitoneal, intrathoracic, suprainguinal vascular) (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'ischemic_heart',
      label: 'History of ischemic heart disease (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'chf',
      label: 'History of congestive heart failure (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'cva_tia',
      label: 'History of cerebrovascular disease (CVA/TIA) (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'insulin_dm',
      label: 'Diabetes mellitus requiring insulin (+1)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'creatinine',
      label: 'Preoperative creatinine >2.0 mg/dL (+1)',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    if (getBool(inputs, 'high_risk_surgery')) score++;
    if (getBool(inputs, 'ischemic_heart')) score++;
    if (getBool(inputs, 'chf')) score++;
    if (getBool(inputs, 'cva_tia')) score++;
    if (getBool(inputs, 'insulin_dm')) score++;
    if (getBool(inputs, 'creatinine')) score++;

    String interpretation;
    String risk;
    if (score == 0) {
      risk = '0.4%';
      interpretation = 'Very low risk';
    } else if (score == 1) {
      risk = '0.9%';
      interpretation = 'Low risk';
    } else if (score == 2) {
      risk = '6.6%';
      interpretation = 'Moderate risk - Consider cardiology consult';
    } else {
      risk = '≥11%';
      interpretation = 'High risk - Cardiology evaluation recommended';
    }

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: '$interpretation (Major cardiac event risk: $risk)',
      normalRange: '0 = Very low risk',
    );
  }
}
