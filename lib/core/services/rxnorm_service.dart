//lib/core/services/rxnorm_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/drug_interaction.dart';

/// Service for RxNorm API - Drug search and interactions
/// API Docs: https://rxnav.nlm.nih.gov/RxNormAPIs.html
class RxNormService {
  static const String _baseUrl = 'https://rxnav.nlm.nih.gov/REST';

  /// Search for drugs by name
  /// Returns list of drugs with RxCUI and name
  Future<List<DrugSearchResult>> searchDrugs(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = '$_baseUrl/drugs.json?name=$query';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final drugGroup = data['drugGroup'];

        if (drugGroup == null || drugGroup['conceptGroup'] == null) {
          return [];
        }

        final results = <DrugSearchResult>[];

        for (final group in drugGroup['conceptGroup']) {
          if (group['conceptProperties'] != null) {
            for (final concept in group['conceptProperties']) {
              results.add(
                DrugSearchResult(
                  rxcui: concept['rxcui'] ?? '',
                  name: concept['name'] ?? '',
                  synonym: concept['synonym'] ?? '',
                  tty: concept['tty'] ?? '', // Term type
                ),
              );
            }
          }
        }

        // Filter and sort results
        final queryLower = query.toLowerCase();

        // Remove duplicates based on name
        final uniqueResults = <String, DrugSearchResult>{};
        for (final r in results) {
          uniqueResults.putIfAbsent(r.name, () => r);
        }
        var filteredResults = uniqueResults.values.toList();

        filteredResults.sort((a, b) {
          final aName = a.name.toLowerCase();
          final bName = b.name.toLowerCase();

          // 1. Exact match priority
          if (aName == queryLower && bName != queryLower) return -1;
          if (bName == queryLower && aName != queryLower) return 1;

          // 2. "Contains /" penalty (Combinations)
          // If query doesn't have slash, prefer non-slash results
          if (!queryLower.contains('/')) {
            final aHasSlash = aName.contains('/');
            final bHasSlash = bName.contains('/');
            if (aHasSlash && !bHasSlash) return 1;
            if (!aHasSlash && bHasSlash) return -1;
          }

          // 3. Starts with priority
          final aStarts = aName.startsWith(queryLower);
          final bStarts = bName.startsWith(queryLower);
          if (aStarts && !bStarts) return -1;
          if (!aStarts && bStarts) return 1;

          // 4. Shortest length priority (favors "Metformin" over "Metformin Hydrochloride")
          return aName.length.compareTo(bName.length);
        });

        return filteredResults;
      }
      return [];
    } catch (e) {
      debugPrint('RxNorm search error: $e');
      return [];
    }
  }

  /// Get drug details by RxCUI
  Future<Map<String, dynamic>?> getDrugProperties(String rxcui) async {
    try {
      final url = '$_baseUrl/rxcui/$rxcui/allProperties.json?prop=all';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('RxNorm properties error: $e');
      return null;
    }
  }

  /// Get drug-drug interactions for a list of RxCUIs
  Future<List<DrugInteraction>> getInteractions(List<String> rxcuis) async {
    if (rxcuis.length < 2) return [];

    try {
      final rxcuiList = rxcuis.join('+');
      final url = '$_baseUrl/interaction/list.json?rxcuis=$rxcuiList';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseInteractions(data);
      }
      return [];
    } catch (e) {
      debugPrint('RxNorm interactions error: $e');
      return [];
    }
  }

  /// Parse interaction response from RxNorm
  List<DrugInteraction> _parseInteractions(Map<String, dynamic> data) {
    final interactions = <DrugInteraction>[];

    final fullInteractionTypeGroup = data['fullInteractionTypeGroup'];
    if (fullInteractionTypeGroup == null) return interactions;

    for (final group in fullInteractionTypeGroup) {
      final fullInteractionType = group['fullInteractionType'];
      if (fullInteractionType == null) continue;

      for (final interaction in fullInteractionType) {
        final interactionPair = interaction['interactionPair'];
        if (interactionPair == null) continue;

        for (final pair in interactionPair) {
          final concepts = pair['interactionConcept'];
          if (concepts == null || concepts.length < 2) continue;

          final drug1 = concepts[0]['minConceptItem'];
          final drug2 = concepts[1]['minConceptItem'];
          final severity = _parseSeverity(pair['severity'] ?? '');

          interactions.add(
            DrugInteraction(
              id: DrugInteraction.generateId(
                drug1['rxcui'] ?? '',
                drug2['rxcui'] ?? '',
              ),
              drug1Id: drug1['rxcui'] ?? '',
              drug1Name: drug1['name'] ?? '',
              drug2Id: drug2['rxcui'] ?? '',
              drug2Name: drug2['name'] ?? '',
              severity: severity,
              description: pair['description'] ?? '',
              source: group['sourceName'] ?? 'RxNorm',
            ),
          );
        }
      }
    }

    // Sort by severity (major first)
    interactions.sort(
      (a, b) => a.severity.priority.compareTo(b.severity.priority),
    );
    return interactions;
  }

  InteractionSeverity _parseSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'major':
        return InteractionSeverity.major;
      case 'moderate':
        return InteractionSeverity.moderate;
      default:
        return InteractionSeverity.minor;
    }
  }
}

/// Search result from RxNorm
class DrugSearchResult {
  final String rxcui;
  final String name;
  final String synonym;
  final String tty; // Term type: SBD, SCD, BN, etc.

  DrugSearchResult({
    required this.rxcui,
    required this.name,
    this.synonym = '',
    this.tty = '',
  });

  @override
  String toString() => '$name ($rxcui)';
}
