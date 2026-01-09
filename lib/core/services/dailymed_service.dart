//lib/core/services/dailymed_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/drug.dart';

/// Service for DailyMed API - Full drug monographs
/// API Docs: https://dailymed.nlm.nih.gov/dailymed/app-support-web-services.cfm
class DailyMedService {
  static const String _baseUrl =
      'https://dailymed.nlm.nih.gov/dailymed/services/v2';

  /// Search for SPL (Structured Product Labels) by drug name
  Future<List<DailyMedResult>> searchByName(String drugName) async {
    if (drugName.trim().isEmpty) return [];

    try {
      final encodedName = Uri.encodeComponent(drugName);
      final url = '$_baseUrl/spls.json?drug_name=$encodedName&pagesize=10';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = <DailyMedResult>[];

        if (data['data'] != null) {
          for (final item in data['data']) {
            results.add(
              DailyMedResult(
                setId: item['setid'] ?? '',
                title: item['title'] ?? '',
                publishedDate: item['published_date'] ?? '',
              ),
            );
          }
        }
        return results;
      }
      return [];
    } catch (e) {
      debugPrint('DailyMed search error: $e');
      return [];
    }
  }

  /// Get full SPL content by SetID
  Future<DrugMonograph?> getMonograph(String setId) async {
    try {
      final url = '$_baseUrl/spls/$setId.json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseMonograph(data);
      }
      return null;
    } catch (e) {
      debugPrint('DailyMed monograph error: $e');
      return null;
    }
  }

  /// Parse SPL into structured DrugMonograph
  DrugMonograph? _parseMonograph(Map<String, dynamic> data) {
    try {
      final splData = data['data'];
      if (splData == null) return null;

      // Sections and codes would be used here for more specific parsing
      // final sections = <String, String>{};
      // const sectionCodes = {...};

      // Parse sections based on LOINC codes
      // Note: Actual parsing depends on SPL XML structure
      // This is simplified for JSON response

      return DrugMonograph(
        setId: splData['setid'] ?? '',
        title: splData['title'] ?? '',
        genericName: _extractGenericName(splData),
        brandNames: _extractBrandNames(splData),
        labeler: splData['labeler'] ?? '',
        dosageInfo: _extractDosageInfo(splData),
        indications: _extractSection(splData, 'indications_and_usage'),
        contraindications: _extractSection(splData, 'contraindications'),
        warnings: _extractSection(splData, 'warnings_and_cautions'),
        adverseReactions: _extractSection(splData, 'adverse_reactions'),
        drugInteractions: _extractSection(splData, 'drug_interactions'),
        mechanism: _extractSection(splData, 'mechanism_of_action'),
      );
    } catch (e) {
      debugPrint('Parse monograph error: $e');
      return null;
    }
  }

  String _extractGenericName(Map<String, dynamic> data) {
    final products = data['products'];
    if (products != null && products.isNotEmpty) {
      return products[0]['generic_name'] ?? '';
    }
    return '';
  }

  List<String> _extractBrandNames(Map<String, dynamic> data) {
    final products = data['products'];
    if (products != null) {
      return products
          .map<String>((p) => p['brand_name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
    }
    return [];
  }

  String _extractSection(Map<String, dynamic> data, String sectionName) {
    // Simplified - actual implementation needs XML parsing
    return data[sectionName]?.toString() ?? '';
  }

  DosageInfo? _extractDosageInfo(Map<String, dynamic> data) {
    var dosageText = data['dosage_and_administration']?.toString();

    // Fallback keys if main key is empty
    if (dosageText == null || dosageText.isEmpty) {
      dosageText = data['dosage_and_administration_table']?.toString();
    }

    final renalText = data['renal_impairment']?.toString();
    final hepaticText = data['hepatic_impairment']?.toString();
    final pediatricText = data['pediatric_use']?.toString();
    final geriatricText = data['geriatric_use']?.toString();

    if ((dosageText == null || dosageText.isEmpty) &&
        renalText == null &&
        hepaticText == null) {
      return null;
    }

    final standardDoses = <StandardDose>[];
    if (dosageText != null && dosageText.isNotEmpty) {
      standardDoses.add(
        StandardDose(
          indication: 'General Instructions',
          route: 'See details',
          dose: 'See details',
          frequency: 'As directed',
          notes: _truncate(dosageText, 800),
        ),
      );
    }

    RenalDosing? renalDosing;
    if (renalText != null ||
        (dosageText != null &&
            (dosageText.toLowerCase().contains('renal') ||
                dosageText.toLowerCase().contains('kidney')))) {
      renalDosing = RenalDosing(
        crClGreater50: 'See notes',
        crCl30to50: 'See notes',
        crCl10to30: 'See notes',
        crClLess10: 'See notes',
        notes: _truncate(
          renalText ??
              'See general dosage instructions for potential renal adjustments.',
          500,
        ),
      );
    }

    HepaticDosing? hepaticDosing;
    if (hepaticText != null ||
        (dosageText != null &&
            (dosageText.toLowerCase().contains('hepatic') ||
                dosageText.toLowerCase().contains('liver')))) {
      hepaticDosing = HepaticDosing(
        childPughA: 'See notes',
        childPughB: 'See notes',
        childPughC: 'See notes',
        notes: _truncate(
          hepaticText ??
              'See general dosage instructions for potential hepatic adjustments.',
          500,
        ),
      );
    }

    PediatricDosing? pediatricDosing;
    if (pediatricText != null) {
      pediatricDosing = PediatricDosing(notes: _truncate(pediatricText, 500));
    }

    return DosageInfo(
      standardDoses: standardDoses,
      renalDosing: renalDosing,
      hepaticDosing: hepaticDosing,
      pediatricDosing: pediatricDosing,
      geriatricNotes: geriatricText != null
          ? _truncate(geriatricText, 500)
          : null,
    );
  }

  String _truncate(String text, int length) {
    if (text.length <= length) return text;
    // Clean up basic HTML tags if possible (very simple regex)
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '');
    if (cleanText.length <= length) return cleanText;
    return '${cleanText.substring(0, length)}...';
  }
}

/// Search result from DailyMed
class DailyMedResult {
  final String setId;
  final String title;
  final String publishedDate;

  DailyMedResult({
    required this.setId,
    required this.title,
    required this.publishedDate,
  });
}

/// Parsed drug monograph from DailyMed SPL
class DrugMonograph {
  final String setId;
  final String title;
  final String genericName;
  final List<String> brandNames;
  final String labeler;
  final DosageInfo? dosageInfo;
  final String indications;
  final String contraindications;
  final String warnings;
  final String adverseReactions;
  final String drugInteractions;
  final String mechanism;

  DrugMonograph({
    required this.setId,
    required this.title,
    this.genericName = '',
    this.brandNames = const [],
    this.labeler = '',
    this.dosageInfo,
    this.indications = '',
    this.contraindications = '',
    this.warnings = '',
    this.adverseReactions = '',
    this.drugInteractions = '',
    this.mechanism = '',
  });

  /// Convert to Drug model for caching
  Drug toDrug(String rxcui) {
    return Drug(
      id: rxcui,
      genericName: genericName.isNotEmpty ? genericName : title,
      tradeNames: brandNames,
      mechanism: mechanism.isNotEmpty ? mechanism : null,
      indications: indications.isNotEmpty ? [indications] : [],
      contraindications: contraindications.isNotEmpty
          ? [contraindications]
          : [],
      warnings: warnings.isNotEmpty ? [warnings] : [],
      dosageInfo: dosageInfo,
    );
  }
}
