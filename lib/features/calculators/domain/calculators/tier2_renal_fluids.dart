library;
//lib/features/calculators/domain/calculators/tier2_renal_fluids.dart
/// Tier 2: Renal, Fluids & Electrolytes Calculators
/// Calculators for kidney function assessment and fluid management.

import 'dart:math';
import '../models/calculator_types.dart';

/// Free Water Deficit Calculator
/// Deficit = TBW × ((CurrentNa / TargetNa) - 1)
class FreeWaterDeficitCalculator extends MedicalCalculator {
  @override
  String get id => 'free_water_deficit';

  @override
  String get shortName => 'FWD';

  @override
  String get fullName => 'Free Water Deficit';

  @override
  String get description =>
      'Calculates free water deficit for hypernatremia correction.';

  @override
  String get category => 'Renal & Fluids';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'na',
      label: 'Current Sodium',
      type: InputTypeInteger(),
      unitHint: 'mEq/L',
      placeholder: '155',
    ),
    const InputSpec(
      key: 'weight',
      label: 'Weight',
      type: InputTypeDecimal(),
      unitHint: 'kg',
      placeholder: '70',
    ),
    const InputSpec(
      key: 'sex',
      label: 'Sex',
      type: InputTypeOptions(['Male', 'Female']),
    ),
    const InputSpec(
      key: 'target_na',
      label: 'Target Sodium',
      type: InputTypeInteger(),
      unitHint: 'mEq/L',
      placeholder: '140',
      defaultValue: 140,
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final na = getDouble(inputs, 'na');
    final weight = getDouble(inputs, 'weight');
    final sex = getOptionIndex(inputs, 'sex');
    final targetNa = getDouble(inputs, 'target_na') ?? 140;

    if (na == null || weight == null) {
      return CalculationResult.awaiting('Please enter sodium and weight');
    }

    if (targetNa <= 0) {
      return CalculationResult.error('Target sodium must be greater than 0');
    }

    // TBW = Weight × (0.6 for male, 0.5 for female)
    final tbwFactor = sex == 0 ? 0.6 : 0.5;
    final tbw = weight * tbwFactor;

    // Deficit = TBW × ((CurrentNa / TargetNa) - 1)
    final deficit = tbw * ((na / targetNa) - 1);

    String interpretation;
    if (deficit <= 0) {
      interpretation = 'No free water deficit (or hyponatremic)';
    } else if (deficit < 3) {
      interpretation = 'Mild deficit - Oral hydration may suffice';
    } else if (deficit < 6) {
      interpretation = 'Moderate deficit - Consider IV D5W';
    } else {
      interpretation = 'Severe deficit - IV replacement required';
    }

    return CalculationResult.success(
      value: deficit,
      unit: 'L',
      interpretation: '$interpretation. Correct slowly (≤10 mEq/L per 24h)',
      normalRange: '0 L',
    );
  }
}

/// Serum Osmolality Calculator
/// Osm = 2×Na + (Glucose/18) + (BUN/2.8)
class OsmolalityCalculator extends MedicalCalculator {
  @override
  String get id => 'osmolality';

  @override
  String get shortName => 'Osm';

  @override
  String get fullName => 'Serum Osmolality';

  @override
  String get description => 'Calculates serum osmolality and osmolar gap.';

  @override
  String get category => 'Renal & Fluids';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'na',
      label: 'Sodium',
      type: InputTypeInteger(),
      unitHint: 'mEq/L',
      placeholder: '140',
    ),
    const InputSpec(
      key: 'glucose',
      label: 'Glucose',
      type: InputTypeInteger(),
      unitHint: 'mg/dL',
      placeholder: '100',
    ),
    const InputSpec(
      key: 'bun',
      label: 'BUN',
      type: InputTypeInteger(),
      unitHint: 'mg/dL',
      placeholder: '15',
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final na = getDouble(inputs, 'na');
    final glucose = getDouble(inputs, 'glucose');
    final bun = getDouble(inputs, 'bun');

    if (na == null || glucose == null || bun == null) {
      return CalculationResult.awaiting('Please enter all values');
    }

    final osm = (2 * na) + (glucose / 18) + (bun / 2.8);

    String interpretation;
    if (osm < 275) {
      interpretation = 'Hypoosmolar - Consider SIADH, water intoxication';
    } else if (osm <= 295) {
      interpretation = 'Normal osmolality';
    } else {
      interpretation = 'Hyperosmolar - Consider dehydration, DKA, HHS';
    }

    return CalculationResult.success(
      value: osm,
      unit: 'mOsm/kg',
      interpretation: interpretation,
      normalRange: '275-295 mOsm/kg',
    );
  }
}

/// Fractional Excretion of Sodium (FENa)
/// FENa = ((UrineNa × SerumCr) / (SerumNa × UrineCr)) × 100
class FenaCalculator extends MedicalCalculator {
  @override
  String get id => 'fena';

  @override
  String get shortName => 'FENa';

  @override
  String get fullName => 'Fractional Excretion of Sodium';

  @override
  String get description =>
      'Helps differentiate prerenal from intrinsic renal failure.';

  @override
  String get category => 'Renal & Fluids';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'serum_na',
      label: 'Serum Sodium',
      type: InputTypeInteger(),
      unitHint: 'mEq/L',
      placeholder: '140',
    ),
    const InputSpec(
      key: 'serum_cr',
      label: 'Serum Creatinine',
      type: InputTypeDecimal(),
      unitHint: 'mg/dL',
      placeholder: '2.0',
    ),
    const InputSpec(
      key: 'urine_na',
      label: 'Urine Sodium',
      type: InputTypeInteger(),
      unitHint: 'mEq/L',
      placeholder: '40',
    ),
    const InputSpec(
      key: 'urine_cr',
      label: 'Urine Creatinine',
      type: InputTypeDecimal(),
      unitHint: 'mg/dL',
      placeholder: '100',
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final serumNa = getDouble(inputs, 'serum_na');
    final serumCr = getDouble(inputs, 'serum_cr');
    final urineNa = getDouble(inputs, 'urine_na');
    final urineCr = getDouble(inputs, 'urine_cr');

    if (serumNa == null ||
        serumCr == null ||
        urineNa == null ||
        urineCr == null) {
      return CalculationResult.awaiting('Please enter all values');
    }

    if (serumNa <= 0 || urineCr <= 0) {
      return CalculationResult.error('Serum Na and Urine Cr must be > 0');
    }

    final fena = ((urineNa * serumCr) / (serumNa * urineCr)) * 100;

    String interpretation;
    if (fena < 1) {
      interpretation = 'Prerenal azotemia (effective renal hypoperfusion)';
    } else if (fena <= 2) {
      interpretation = 'Indeterminate - Consider clinical context';
    } else {
      interpretation = 'Intrinsic renal failure (ATN likely)';
    }

    return CalculationResult.success(
      value: fena,
      unit: '%',
      interpretation: interpretation,
      normalRange: '<1% (prerenal) vs >2% (intrinsic)',
    );
  }
}

/// MDRD GFR Calculator
/// GFR = 175 × (Scr)^-1.154 × (Age)^-0.203 × (0.742 if female) × (1.212 if Black)
class MdrdCalculator extends MedicalCalculator {
  @override
  String get id => 'mdrd';

  @override
  String get shortName => 'MDRD';

  @override
  String get fullName => 'MDRD eGFR';

  @override
  String get description => 'Estimates GFR using the MDRD equation.';

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
      key: 'scr',
      label: 'Serum Creatinine',
      type: InputTypeDecimal(),
      unitHint: 'mg/dL',
      placeholder: '1.2',
    ),
    const InputSpec(
      key: 'sex',
      label: 'Sex',
      type: InputTypeOptions(['Male', 'Female']),
    ),
    const InputSpec(
      key: 'race',
      label: 'Race',
      type: InputTypeOptions(['Non-Black', 'Black']),
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final age = getDouble(inputs, 'age');
    final scr = getDouble(inputs, 'scr');
    final sex = getOptionIndex(inputs, 'sex');
    final race = getOptionIndex(inputs, 'race');

    if (age == null || scr == null) {
      return CalculationResult.awaiting('Please enter age and creatinine');
    }

    if (scr <= 0) {
      return CalculationResult.error('Creatinine must be > 0');
    }

    double gfr =
        175 * pow(scr, -1.154).toDouble() * pow(age, -0.203).toDouble();

    if (sex == 1) gfr *= 0.742; // Female
    if (race == 1) gfr *= 1.212; // Black

    return _interpretGfr(gfr);
  }

  CalculationResult _interpretGfr(double gfr) {
    String interpretation;
    String stage;
    if (gfr >= 90) {
      stage = 'G1';
      interpretation = 'Normal or high';
    } else if (gfr >= 60) {
      stage = 'G2';
      interpretation = 'Mildly decreased';
    } else if (gfr >= 45) {
      stage = 'G3a';
      interpretation = 'Mild-moderately decreased';
    } else if (gfr >= 30) {
      stage = 'G3b';
      interpretation = 'Moderate-severely decreased';
    } else if (gfr >= 15) {
      stage = 'G4';
      interpretation = 'Severely decreased';
    } else {
      stage = 'G5';
      interpretation = 'Kidney failure';
    }

    return CalculationResult.success(
      value: gfr,
      unit: 'mL/min/1.73m²',
      interpretation: 'CKD Stage $stage: $interpretation',
      normalRange: '≥90 mL/min/1.73m²',
    );
  }
}

/// CKD-EPI 2021 Calculator (Race-Free)
/// Uses the 2021 creatinine refit equation
class CkdEpiCalculator extends MedicalCalculator {
  @override
  String get id => 'ckd_epi';

  @override
  String get shortName => 'CKD-EPI';

  @override
  String get fullName => 'CKD-EPI 2021 eGFR';

  @override
  String get description => 'Race-free eGFR using 2021 CKD-EPI equation.';

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
    final scr = getDouble(inputs, 'scr');
    final sex = getOptionIndex(inputs, 'sex');

    if (age == null || scr == null) {
      return CalculationResult.awaiting('Please enter age and creatinine');
    }

    if (scr <= 0) {
      return CalculationResult.error('Creatinine must be > 0');
    }

    // CKD-EPI 2021 Race-Free Equation
    final isFemale = sex == 1;
    final kappa = isFemale ? 0.7 : 0.9;
    final alpha = isFemale ? -0.241 : -0.302;

    final scrOverKappa = scr / kappa;

    double gfr =
        142 *
        pow(min(scrOverKappa, 1.0), alpha).toDouble() *
        pow(max(scrOverKappa, 1.0), -1.2).toDouble() *
        pow(0.9938, age).toDouble();

    if (isFemale) gfr *= 1.012;

    String interpretation;
    String stage;
    if (gfr >= 90) {
      stage = 'G1';
      interpretation = 'Normal or high';
    } else if (gfr >= 60) {
      stage = 'G2';
      interpretation = 'Mildly decreased';
    } else if (gfr >= 45) {
      stage = 'G3a';
      interpretation = 'Mild-moderately decreased';
    } else if (gfr >= 30) {
      stage = 'G3b';
      interpretation = 'Moderate-severely decreased';
    } else if (gfr >= 15) {
      stage = 'G4';
      interpretation = 'Severely decreased';
    } else {
      stage = 'G5';
      interpretation = 'Kidney failure';
    }

    return CalculationResult.success(
      value: gfr,
      unit: 'mL/min/1.73m²',
      interpretation: 'CKD Stage $stage: $interpretation',
      normalRange: '≥90 mL/min/1.73m²',
    );
  }
}

/// Maintenance Fluids Calculator (4-2-1 Rule)
class MaintenanceFluidsCalculator extends MedicalCalculator {
  @override
  String get id => 'maintenance_fluids';

  @override
  String get shortName => 'IVF';

  @override
  String get fullName => 'Maintenance Fluids (4-2-1)';

  @override
  String get description => 'Calculates hourly maintenance IV fluid rate.';

  @override
  String get category => 'Renal & Fluids';

  @override
  List<InputSpec> get inputSpecs => [
    const InputSpec(
      key: 'weight',
      label: 'Weight',
      type: InputTypeDecimal(),
      unitHint: 'kg',
      placeholder: '70',
    ),
  ];

  @override
  CalculationResult calculate(Map<String, dynamic> inputs) {
    final weight = getDouble(inputs, 'weight');

    if (weight == null || weight <= 0) {
      return CalculationResult.awaiting('Please enter a valid weight');
    }

    // 4-2-1 Rule
    double rate = 0;
    double remaining = weight;

    // First 10 kg: 4 mL/kg/hr
    if (remaining > 0) {
      final first10 = min(remaining, 10.0);
      rate += first10 * 4;
      remaining -= first10;
    }

    // Next 10 kg: 2 mL/kg/hr
    if (remaining > 0) {
      final next10 = min(remaining, 10.0);
      rate += next10 * 2;
      remaining -= next10;
    }

    // Remaining: 1 mL/kg/hr
    if (remaining > 0) {
      rate += remaining * 1;
    }

    final daily = rate * 24;

    return CalculationResult.success(
      value: rate,
      unit: 'mL/hr',
      interpretation: 'Daily total: ${daily.toStringAsFixed(0)} mL/day',
      normalRange: 'Based on 4-2-1 rule',
    );
  }
}
