library;
//lib/features/calculators/domain/models/calculator_types.dart
/// Core domain models and abstract interface for medical calculators.
/// This file defines the data structures and contracts for all calculator implementations.

/// Result of a medical calculation.
class CalculationResult {
  final double? value;
  final String? unit;
  final String? interpretation;
  final String? normalRange;
  final String? error;
  final String? awaitingMessage;

  const CalculationResult({
    this.value,
    this.unit,
    this.interpretation,
    this.normalRange,
    this.error,
    this.awaitingMessage,
  });

  bool get isSuccess =>
      error == null && awaitingMessage == null && value != null;
  bool get isError => error != null;
  bool get isAwaiting => awaitingMessage != null;

  factory CalculationResult.success({
    required double value,
    String? unit,
    String? interpretation,
    String? normalRange,
  }) {
    return CalculationResult(
      value: value,
      unit: unit,
      interpretation: interpretation,
      normalRange: normalRange,
    );
  }

  factory CalculationResult.error(String message) {
    return CalculationResult(error: message);
  }

  /// Used when waiting for user input - displays as neutral, not an error
  factory CalculationResult.awaiting(String message) {
    return CalculationResult(awaitingMessage: message);
  }

  @override
  String toString() {
    if (isAwaiting) return 'Awaiting: $awaitingMessage';
    if (isError) return 'Error: $error';
    return '${value?.toStringAsFixed(2)} ${unit ?? ''} - $interpretation';
  }
}

/// Sealed class hierarchy for input types.
sealed class InputType {
  const InputType();
}

class InputTypeInteger extends InputType {
  const InputTypeInteger();
}

class InputTypeDecimal extends InputType {
  const InputTypeDecimal();
}

class InputTypeOptions extends InputType {
  final List<String> entries;
  final int defaultIndex;

  const InputTypeOptions(this.entries, {this.defaultIndex = 0});
}

class InputTypeCheckbox extends InputType {
  const InputTypeCheckbox();
}

class InputTypeDate extends InputType {
  const InputTypeDate();
}

/// Specification for a single input field.
class InputSpec {
  final String key;
  final String label;
  final InputType type;
  final String? unitHint;
  final String? placeholder;
  final double? defaultValue;
  final double? minValue;
  final double? maxValue;

  const InputSpec({
    required this.key,
    required this.label,
    required this.type,
    this.unitHint,
    this.placeholder,
    this.defaultValue,
    this.minValue,
    this.maxValue,
  });
}

/// Abstract interface for all medical calculators.
abstract class MedicalCalculator {
  /// Unique identifier for this calculator.
  String get id;

  /// Short display name (e.g., "MAP", "GCS").
  String get shortName;

  /// Full descriptive name.
  String get fullName;

  /// Brief description of what this calculator does.
  String get description;

  /// Category for grouping (e.g., "Hemodynamics", "Renal").
  String get category;

  /// List of input specifications.
  List<InputSpec> get inputSpecs;

  /// Perform the calculation with provided inputs.
  /// Keys in [inputs] correspond to InputSpec.key values.
  CalculationResult calculate(Map<String, dynamic> inputs);

  /// Helper to safely get a double value from inputs.
  double? getDouble(Map<String, dynamic> inputs, String key) {
    final value = inputs[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper to safely get an int value from inputs.
  int? getInt(Map<String, dynamic> inputs, String key) {
    final value = inputs[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper to safely get a boolean value from inputs.
  bool getBool(Map<String, dynamic> inputs, String key) {
    final value = inputs[key];
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0;
    return false;
  }

  /// Helper to get option index from inputs.
  int getOptionIndex(Map<String, dynamic> inputs, String key) {
    final value = inputs[key];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return 0;
  }
}
