//lib/core/services/drug_supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/drug.dart';
import '../models/drug_interaction.dart';

/// Service for managing drug data in Supabase
class DrugSupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _tableDrugs = 'drugs';
  static const String _tableInteractions = 'drug_interactions';
  static const String _tableSideEffects = 'side_effect_details';

  // Dosage tables (created in 20260106103048_drug_tables.sql)
  static const String _tableDosageInfo = 'dosage_info';
  static const String _tableStandardDoses = 'standard_doses';
  static const String _tableRenalDosing = 'renal_dosing';
  static const String _tableHepaticDosing = 'hepatic_dosing';
  static const String _tablePediatricDosing = 'pediatric_dosing';

  /// Resolve a drug ID from an input that may be an ID or generic name.
  Future<String?> resolveDrugId(String input) async {
    final q = input.trim();
    if (q.isEmpty) return null;

    // 1) Assume it's an ID.
    final byId = await _client
        .from(_tableDrugs)
        .select('id')
        .eq('id', q)
        .maybeSingle();
    if (byId != null) return byId['id']?.toString();

    // 2) Exact generic name.
    final byGeneric = await _client
        .from(_tableDrugs)
        .select('id')
        .eq('generic_name', q)
        .maybeSingle();
    if (byGeneric != null) return byGeneric['id']?.toString();

    // 3) Fuzzy match.
    final fuzzyRows = await _client
        .from(_tableDrugs)
        .select('id')
        .or('generic_name.ilike.%$q%')
        .limit(1);

    final fuzzyList = List<Map<String, dynamic>>.from(fuzzyRows as List);
    if (fuzzyList.isNotEmpty) return fuzzyList.first['id']?.toString();

    return null;
  }

  /// Upsert a complete drug record with all related data
  Future<Map<String, dynamic>> upsertDrug(Drug drug) async {
    try {
      // Prepare drug data - single table schema
      final drugData = {
        'id': drug.id,
        'generic_name': drug.genericName,
        'trade_names': drug.tradeNames,
        'drug_class': drug.drugClass,
        'mechanism': drug.mechanism,
        'indications': drug.indications,
        'contraindications': drug.contraindications,
        'warnings': drug.warnings,
        'black_box_warnings': drug.blackBoxWarnings,
        'side_effects': drug.sideEffects,
        'common_side_effects': drug.commonSideEffects,
        'rare_side_effects': drug.rareSideEffects,
        'serious_side_effects': drug.seriousSideEffects,
        'interacts_with': drug.interactsWith,
        // Standard dosing
        'standard_dose_indication': drug.standardDoseIndication,
        'standard_dose_route': drug.standardDoseRoute,
        'standard_dose': drug.standardDose,
        'standard_dose_frequency': drug.standardDoseFrequency,
        'standard_dose_duration': drug.standardDoseDuration,
        'standard_dose_notes': drug.standardDoseNotes,
        // Special populations
        'geriatric_notes': drug.geriatricNotes,
        'max_daily_dose': drug.maxDailyDose,
        // Renal dosing
        'renal_crcl_gt_50': drug.renalCrclGt50,
        'renal_crcl_30_50': drug.renalCrcl30_50,
        'renal_crcl_10_30': drug.renalCrcl10_30,
        'renal_crcl_lt_10': drug.renalCrclLt10,
        'renal_dialysis': drug.renalDialysis,
        'renal_notes': drug.renalNotes,
        // Hepatic dosing
        'hepatic_child_pugh_a': drug.hepaticChildPughA,
        'hepatic_child_pugh_b': drug.hepaticChildPughB,
        'hepatic_child_pugh_c': drug.hepaticChildPughC,
        'hepatic_notes': drug.hepaticNotes,
        // Pediatric dosing
        'pediatric_neonates': drug.pediatricNeonates,
        'pediatric_infants': drug.pediatricInfants,
        'pediatric_children': drug.pediatricChildren,
        'pediatric_adolescents': drug.pediatricAdolescents,
        'pediatric_weight_based': drug.pediatricWeightBased,
        'pediatric_notes': drug.pediatricNotes,
        'cached_at': drug.cachedAt.toIso8601String(),
      };

      // Upsert drug
      final response = await _client
          .from(_tableDrugs)
          .upsert(drugData, onConflict: 'id')
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to upsert drug: $e');
    }
  }

  /// Get drug by generic name
  Future<Map<String, dynamic>?> getDrugByGenericName(String genericName) async {
    try {
      final response = await _client
          .from(_tableDrugs)
          .select()
          .ilike('generic_name', genericName)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get drug by generic name: $e');
    }
  }

  /// Load dosage information for a drug from normalized Supabase tables.
  ///
  /// Returns null if no dosage information exists.
  Future<DosageInfo?> getDosageInfo(String drugId) async {
    try {
      final dosageRow = await _client
          .from(_tableDosageInfo)
          .select('geriatric_notes,max_daily_dose')
          .eq('drug_id', drugId)
          .maybeSingle();

      final standardRows = await _client
          .from(_tableStandardDoses)
          .select('indication,route,dose,frequency,duration,notes')
          .eq('dosage_info_id', drugId);

      final renalRow = await _client
          .from(_tableRenalDosing)
          .select(
            'crc_l_greater_50,crc_l_30_to_50,crc_l_10_to_30,crc_l_less_10,dialysis,notes',
          )
          .eq('dosage_info_id', drugId)
          .maybeSingle();

      final hepaticRow = await _client
          .from(_tableHepaticDosing)
          .select('child_pugh_a,child_pugh_b,child_pugh_c,notes')
          .eq('dosage_info_id', drugId)
          .maybeSingle();

      final pediatricRow = await _client
          .from(_tablePediatricDosing)
          .select('neonates,infants,children,adolescents,weight_based,notes')
          .eq('dosage_info_id', drugId)
          .maybeSingle();

      final standardDoses = (standardRows as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (r) => StandardDose(
              indication: r['indication']?.toString() ?? '',
              route: r['route']?.toString() ?? '',
              dose: r['dose']?.toString() ?? '',
              frequency: r['frequency']?.toString() ?? '',
              duration: r['duration']?.toString(),
              notes: r['notes']?.toString(),
            ),
          )
          .toList(growable: false);

      final renal = renalRow == null
          ? null
          : RenalDosing(
              crClGreater50: renalRow['crc_l_greater_50']?.toString() ?? '-',
              crCl30to50: renalRow['crc_l_30_to_50']?.toString() ?? '-',
              crCl10to30: renalRow['crc_l_10_to_30']?.toString() ?? '-',
              crClLess10: renalRow['crc_l_less_10']?.toString() ?? '-',
              dialysis: renalRow['dialysis']?.toString(),
              notes: renalRow['notes']?.toString(),
            );

      final hepatic = hepaticRow == null
          ? null
          : HepaticDosing(
              childPughA: hepaticRow['child_pugh_a']?.toString() ?? '-',
              childPughB: hepaticRow['child_pugh_b']?.toString() ?? '-',
              childPughC: hepaticRow['child_pugh_c']?.toString() ?? '-',
              notes: hepaticRow['notes']?.toString(),
            );

      final pediatric = pediatricRow == null
          ? null
          : PediatricDosing(
              neonates: pediatricRow['neonates']?.toString(),
              infants: pediatricRow['infants']?.toString(),
              children: pediatricRow['children']?.toString(),
              adolescents: pediatricRow['adolescents']?.toString(),
              weightBased: pediatricRow['weight_based']?.toString(),
              notes: pediatricRow['notes']?.toString(),
            );

      final geriatricNotes = dosageRow?['geriatric_notes']?.toString();
      final maxDailyDose = dosageRow?['max_daily_dose']?.toString();

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
    } catch (e) {
      throw Exception('Failed to load dosage info: $e');
    }
  }

  /// Search drugs by name or brand
  Future<List<Map<String, dynamic>>> searchDrugs(String query) async {
    try {
      final response = await _client
          .from(_tableDrugs)
          .select()
          .or('generic_name.ilike.%$query%,trade_names.cs.{$query}')
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search drugs: $e');
    }
  }

  /// Get drugs by trade name in a specific country
  Future<List<Map<String, dynamic>>> getDrugsByTradeName(
    String tradeName,
    String countryCode,
  ) async {
    try {
      final response = await _client
          .from(_tableDrugs)
          .select()
          .contains('trade_names_by_country', {
            countryCode: [tradeName],
          })
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get drugs by trade name: $e');
    }
  }

  /// Upsert a drug interaction with deterministic id to prevent duplicates.
  ///
  /// Supabase schema (see migration):
  /// - id TEXT PK
  /// - drug_id TEXT
  /// - interacting_drug_id TEXT
  Future<Map<String, dynamic>> upsertDrugInteraction(
    DrugInteraction interaction,
  ) async {
    try {
      final sorted = [interaction.drug1Id, interaction.drug2Id]..sort();
      final id = DrugInteraction.generateId(sorted[0], sorted[1]);

      final interactionData = {
        'id': id,
        'drug_id': sorted[0],
        'interacting_drug_id': sorted[1],
        'severity': interaction.severity.name,
        'description': interaction.description,
        'mechanism': interaction.mechanism,
        'management': interaction.management,
        'source': interaction.source,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from(_tableInteractions)
          .upsert(interactionData, onConflict: 'id')
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to upsert drug interaction: $e');
    }
  }

  /// Get all interactions for a drug
  Future<List<Map<String, dynamic>>> getDrugInteractions(String drugId) async {
    try {
      final response = await _client
          .from(_tableInteractions)
          .select()
          .or('drug_id.eq.$drugId,interacting_drug_id.eq.$drugId');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get drug interactions: $e');
    }
  }

  /// Check if two drugs interact
  Future<Map<String, dynamic>?> checkInteraction(
    String drug1Id,
    String drug2Id,
  ) async {
    try {
      final sorted = [drug1Id, drug2Id]..sort();

      // Prefer deterministic id lookup first.
      final deterministicId = DrugInteraction.generateId(sorted[0], sorted[1]);
      final byId = await _client
          .from(_tableInteractions)
          .select()
          .eq('id', deterministicId)
          .maybeSingle();
      if (byId != null) return byId;

      // Fallback: match either ordering (in case legacy rows exist).
      final response = await _client
          .from(_tableInteractions)
          .select()
          .or(
            'and(drug_id.eq.${sorted[0]},interacting_drug_id.eq.${sorted[1]}),and(drug_id.eq.${sorted[1]},interacting_drug_id.eq.${sorted[0]})',
          )
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to check interaction: $e');
    }
  }

  /// Add side effect details
  Future<Map<String, dynamic>> addSideEffect({
    required String name,
    required String category, // 'common', 'rare', 'serious'
    required int frequencyPercentage,
    String? onset,
    String? riskFactors,
    String? management,
  }) async {
    try {
      final sideEffectData = {
        'name': name,
        'category': category,
        'frequency_percentage': frequencyPercentage,
        'onset': onset,
        'risk_factors': riskFactors,
        'management': management,
      };

      final response = await _client
          .from(_tableSideEffects)
          .insert(sideEffectData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to add side effect: $e');
    }
  }

  /// Get side effects for a drug
  Future<List<Map<String, dynamic>>> getDrugSideEffects(String drugId) async {
    try {
      final drug = await _client
          .from(_tableDrugs)
          .select(
            'side_effects, common_side_effects, rare_side_effects, serious_side_effects',
          )
          .eq('id', drugId)
          .single();

      return [
        {
          'all': drug['side_effects'] ?? [],
          'common': drug['common_side_effects'] ?? [],
          'rare': drug['rare_side_effects'] ?? [],
          'serious': drug['serious_side_effects'] ?? [],
        },
      ];
    } catch (e) {
      throw Exception('Failed to get drug side effects: $e');
    }
  }

  /// Bulk upload drugs from local cache
  Future<Map<String, dynamic>> uploadDrugs(List<Drug> drugs) async {
    int successCount = 0;
    int failureCount = 0;
    List<String> errors = [];

    for (final drug in drugs) {
      try {
        await upsertDrug(drug);
        successCount++;
      } catch (e) {
        failureCount++;
        errors.add('${drug.genericName}: $e');
      }
    }

    return {
      'total': drugs.length,
      'success': successCount,
      'failed': failureCount,
      'errors': errors,
    };
  }

  /// Get all drugs (paginated)
  Future<List<Map<String, dynamic>>> getAllDrugs({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _client
          .from(_tableDrugs)
          .select()
          .range((page - 1) * pageSize, page * pageSize - 1)
          .order('generic_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get all drugs: $e');
    }
  }

  /// Delete a drug
  Future<void> deleteDrug(String drugId) async {
    try {
      await _client.from(_tableDrugs).delete().eq('id', drugId);
    } catch (e) {
      throw Exception('Failed to delete drug: $e');
    }
  }
}
