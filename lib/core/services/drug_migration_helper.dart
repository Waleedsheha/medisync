//lib/core/services/drug_migration_helper.dart
import 'package:flutter/foundation.dart';
import '../models/drug.dart';
import 'drug_database_service.dart';
import 'drug_supabase_service.dart';

/// Helper service to migrate local Hive drug data to Supabase
class DrugMigrationHelper {
  final DrugDatabaseService _localService;
  final DrugSupabaseService _supabaseService;

  DrugMigrationHelper({
    required DrugDatabaseService localService,
    required DrugSupabaseService supabaseService,
  }) : _localService = localService,
       _supabaseService = supabaseService;

  /// Upload all local cached drugs to Supabase
  Future<Map<String, dynamic>> uploadLocalCacheToSupabase({
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('Starting migration: Fetching local drugs...');
      final localDrugs = await _localService.getAllCachedDrugs();
      debugPrint('Found ${localDrugs.length} local drugs');

      if (localDrugs.isEmpty) {
        return {
          'success': true,
          'message': 'No local drugs to migrate',
          'total': 0,
          'uploaded': 0,
          'failed': 0,
        };
      }

      int successCount = 0;
      int failureCount = 0;
      List<String> errors = [];

      for (int i = 0; i < localDrugs.length; i++) {
        final drug = localDrugs[i];

        try {
          // Upload to Supabase
          await _supabaseService.upsertDrug(drug);

          successCount++;
          debugPrint(
            '✅ Uploaded: ${drug.genericName} (${i + 1}/${localDrugs.length})',
          );

          // Notify progress
          onProgress?.call(i + 1, localDrugs.length);
        } catch (e) {
          failureCount++;
          final error = '${drug.genericName}: $e';
          errors.add(error);
          debugPrint('❌ Failed: $error');
        }
      }

      final result = {
        'success': true,
        'message': 'Migration completed',
        'total': localDrugs.length,
        'uploaded': successCount,
        'failed': failureCount,
        'errors': errors,
      };

      debugPrint(
        'Migration complete: $successCount uploaded, $failureCount failed',
      );
      return result;
    } catch (e) {
      debugPrint('Migration failed: $e');
      return {
        'success': false,
        'message': 'Migration failed: $e',
        'total': 0,
        'uploaded': 0,
        'failed': 0,
      };
    }
  }

  /// Ensure drug has scientific name set
  // Removed: scientificName is no longer part of the Drug model.

  /// Upload a single drug
  Future<bool> uploadSingleDrug(Drug drug) async {
    try {
      await _supabaseService.upsertDrug(drug);
      return true;
    } catch (e) {
      debugPrint('Failed to upload drug: $e');
      return false;
    }
  }

  /// Sync a drug from Supabase to local cache
  Future<Drug?> syncDrugFromSupabase(String drugId) async {
    try {
      // Try by generic name
      final remoteDrug = await _supabaseService.getDrugByGenericName(drugId);
      if (remoteDrug == null) return null;
      return _convertRemoteToRemote(remoteDrug);
    } catch (e) {
      debugPrint('Failed to sync drug from Supabase: $e');
      return null;
    }
  }

  /// Convert Supabase drug format to local Drug model
  Drug _convertRemoteToRemote(Map<String, dynamic> remote) {
    return Drug(
      id: remote['id'],
      genericName: remote['generic_name'] ?? '',
      tradeNames: List<String>.from(remote['trade_names'] ?? const []),
      sideEffects: List<String>.from(remote['side_effects'] ?? []),
      commonSideEffects: List<String>.from(remote['common_side_effects'] ?? []),
      rareSideEffects: List<String>.from(remote['rare_side_effects'] ?? []),
      seriousSideEffects: List<String>.from(
        remote['serious_side_effects'] ?? [],
      ),
      drugClass: remote['drug_class'],
      mechanism: remote['mechanism'],
      indications: List<String>.from(remote['indications'] ?? []),
      contraindications: List<String>.from(remote['contraindications'] ?? []),
      warnings: List<String>.from(remote['warnings'] ?? []),
      blackBoxWarnings: List<String>.from(remote['black_box_warnings'] ?? []),
      dosageInfo: null, // Would need to parse nested dosage info
      interactsWith: List<String>.from(remote['interacts_with'] ?? []),
      cachedAt: DateTime.tryParse(remote['cached_at'] ?? ''),
    );
  }

  /// Check migration status
  Future<Map<String, dynamic>> checkMigrationStatus() async {
    try {
      final localDrugs = await _localService.getAllCachedDrugs();
      final remoteDrugs = await _supabaseService.getAllDrugs(pageSize: 1);

      // Get count from Supabase (first page count is approximate)
      final remoteCount = remoteDrugs.isNotEmpty ? 1 : 0; // Simplified check

      return {
        'local_count': localDrugs.length,
        'remote_count': remoteCount,
        'needs_migration': localDrugs.length > remoteCount,
      };
    } catch (e) {
      return {'error': 'Failed to check migration status: $e'};
    }
  }
}
