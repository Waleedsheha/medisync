library;
//lib/features/calculators/presentation/calculator_provider.dart
/// Calculator State Management Provider
/// Manages the calculator selection, inputs, and result state.

import 'package:flutter/foundation.dart';
import '../domain/calculators.dart';

/// ChangeNotifier for managing calculator state.
class CalculatorProvider extends ChangeNotifier {
  /// All available calculators.
  final List<MedicalCalculator> _calculators = defaultCalculators();

  /// Currently selected calculator index.
  int _selectedIndex = 0;

  /// Current input values.
  Map<String, dynamic> _inputs = {};

  /// Last calculation result.
  CalculationResult? _lastResult;

  /// Search/filter query.
  String _searchQuery = '';

  // ============= Getters =============

  /// All calculators.
  List<MedicalCalculator> get calculators => _calculators;

  /// Filtered calculators based on search query.
  List<MedicalCalculator> get filteredCalculators {
    if (_searchQuery.isEmpty) return _calculators;

    final query = _searchQuery.toLowerCase();
    return _calculators.where((c) {
      return c.shortName.toLowerCase().contains(query) ||
          c.fullName.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query) ||
          c.category.toLowerCase().contains(query);
    }).toList();
  }

  /// Calculators grouped by category.
  Map<String, List<MedicalCalculator>> get calculatorsByCategory {
    final Map<String, List<MedicalCalculator>> grouped = {};
    for (final calc in filteredCalculators) {
      grouped.putIfAbsent(calc.category, () => []).add(calc);
    }
    return grouped;
  }

  /// Currently selected calculator.
  MedicalCalculator get currentCalculator => _calculators[_selectedIndex];

  /// Selected index.
  int get selectedIndex => _selectedIndex;

  /// Current inputs.
  Map<String, dynamic> get inputs => _inputs;

  /// Last result.
  CalculationResult? get lastResult => _lastResult;

  /// Search query.
  String get searchQuery => _searchQuery;

  // ============= Actions =============

  /// Select a calculator by index.
  void selectCalculator(int index) {
    if (index >= 0 && index < _calculators.length) {
      _selectedIndex = index;
      _inputs = {};
      _lastResult = null;
      notifyListeners();
    }
  }

  /// Select a calculator by ID.
  void selectCalculatorById(String id) {
    final index = _calculators.indexWhere((c) => c.id == id);
    if (index != -1) {
      selectCalculator(index);
    }
  }

  /// Update an input value.
  void updateInput(String key, dynamic value) {
    _inputs[key] = value;
    // Auto-calculate on input change
    calculate();
  }

  /// Update multiple inputs at once.
  void updateInputs(Map<String, dynamic> newInputs) {
    _inputs.addAll(newInputs);
    calculate();
  }

  /// Clear all inputs.
  void clearInputs() {
    _inputs = {};
    _lastResult = null;
    notifyListeners();
  }

  /// Perform calculation.
  void calculate() {
    try {
      _lastResult = currentCalculator.calculate(_inputs);
    } catch (e) {
      _lastResult = CalculationResult.error(
        'Calculation error: ${e.toString()}',
      );
    }
    notifyListeners();
  }

  /// Update search query.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search.
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Get input value for a specific key.
  dynamic getInputValue(String key) {
    return _inputs[key];
  }

  /// Check if all required inputs are filled.
  bool get hasAllRequiredInputs {
    for (final spec in currentCalculator.inputSpecs) {
      if (_inputs[spec.key] == null) {
        return false;
      }
    }
    return true;
  }
}
