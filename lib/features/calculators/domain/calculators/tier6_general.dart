library;
//lib/features/calculators/domain/calculators/tier6_general.dart
/// Tier 6: General / Other Calculators
/// BMI/BSA, Ideal Body Weight, Steroid Conversion, MME, Due Date, Centor Score.

import 'dart:math';
import '../models/calculator_types.dart';

/// BMI and BSA Calculator
class BmiBsaCalculator extends MedicalCalculator {
  @override
  String get id => 'bmi_bsa';

  @override
  String get shortName => 'BMI/BSA';

  @override
  String get fullName => 'BMI & Body Surface Area';

  @override
  String get description => 'Calculates BMI and BSA for drug dosing.';

  @override
  String get category => 'General';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'weight',
      label: 'Weight',
      type: InputTypeDecimal(),
      unitHint: 'kg',
      placeholder: '70',
    ),
    const InputSpec(
      key: 'height',
      label: 'Height',
      type: InputTypeDecimal(),
      unitHint: 'cm',
      placeholder: '170',
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final weight = getDouble(inputs, 'weight');
    final height = getDouble(inputs, 'height');

    if (weight == null || height == null) {
      return CalculationResult.awaiting('Please enter weight and height');
    }

    if (weight <= 0 || height <= 0) {
      return CalculationResult.error('Weight and height must be > 0');
    }

    // BMI = weight (kg) / height (m)²
    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);

    // BSA (Mosteller formula) = √((height × weight) / 3600)
    final bsa = sqrt((height * weight) / 3600);

    String bmiCategory;
    if (bmi < 18.5) {
      bmiCategory = 'Underweight';
    } else if (bmi < 25) {
      bmiCategory = 'Normal weight';
    } else if (bmi < 30) {
      bmiCategory = 'Overweight';
    } else if (bmi < 35) {
      bmiCategory = 'Obesity Class I';
    } else if (bmi < 40) {
      bmiCategory = 'Obesity Class II';
    } else {
      bmiCategory = 'Obesity Class III';
    }

    return CalculationResult.success(
      value: bmi,
      unit: 'kg/m²',
      interpretation: '$bmiCategory | BSA: ${bsa.toStringAsFixed(2)} m²',
      normalRange: 'BMI 18.5-24.9 kg/m²',
    );
  }
}

/// Ideal Body Weight Calculator (Devine Formula)
class IbwCalculator extends MedicalCalculator {
  @override
  String get id => 'ibw';

  @override
  String get shortName => 'IBW';

  @override
  String get fullName => 'Ideal Body Weight';

  @override
  String get description =>
      'Calculates ideal body weight for drug dosing (Devine formula).';

  @override
  String get category => 'General';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'height',
      label: 'Height',
      type: InputTypeDecimal(),
      unitHint: 'cm',
      placeholder: '170',
    ),
    const InputSpec(
      key: 'sex',
      label: 'Sex',
      type: InputTypeOptions(['Male', 'Female']),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final height = getDouble(inputs, 'height');
    final sex = getOptionIndex(inputs, 'sex');

    if (height == null) {
      return CalculationResult.awaiting('Please enter height');
    }

    // Convert cm to inches
    final heightInches = height / 2.54;

    // Devine formula
    // Male: 50 + 2.3 × (height in inches - 60)
    // Female: 45.5 + 2.3 × (height in inches - 60)
    double ibw;
    if (sex == 0) {
      ibw = 50 + 2.3 * (heightInches - 60);
    } else {
      ibw = 45.5 + 2.3 * (heightInches - 60);
    }

    // IBW can be negative for very short individuals
    if (ibw < 0) ibw = 0;

    return CalculationResult.success(
      value: ibw,
      unit: 'kg',
      interpretation: 'Use for aminoglycoside, vancomycin dosing',
      normalRange: 'Varies by height',
    );
  }
}

/// Steroid Conversion Calculator
class SteroidConversionCalculator extends MedicalCalculator {
  @override
  String get id => 'steroid_conversion';

  @override
  String get shortName => 'Steroid';

  @override
  String get fullName => 'Steroid Conversion';

  @override
  String get description => 'Converts between equivalent steroid doses.';

  @override
  String get category => 'General';

  // Equivalence table (relative to hydrocortisone 20mg)
  // Hydrocortisone 20 = Prednisone 5 = Methylprednisolone 4 = Dexamethasone 0.75
  static const Map<String, double> _equivalentDoses = {
    'Hydrocortisone': 20.0,
    'Prednisone': 5.0,
    'Prednisolone': 5.0,
    'Methylprednisolone': 4.0,
    'Dexamethasone': 0.75,
    'Betamethasone': 0.6,
    'Triamcinolone': 4.0,
  };

  @override
  List<InputSpec> get inputSpecs => [
    InputSpec(
      key: 'from_drug',
      label: 'From Drug',
      type: InputTypeOptions(_equivalentDoses.keys.toList()),
    ),
    const InputSpec(
      key: 'dose',
      label: 'Dose',
      type: InputTypeDecimal(),
      unitHint: 'mg',
      placeholder: '10',
    ),
    InputSpec(
      key: 'to_drug',
      label: 'To Drug',
      type: InputTypeOptions(_equivalentDoses.keys.toList()),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final fromIndex = getOptionIndex(inputs, 'from_drug');
    final dose = getDouble(inputs, 'dose');
    final toIndex = getOptionIndex(inputs, 'to_drug');

    if (dose == null || dose <= 0) {
      return CalculationResult.awaiting('Please enter a valid dose');
    }

    final drugs = _equivalentDoses.keys.toList();
    final fromDrug = drugs[fromIndex];
    final toDrug = drugs[toIndex];

    final fromEquiv = _equivalentDoses[fromDrug]!;
    final toEquiv = _equivalentDoses[toDrug]!;

    // Convert: dose × (toEquiv / fromEquiv)
    final convertedDose = dose * (toEquiv / fromEquiv);

    return CalculationResult.success(
      value: convertedDose,
      unit: 'mg',
      interpretation:
          '$dose mg $fromDrug = ${convertedDose.toStringAsFixed(2)} mg $toDrug',
      normalRange: 'Equivalent potency conversion',
    );
  }
}

/// Morphine Milligram Equivalent (MME) Calculator
class MmeCalculator extends MedicalCalculator {
  @override
  String get id => 'mme';

  @override
  String get shortName => 'MME';

  @override
  String get fullName => 'Morphine Milligram Equivalent';

  @override
  String get description => 'Calculates daily morphine equivalent dose.';

  @override
  String get category => 'General';

  static const Map<String, double> _conversionFactors = {
    'Morphine (oral)': 1.0,
    'Morphine (IV/IM)': 3.0,
    'Oxycodone': 1.5,
    'Hydrocodone': 1.0,
    'Hydromorphone (oral)': 4.0,
    'Hydromorphone (IV)': 20.0,
    'Fentanyl patch (mcg/hr)': 2.4, // Per mcg/hr
    'Tramadol': 0.1,
    'Codeine': 0.15,
    'Methadone (1-20mg/d)': 4.0,
    'Methadone (21-40mg/d)': 8.0,
    'Methadone (41-60mg/d)': 10.0,
    'Methadone (>60mg/d)': 12.0,
  };

  @override
  List<InputSpec> get inputSpecs => [
    InputSpec(
      key: 'drug',
      label: 'Opioid',
      type: InputTypeOptions(_conversionFactors.keys.toList()),
    ),
    const InputSpec(
      key: 'dose',
      label: 'Daily Dose',
      type: InputTypeDecimal(),
      unitHint: 'mg (or mcg/hr for fentanyl patch)',
      placeholder: '30',
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final drugIndex = getOptionIndex(inputs, 'drug');
    final dose = getDouble(inputs, 'dose');

    if (dose == null || dose <= 0) {
      return CalculationResult.awaiting('Please enter a valid dose');
    }

    final drugs = _conversionFactors.keys.toList();
    final drug = drugs[drugIndex];
    final factor = _conversionFactors[drug]!;

    final mme = dose * factor;

    String interpretation;
    String riskLevel;
    if (mme < 50) {
      riskLevel = 'Standard';
      interpretation = 'Standard opioid dose';
    } else if (mme < 90) {
      riskLevel = 'Moderate';
      interpretation = 'Moderate dose - Monitor closely';
    } else {
      riskLevel = 'High';
      interpretation = 'HIGH DOSE - CDC recommends avoiding or justifying';
    }

    return CalculationResult.success(
      value: mme,
      unit: 'MME/day',
      interpretation: '$interpretation ($riskLevel risk)',
      normalRange: '<50 MME/day',
    );
  }
}

/// Due Date Calculator (Naegele's Rule)
class DueDateCalculator extends MedicalCalculator {
  @override
  String get id => 'due_date';

  @override
  String get shortName => 'EDD';

  @override
  String get fullName => 'Estimated Due Date';

  @override
  String get description =>
      'Calculates estimated due date from LMP (Naegele\'s rule).';

  @override
  String get category => 'General';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'lmp_year',
      label: 'LMP Year',
      type: InputTypeInteger(),
      placeholder: '2026',
    ),
    const InputSpec(
      key: 'lmp_month',
      label: 'LMP Month (1-12)',
      type: InputTypeInteger(),
      placeholder: '1',
      minValue: 1,
      maxValue: 12,
    ),
    const InputSpec(
      key: 'lmp_day',
      label: 'LMP Day (1-31)',
      type: InputTypeInteger(),
      placeholder: '1',
      minValue: 1,
      maxValue: 31,
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final year = getInt(inputs, 'lmp_year');
    final month = getInt(inputs, 'lmp_month');
    final day = getInt(inputs, 'lmp_day');

    if (year == null || month == null || day == null) {
      return CalculationResult.awaiting('Please enter complete LMP date');
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return CalculationResult.error('Invalid date values');
    }

    try {
      final lmp = DateTime(year, month, day);

      // Naegele's Rule: LMP + 1 year - 3 months + 7 days
      // Or simply: LMP + 280 days
      final edd = lmp.add(const Duration(days: 280));

      final now = DateTime.now();
      final gestationalAge = now.difference(lmp).inDays;
      final weeks = gestationalAge ~/ 7;
      final days = gestationalAge % 7;

      return CalculationResult.success(
        value: gestationalAge.toDouble(),
        unit: 'days GA',
        interpretation:
            'EDD: ${edd.month}/${edd.day}/${edd.year} | '
            'Current GA: $weeks weeks $days days',
        normalRange: 'Term: 37-42 weeks',
      );
    } catch (e) {
      return CalculationResult.error('Invalid date');
    }
  }
}

/// Centor Score (Modified/McIsaac) for Strep Pharyngitis
class CentorCalculator extends MedicalCalculator {
  @override
  String get id => 'centor';

  @override
  String get shortName => 'Centor';

  @override
  String get fullName => 'Centor Score (McIsaac)';

  @override
  String get description =>
      'Estimates probability of streptococcal pharyngitis.';

  @override
  String get category => 'General';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'age',
      label: 'Age Group',
      type: InputTypeOptions([
        '3-14 years (+1)',
        '15-44 years (0)',
        '≥45 years (-1)',
      ]),
    ),
    const InputSpec(
      key: 'exudate',
      label: 'Tonsillar exudate or swelling',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'lymph',
      label: 'Tender anterior cervical lymph nodes',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'fever',
      label: 'Fever (history or >38°C)',
      type: InputTypeCheckbox(),
    ),
    const InputSpec(
      key: 'no_cough',
      label: 'Absence of cough',
      type: InputTypeCheckbox(),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    int score = 0;

    // Age scoring
    final ageGroup = getOptionIndex(inputs, 'age');
    if (ageGroup == 0) {
      score += 1; // 3-14 years
    } else if (ageGroup == 2) {
      score -= 1; // ≥45 years
    }

    if (getBool(inputs, 'exudate')) score++;
    if (getBool(inputs, 'lymph')) score++;
    if (getBool(inputs, 'fever')) score++;
    if (getBool(inputs, 'no_cough')) score++;

    String interpretation;
    String strepRisk;
    String recommendation;

    if (score <= 0) {
      strepRisk = '1-2.5%';
      recommendation = 'No testing or antibiotics';
    } else if (score == 1) {
      strepRisk = '5-10%';
      recommendation = 'No testing or antibiotics';
    } else if (score == 2) {
      strepRisk = '11-17%';
      recommendation = 'Consider rapid strep test';
    } else if (score == 3) {
      strepRisk = '28-35%';
      recommendation = 'Rapid strep test; treat if positive';
    } else {
      strepRisk = '51-53%';
      recommendation = 'Consider empiric antibiotics or test';
    }

    interpretation = 'Strep probability: $strepRisk. $recommendation';

    return CalculationResult.success(
      value: score.toDouble(),
      unit: 'points',
      interpretation: interpretation,
      normalRange: '≤1 = Low probability',
    );
  }
}
