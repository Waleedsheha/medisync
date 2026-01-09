library;
//lib/features/calculators/domain/calculators.dart
/// Main calculator registry and export file.
/// Provides the defaultCalculators() function and exports all calculator implementations.

// Export core types
export 'models/calculator_types.dart';

// Export all calculator implementations
export 'calculators/tier1_hemodynamics.dart';
export 'calculators/tier2_renal_fluids.dart';
export 'calculators/tier3_cardiac_risk.dart';
export 'calculators/tier4_respiratory.dart';
export 'calculators/tier5_liver_gi.dart';
export 'calculators/tier6_general.dart';
export 'calculators/tier7_clinical_scores.dart';

// Import for defaultCalculators function
import 'models/calculator_types.dart';
import 'calculators/tier1_hemodynamics.dart';
import 'calculators/tier2_renal_fluids.dart';
import 'calculators/tier3_cardiac_risk.dart';
import 'calculators/tier4_respiratory.dart';
import 'calculators/tier5_liver_gi.dart';
import 'calculators/tier6_general.dart';
import 'calculators/tier7_clinical_scores.dart';

/// Returns the complete list of all medical calculators.
/// Ordered by tier and clinical relevance.
List<MedicalCalculator> defaultCalculators() {
  return [
    // 1. Hemodynamics
    MapCalculator(),
    GcsCalculator(),
    SirsCalculator(),
    QtcCalculator(),

    // 2. Renal & Fluids
    CrClCalculator(),
    AnionGapCalculator(),
    CorrectedCalciumCalculator(),
    CorrectedSodiumCalculator(),
    FreeWaterDeficitCalculator(),
    OsmolalityCalculator(),
    FenaCalculator(),
    MdrdCalculator(),
    CkdEpiCalculator(),
    MaintenanceFluidsCalculator(),

    // 3. Cardiac Risk
    HeartScoreCalculator(),
    FraminghamCalculator(),
    AscvdCalculator(),
    RcriCalculator(),

    // 4. Respiratory
    Curb65Calculator(),
    StopBangCalculator(),
    PercCalculator(),

    // 5. Liver
    ChildPughCalculator(),
    MeldNaCalculator(),
    Fib4Calculator(),

    // 6. Major Clinical Scores (Scores)
    SofaCalculator(),
    QsofaCalculator(),
    WellsPeCalculator(),
    WellsDvtCalculator(),
    GenevaCalculator(),
    TimiNstemiCalculator(),
    Cha2ds2VascCalculator(),
    HasBledCalculator(),

    // 7. General
    BmiBsaCalculator(),
    IbwCalculator(),
    SteroidConversionCalculator(),
    MmeCalculator(),
    DueDateCalculator(),
    CentorCalculator(),
  ];
}

/// Returns calculators grouped by category.
Map<String, List<MedicalCalculator>> calculatorsByCategory() {
  final calculators = defaultCalculators();
  final Map<String, List<MedicalCalculator>> grouped = {};

  for (final calc in calculators) {
    grouped.putIfAbsent(calc.category, () => []).add(calc);
  }

  return grouped;
}

/// Finds a calculator by its ID.
MedicalCalculator? findCalculatorById(String id) {
  try {
    return defaultCalculators().firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
