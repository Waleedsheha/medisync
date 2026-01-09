//lib/core/services/drug_database_service.dart
// ignore_for_file: invalid_return_type_for_catch_error

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/drug.dart';
import '../models/drug_interaction.dart';
import 'rxnorm_service.dart';
import 'dailymed_service.dart';
import 'huggingface_service.dart';
import 'drug_supabase_service.dart';

/// Main service for drug database - combines Supabase storage with API fetching
class DrugDatabaseService {
  static const String _favoritesBoxName = 'drug_favorites';
  static const String _recentBoxName = 'drug_recent';
  // Interactions still cached locally or fetched? Let's keep interaction cache local for now to avoid complex relations
  static const String _interactionBoxName = 'interactions_cache';

  // Supabase table names
  static const String _tableDrugs = 'drugs';

  late Box<String> _favoritesBox;
  late Box<String> _recentBox;
  late Box<DrugInteraction> _interactionBox;

  final RxNormService _rxNormService = RxNormService();
  final DailyMedService _dailyMedService = DailyMedService();
  final HuggingFaceService _hfService = HuggingFaceService();
  final DrugSupabaseService _drugSupabaseService = DrugSupabaseService();

  bool _isInitialized = false;
  bool _interactionSyncStarted = false;

  /// Initialize Hive boxes (for user prefs) and Supabase (assumed in main)
  Future<void> initialize() async {
    if (_isInitialized) return;

    _favoritesBox = await Hive.openBox<String>(_favoritesBoxName);
    _recentBox = await Hive.openBox<String>(_recentBoxName);
    _interactionBox = await Hive.openBox<DrugInteraction>(_interactionBoxName);

    _isInitialized = true;

    // Best-effort: upload any locally cached interactions to Supabase.
    // Deduplication is enforced by deterministic id + DB uniqueness.
    if (!_interactionSyncStarted) {
      _interactionSyncStarted = true;
      unawaited(_syncCachedInteractionsToSupabase());
    }
  }

  Future<void> _syncCachedInteractionsToSupabase() async {
    try {
      final cached = _interactionBox.values.toList(growable: false);
      if (cached.isEmpty) return;

      // Keep this bounded to avoid long startup syncs.
      final batch = cached.length > 300 ? cached.take(300) : cached;
      for (final interaction in batch) {
        try {
          await _drugSupabaseService.upsertDrugInteraction(interaction);
        } catch (e) {
          debugPrint('Interaction sync failed (${interaction.id}): $e');
        }
      }
    } catch (e) {
      debugPrint('Interaction sync failed: $e');
    }
  }

  /// Search drugs - Supabase first, then API
  Future<DrugSearchResponse> searchDrugs(String query) async {
    await initialize();

    if (query.trim().isEmpty) {
      return DrugSearchResponse(drugs: [], fromCache: true);
    }

    // 1. First, search Supabase (our global cache/db) using the enhanced schema
    try {
      final supabaseResults = await _drugSupabaseService.searchDrugs(query);
      if (supabaseResults.isNotEmpty) {
        final base = supabaseResults.map(_fromSupabaseRow).toList();
        final drugs = await _hydrateDosageInfo(base);
        return DrugSearchResponse(drugs: drugs, fromCache: true);
      }
    } catch (e) {
      debugPrint('Supabase search failed: $e');
      // Continue to API if DB search fails or empty
    }

    // 2. If not in DB, search via RxNorm API
    final apiResults = await _rxNormService.searchDrugs(query);

    if (apiResults.isNotEmpty) {
      // 3. Fetch full details for each result and save to Supabase
      final drugs = <Drug>[];
      for (final result in apiResults.take(10)) {
        // Limit to first 10 results
        final drug = await _fetchAndSaveDrug(result);
        if (drug != null) {
          drugs.add(drug);
          // Redundant safety save to ensure database is populated
          _saveToSupabase(drug);
        }
      }
      return DrugSearchResponse(drugs: drugs, fromCache: false);
    }

    // 3. Fallback: Search online via AI (HuggingFace) if RxNorm fails
    try {
      final aiData = await _hfService.generateDrugData(query);
      if (aiData != null) {
        final drug = _createDrugFromAiData(query, aiData);

        // EXTRA DEDUPLICATION: Check if this generic name now exists in DB
        // (possibly under a different ID like RxCUI or another AI ID)
        final existing = await _drugSupabaseService.getDrugByGenericName(
          drug.genericName,
        );
        if (existing != null) {
          final existingDrug = _fromSupabaseRow(existing);
          // If existing one is missing dosage/warnings, enrich it instead of creating new
          if (existingDrug.dosageInfo == null ||
              existingDrug.warnings.isEmpty) {
            final enriched = _enrichDrugWithAi(existingDrug, aiData);
            await _saveToSupabase(enriched);
            return DrugSearchResponse(drugs: [enriched], fromCache: false);
          }
          return DrugSearchResponse(drugs: [existingDrug], fromCache: true);
        }

        await _saveToSupabase(drug);
        return DrugSearchResponse(drugs: [drug], fromCache: false);
      }
    } catch (e) {
      debugPrint('AI search fallback failed: $e');
    }

    return DrugSearchResponse(drugs: [], fromCache: false);
  }

  /// Fetch drug from API and save to Supabase
  Future<Drug?> _fetchAndSaveDrug(DrugSearchResult searchResult) async {
    // Check if already in Supabase by ID
    final existing = await getDrugById(searchResult.rxcui);
    if (existing != null && !existing.isStale) {
      return existing;
    }

    // Try to get detailed info from DailyMed
    final dailyMedResults = await _dailyMedService.searchByName(
      searchResult.name,
    );

    Drug drug;

    if (dailyMedResults.isNotEmpty) {
      final monograph = await _dailyMedService.getMonograph(
        dailyMedResults.first.setId,
      );
      if (monograph != null) {
        drug = monograph.toDrug(searchResult.rxcui);
      } else {
        drug = _createBasicDrug(searchResult);
      }
    } else {
      drug = _createBasicDrug(searchResult);
    }

    // AI ENRICHMENT
    if (drug.dosageInfo == null || drug.warnings.isEmpty) {
      try {
        final aiData = await _hfService.generateDrugData(searchResult.name);
        if (aiData != null) {
          drug = _enrichDrugWithAi(drug, aiData);
        }
      } catch (e) {
        debugPrint('AI Enrichment failed: $e');
      }
    }

    // Save to Supabase
    await _saveToSupabase(drug);

    return drug;
  }

  /// Save drug to Supabase
  Future<void> _saveToSupabase(Drug drug) async {
    try {
      // Auto-upload into the enhanced schema (generic_name/trade_names/trade_names_by_country/etc.)
      await _drugSupabaseService.upsertDrug(drug);
    } catch (e) {
      debugPrint('Error saving to Supabase: $e');
    }
  }

  /// Enrich existing drug object with AI-generated data
  Drug _enrichDrugWithAi(Drug original, Map<String, dynamic> aiData) {
    // Parse dosage info
    final dosageInfo = _parseDosageInfoFromAiMap(
      aiData['dosageInfo'] as Map<String, dynamic>?,
    );

    final aiSideEffects = (aiData['sideEffects'] as List?)?.cast<String>();
    final aiCommonSideEffects = (aiData['commonSideEffects'] as List?)
        ?.cast<String>();
    final aiRareSideEffects = (aiData['rareSideEffects'] as List?)
        ?.cast<String>();
    final aiSeriousSideEffects = (aiData['seriousSideEffects'] as List?)
        ?.cast<String>();

    return Drug(
      id: original.id,
      genericName: (aiData['genericName']?.toString().trim().isNotEmpty == true)
          ? aiData['genericName'].toString()
          : original.genericName,
      tradeNames:
          (aiData['tradeNames'] as List?)?.cast<String>() ??
          (aiData['brandNames'] as List?)?.cast<String>() ??
          original.tradeNames,
      sideEffects: aiSideEffects ?? original.sideEffects,
      commonSideEffects: aiCommonSideEffects ?? original.commonSideEffects,
      rareSideEffects: aiRareSideEffects ?? original.rareSideEffects,
      seriousSideEffects: aiSeriousSideEffects ?? original.seriousSideEffects,
      drugClass: aiData['drugClass'] ?? original.drugClass,
      mechanism: aiData['mechanism'] ?? original.mechanism,
      indications:
          (aiData['indications'] as List?)?.cast<String>() ??
          original.indications,
      contraindications:
          (aiData['contraindications'] as List?)?.cast<String>() ??
          original.contraindications,
      warnings:
          (aiData['warnings'] as List?)?.cast<String>() ?? original.warnings,
      blackBoxWarnings:
          (aiData['blackBoxWarnings'] as List?)?.cast<String>() ??
          original.blackBoxWarnings,
      dosageInfo: dosageInfo ?? original.dosageInfo,
      interactsWith:
          (aiData['interactsWith'] as List?)?.cast<String>() ??
          original.interactsWith,
      cachedAt: DateTime.now(),
    );
  }

  DosageInfo? _parseDosageInfoFromAiMap(Map<String, dynamic>? dosageMap) {
    if (dosageMap == null) return null;

    final standardRaw = dosageMap['standardDoses'];
    final standardDoses = <StandardDose>[];
    if (standardRaw is List) {
      for (final entry in standardRaw) {
        if (entry is Map) {
          standardDoses.add(
            StandardDose(
              indication: entry['indication']?.toString() ?? '',
              route: entry['route']?.toString() ?? '',
              dose: entry['dose']?.toString() ?? '',
              frequency: entry['frequency']?.toString() ?? '',
              duration: entry['duration']?.toString(),
              notes: entry['notes']?.toString(),
            ),
          );
        }
      }
    }

    RenalDosing? renal;
    final renalMap = dosageMap['renalDosing'];
    if (renalMap is Map) {
      renal = RenalDosing(
        crClGreater50: renalMap['crClGreater50']?.toString() ?? '-',
        crCl30to50: renalMap['crCl30to50']?.toString() ?? '-',
        crCl10to30: renalMap['crCl10to30']?.toString() ?? '-',
        crClLess10: renalMap['crClLess10']?.toString() ?? '-',
        dialysis: renalMap['dialysis']?.toString(),
        notes: renalMap['notes']?.toString(),
      );
    }

    HepaticDosing? hepatic;
    final hepaticMap = dosageMap['hepaticDosing'];
    if (hepaticMap is Map) {
      hepatic = HepaticDosing(
        childPughA: hepaticMap['childPughA']?.toString() ?? '-',
        childPughB: hepaticMap['childPughB']?.toString() ?? '-',
        childPughC: hepaticMap['childPughC']?.toString() ?? '-',
        notes: hepaticMap['notes']?.toString(),
      );
    }

    PediatricDosing? pediatric;
    final pedMap = dosageMap['pediatricDosing'];
    if (pedMap is Map) {
      pediatric = PediatricDosing(
        neonates: pedMap['neonates']?.toString(),
        infants: pedMap['infants']?.toString(),
        children: pedMap['children']?.toString(),
        adolescents: pedMap['adolescents']?.toString(),
        weightBased: pedMap['weightBased']?.toString(),
        notes: pedMap['notes']?.toString(),
      );
    }

    final geriatricNotes = dosageMap['geriatricNotes']?.toString();
    final maxDailyDose = dosageMap['maxDailyDose']?.toString();

    final hasAny =
        standardDoses.isNotEmpty ||
        renal != null ||
        hepatic != null ||
        pediatric != null ||
        (geriatricNotes != null && geriatricNotes.trim().isNotEmpty) ||
        (maxDailyDose != null && maxDailyDose.trim().isNotEmpty);
    if (!hasAny) return null;

    return DosageInfo(
      standardDoses: standardDoses,
      renalDosing: renal,
      hepaticDosing: hepatic,
      pediatricDosing: pediatric,
      geriatricNotes: geriatricNotes,
      maxDailyDose: maxDailyDose,
    );
  }

  /// Create a new Drug object from AI generated data
  Drug _createDrugFromAiData(String queryName, Map<String, dynamic> aiData) {
    final dosageInfo = _parseDosageInfoFromAiMap(
      aiData['dosageInfo'] as Map<String, dynamic>?,
    );

    final gName = (aiData['genericName']?.toString().trim().isNotEmpty == true)
        ? aiData['genericName'].toString().trim()
        : queryName.trim();

    // Use a deterministic AI ID based on the generic name to prevent duplicates
    final normalizedId = gName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '_',
    );
    final aiId = 'ai_$normalizedId';

    return Drug(
      id: aiId,
      genericName: gName,
      tradeNames:
          (aiData['tradeNames'] as List?)?.cast<String>() ??
          (aiData['brandNames'] as List?)?.cast<String>() ??
          const [],
      sideEffects: (aiData['sideEffects'] as List?)?.cast<String>() ?? const [],
      commonSideEffects:
          (aiData['commonSideEffects'] as List?)?.cast<String>() ?? const [],
      rareSideEffects:
          (aiData['rareSideEffects'] as List?)?.cast<String>() ?? const [],
      seriousSideEffects:
          (aiData['seriousSideEffects'] as List?)?.cast<String>() ?? const [],
      drugClass: aiData['drugClass'],
      mechanism: aiData['mechanism'],
      indications: (aiData['indications'] as List?)?.cast<String>() ?? [],
      contraindications:
          (aiData['contraindications'] as List?)?.cast<String>() ?? [],
      warnings: (aiData['warnings'] as List?)?.cast<String>() ?? [],
      blackBoxWarnings:
          (aiData['blackBoxWarnings'] as List?)?.cast<String>() ?? [],
      dosageInfo: dosageInfo,
      interactsWith:
          (aiData['interactsWith'] as List?)?.cast<String>() ?? const [],
      cachedAt: DateTime.now(),
    );
  }

  /// Create basic drug from RxNorm search result
  Drug _createBasicDrug(DrugSearchResult result) {
    return Drug(
      id: result.rxcui,
      genericName: result.name,
      tradeNames: result.synonym.isNotEmpty ? [result.synonym] : [],
    );
  }

  /// Get drug by ID (from Supabase or fetch)
  Future<Drug?> getDrugById(String rxcui) async {
    await initialize();

    // Check Supabase
    try {
      final response = await Supabase.instance.client
          .from(_tableDrugs)
          .select()
          .eq('id', rxcui)
          .maybeSingle();

      if (response != null) {
        final base = _fromSupabaseRow(response);
        final dosage = await _drugSupabaseService.getDosageInfo(base.id);
        return _copyDrugWithDosage(base, dosage);
      }
    } catch (e) {
      // ignore
    }

    // Not in DB - fetch and save
    // (This usually happens if we just have an ID but no data)
    final properties = await _rxNormService.getDrugProperties(rxcui);
    if (properties == null) return null;

    // In a real app we'd parse this property map to a Drug object
    // For now, return null as fallback implementation needs parsing logic
    return null;
  }

  Future<List<Drug>> _hydrateDosageInfo(List<Drug> drugs) async {
    if (drugs.isEmpty) return drugs;
    final limited = drugs.length > 15 ? drugs.take(15).toList() : drugs;

    final hydrated = await Future.wait(
      limited.map((d) async {
        try {
          final dosage = await _drugSupabaseService.getDosageInfo(d.id);
          return _copyDrugWithDosage(d, dosage);
        } catch (_) {
          return d;
        }
      }),
    );

    if (hydrated.length == drugs.length) return hydrated;
    return [...hydrated, ...drugs.skip(hydrated.length)];
  }

  Drug _copyDrugWithDosage(Drug original, DosageInfo? dosageInfo) {
    if (dosageInfo == null) return original;
    return Drug(
      id: original.id,
      genericName: original.genericName,
      tradeNames: original.tradeNames,
      sideEffects: original.sideEffects,
      commonSideEffects: original.commonSideEffects,
      rareSideEffects: original.rareSideEffects,
      seriousSideEffects: original.seriousSideEffects,
      drugClass: original.drugClass,
      mechanism: original.mechanism,
      indications: original.indications,
      contraindications: original.contraindications,
      warnings: original.warnings,
      blackBoxWarnings: original.blackBoxWarnings,
      dosageInfo: dosageInfo,
      interactsWith: original.interactsWith,
      cachedAt: original.cachedAt,
    );
  }

  /// Check interactions between drugs
  Future<List<DrugInteraction>> checkInteractions(List<String> drugIds) async {
    await initialize();
    if (drugIds.length < 2) return [];

    final interactions = <DrugInteraction>[];
    final uncachedPairs = <List<String>>[];

    // 1. Check local cache
    for (int i = 0; i < drugIds.length; i++) {
      for (int j = i + 1; j < drugIds.length; j++) {
        final pairId = DrugInteraction.generateId(drugIds[i], drugIds[j]);
        final cached = _interactionBox.get(pairId);

        if (cached != null) {
          interactions.add(cached);
        } else {
          uncachedPairs.add([drugIds[i], drugIds[j]]);
        }
      }
    }

    if (uncachedPairs.isNotEmpty) {
      final newlyCached = <DrugInteraction>[];

      // 2. Identify RxNorm-able rxcuis
      final rxcuis = drugIds.where((id) => !id.startsWith('ai_')).toList();
      if (rxcuis.length >= 2) {
        final rxInteractions = await _rxNormService.getInteractions(rxcuis);
        for (final interaction in rxInteractions) {
          if (!_interactionBox.containsKey(interaction.id)) {
            await _interactionBox.put(interaction.id, interaction);
            // Save to global DB
            _drugSupabaseService
                .upsertDrugInteraction(interaction)
                .catchError((e) => debugPrint('Sync error: $e'));
            newlyCached.add(interaction);
          }
          interactions.add(interaction);
        }
      }

      // 3. Identify pairs that need AI (at least one is ai_ or RxNorm missed it)
      for (final pair in uncachedPairs) {
        final pairId = DrugInteraction.generateId(pair[0], pair[1]);
        final resolvedByRxNorm = interactions.any((it) => it.id == pairId);

        if (!resolvedByRxNorm) {
          // Fetch names for AI check
          final drug1 = await getDrugById(pair[0]);
          final drug2 = await getDrugById(pair[1]);

          if (drug1 != null && drug2 != null) {
            final aiResult = await _hfService.checkDrugDrugInteraction(
              drug1.genericName,
              drug2.genericName,
            );

            if (aiResult != null &&
                aiResult['severity'] != 'none' &&
                aiResult['severity'] != null) {
              final interaction = DrugInteraction(
                id: pairId,
                drug1Id: pair[0],
                drug1Name: drug1.genericName,
                drug2Id: pair[1],
                drug2Name: drug2.genericName,
                severity: _parseAiSeverity(aiResult['severity']),
                description: aiResult['description'] ?? '',
                source: 'AI-Enhanced',
              );

              await _interactionBox.put(interaction.id, interaction);
              // Save AI result to global DB for next user
              _drugSupabaseService
                  .upsertDrugInteraction(interaction)
                  .catchError((e) => debugPrint('AI Sync error: $e'));
              newlyCached.add(interaction);
              interactions.add(interaction);
            }
          }
        }
      }

      if (newlyCached.isNotEmpty) {
        unawaited(_uploadInteractionsToSupabase(newlyCached));
      }
    }

    interactions.sort(
      (a, b) => a.severity.priority.compareTo(b.severity.priority),
    );
    return interactions;
  }

  InteractionSeverity _parseAiSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'major':
        return InteractionSeverity.major;
      case 'moderate':
        return InteractionSeverity.moderate;
      case 'minor':
        return InteractionSeverity.minor;
      default:
        return InteractionSeverity.minor;
    }
  }

  Future<void> _uploadInteractionsToSupabase(
    List<DrugInteraction> interactions,
  ) async {
    for (final interaction in interactions) {
      try {
        await _drugSupabaseService.upsertDrugInteraction(interaction);
      } catch (e) {
        debugPrint('Failed to upload interaction ${interaction.id}: $e');
      }
    }
  }

  // ==================== FAVORITES ====================

  Future<void> addFavorite(String drugId) async {
    await initialize();
    await _favoritesBox.put(drugId, drugId);
  }

  Future<void> removeFavorite(String drugId) async {
    await initialize();
    await _favoritesBox.delete(drugId);
  }

  bool isFavorite(String drugId) {
    return _favoritesBox.containsKey(drugId);
  }

  /// Get all favorite drugs (ASYNC NOW)
  Future<List<Drug>> getFavorites() async {
    await initialize();
    final favoriteIds = _favoritesBox.values.toList();
    if (favoriteIds.isEmpty) return [];

    try {
      final response = await Supabase.instance.client
          .from(_tableDrugs)
          .select()
          .filter('id', 'in', favoriteIds);

      return (response as List).map((e) => _fromSupabaseRow(e)).toList();
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      return [];
    }
  }

  // ==================== RECENT ====================

  Future<void> addToRecent(String drugId) async {
    await initialize();
    await _recentBox.delete(drugId);
    await _recentBox.put(drugId, drugId);
    if (_recentBox.length > 20) {
      final firstKey = _recentBox.keys.first;
      await _recentBox.delete(firstKey);
    }
  }

  // ==================== MAPPERS ====================

  Drug _fromSupabaseRow(Map<String, dynamic> row) {
    return Drug(
      id: row['id']?.toString() ?? '',
      genericName:
          row['generic_name']?.toString() ??
          row['genericName']?.toString() ??
          '',
      tradeNames: List<String>.from(row['trade_names'] ?? const []),
      sideEffects: List<String>.from(
        row['side_effects'] ?? row['sideEffects'] ?? const [],
      ),
      commonSideEffects: List<String>.from(
        row['common_side_effects'] ?? row['commonSideEffects'] ?? const [],
      ),
      rareSideEffects: List<String>.from(
        row['rare_side_effects'] ?? row['rareSideEffects'] ?? const [],
      ),
      seriousSideEffects: List<String>.from(
        row['serious_side_effects'] ?? row['seriousSideEffects'] ?? const [],
      ),
      drugClass: row['drug_class'] ?? row['drugClass'],
      mechanism: row['mechanism'],
      indications: List<String>.from(row['indications'] ?? const []),
      contraindications: List<String>.from(
        row['contraindications'] ?? const [],
      ),
      warnings: List<String>.from(row['warnings'] ?? const []),
      blackBoxWarnings: List<String>.from(
        row['black_box_warnings'] ?? row['blackBoxWarnings'] ?? const [],
      ),
      dosageInfo: null,
      interactsWith: List<String>.from(
        row['interacts_with'] ?? row['interactsWith'] ?? const [],
      ),
      cachedAt:
          DateTime.tryParse(
            row['cached_at']?.toString() ?? row['cachedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Future<List<Drug>> getRecentDrugs() async {
    await initialize();
    final recentIds = _recentBox.values.toList().reversed.toList();
    if (recentIds.isEmpty) return [];

    try {
      final response = await Supabase.instance.client
          .from(_tableDrugs)
          .select()
          .filter('id', 'in', recentIds);

      // Map results back to original order? Supabase might not preserve order
      final drugsMap = {
        for (var e in (response as List)) e['id']: _fromSupabaseRow(e),
      };

      return recentIds
          .map((id) => drugsMap[id])
          .where((d) => d != null)
          .cast<Drug>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching recent: $e');
      return [];
    }
  }

  // ==================== LIBRARY ====================

  Future<List<Drug>> getAllCachedDrugs() async {
    try {
      // Just returning latest 50 for now as "Library"
      final response = await Supabase.instance.client
          .from(_tableDrugs)
          .select()
          .limit(50);

      return (response as List).map((e) => _fromSupabaseRow(e)).toList()
        ..sort((a, b) => a.genericName.compareTo(b.genericName));
    } catch (e) {
      return [];
    }
  }

  Future<int> get cachedDrugsCount async {
    try {
      final response = await Supabase.instance.client.from(_tableDrugs).count();
      return response;
    } catch (e) {
      return 0;
    }
  }

  Future<void> clearCache() async {
    // Do nothing or clear local boxes only. Supabase is persistent.
    await initialize();
    await _interactionBox.clear();
  }
}

/// Response from drug search
class DrugSearchResponse {
  final List<Drug> drugs;
  final bool fromCache;

  DrugSearchResponse({required this.drugs, required this.fromCache});
}
