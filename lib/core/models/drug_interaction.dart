//lib/core/models/drug_interaction.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'drug_interaction.g.dart';

/// Drug-Drug Interaction model
@HiveType(typeId: 26)
class DrugInteraction extends HiveObject {
  @HiveField(0)
  final String id; // Unique ID for this interaction

  @HiveField(1)
  final String drug1Id;

  @HiveField(2)
  final String drug1Name;

  @HiveField(3)
  final String drug2Id;

  @HiveField(4)
  final String drug2Name;

  @HiveField(5)
  final InteractionSeverity severity;

  @HiveField(6)
  final String description;

  @HiveField(7)
  final String? mechanism;

  @HiveField(8)
  final String? management;

  @HiveField(9)
  final String source; // e.g., "DrugBank", "ONCHigh", "RxNorm"

  @HiveField(10)
  final DateTime cachedAt;

  DrugInteraction({
    required this.id,
    required this.drug1Id,
    required this.drug1Name,
    required this.drug2Id,
    required this.drug2Name,
    required this.severity,
    required this.description,
    this.mechanism,
    this.management,
    required this.source,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  /// Generate unique ID from drug pair
  static String generateId(String drug1Id, String drug2Id) {
    final sorted = [drug1Id, drug2Id]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}

/// Interaction severity levels
@HiveType(typeId: 27)
enum InteractionSeverity {
  @HiveField(0)
  major, // 🔴 Avoid combination

  @HiveField(1)
  moderate, // 🟠 Use with caution

  @HiveField(2)
  minor, // 🟢 Monitor
}

/// Static helpers for InteractionSeverity
class InteractionSeverityHelper {
  /// Get color based on severity
  static Color getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.major:
        return const Color(0xFFFF4444); // Red
      case InteractionSeverity.moderate:
        return const Color(0xFFFFAA00); // Orange
      case InteractionSeverity.minor:
        return const Color(0xFF4CAF50); // Green
    }
  }

  /// Get icon based on severity
  static String getSeverityIcon(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.major:
        return '⚠️';
      case InteractionSeverity.moderate:
        return '⚡';
      case InteractionSeverity.minor:
        return 'ℹ️';
    }
  }
}

extension InteractionSeverityExtension on InteractionSeverity {
  String get displayName {
    switch (this) {
      case InteractionSeverity.major:
        return 'Major';
      case InteractionSeverity.moderate:
        return 'Moderate';
      case InteractionSeverity.minor:
        return 'Minor';
    }
  }

  String get emoji {
    switch (this) {
      case InteractionSeverity.major:
        return '🔴';
      case InteractionSeverity.moderate:
        return '🟠';
      case InteractionSeverity.minor:
        return '🟢';
    }
  }

  int get priority {
    switch (this) {
      case InteractionSeverity.major:
        return 0;
      case InteractionSeverity.moderate:
        return 1;
      case InteractionSeverity.minor:
        return 2;
    }
  }
}
