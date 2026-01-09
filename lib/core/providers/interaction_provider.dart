//lib/core/providers/interaction_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drug.dart';

/// Provider for managing selected drugs in the interaction checker.
/// Uses the modern Notifier pattern for Riverpod 2.0+.
final selectedDrugsForInteractionProvider =
    NotifierProvider<SelectedDrugsNotifier, List<Drug>>(() {
      return SelectedDrugsNotifier();
    });

class SelectedDrugsNotifier extends Notifier<List<Drug>> {
  @override
  List<Drug> build() => [];

  void addDrug(Drug drug) {
    if (!state.any((d) => d.id == drug.id)) {
      state = [...state, drug];
    }
  }

  void removeDrug(String id) {
    state = state.where((d) => d.id != id).toList();
  }

  void clear() {
    state = [];
  }
}
