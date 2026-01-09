//lib/features/drugs/presentation/drug_search_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/glass_theme.dart';
import '../../../core/presentation/glass_widgets.dart';
import '../../../core/models/drug.dart';
import '../../../core/services/drug_database_service.dart';
import 'drug_detail_screen.dart';

/// Provider for drug database service
final drugDatabaseProvider = Provider((ref) => DrugDatabaseService());

/// Drug Search Tab with autocomplete
class DrugSearchTab extends ConsumerStatefulWidget {
  const DrugSearchTab({super.key});

  @override
  ConsumerState<DrugSearchTab> createState() => _DrugSearchTabState();
}

class _DrugSearchTabState extends ConsumerState<DrugSearchTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Drug> _results = [];
  bool _isLoading = false;
  bool _fromCache = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(drugDatabaseProvider);
      await service.initialize();
      final response = await service.searchDrugs(query);

      setState(() {
        _results = response.drugs;
        _fromCache = response.fromCache;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  void _openDrugDetail(Drug drug) {
    // Add to recent
    ref.read(drugDatabaseProvider).addToRecent(drug.id);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrugDetailScreen(drug: drug)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search input
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search drug name...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: GlassTheme.neonPurple,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _search(value);
                }
              },
              onSubmitted: _search,
            ),
          ),

          const SizedBox(height: 16),

          // Status indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircularProgressIndicator(color: GlassTheme.neonPurple),
                  SizedBox(height: 12),
                  Text(
                    'Fetching from database...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    color: Colors.red,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (_results.isEmpty && _searchController.text.length >= 2)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(LucideIcons.searchX, color: Colors.white38, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No drugs found',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Try a different search term',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            )
          else if (_results.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.pill,
                      size: 64,
                      color: GlassTheme.neonPurple.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Search for a medication',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'e.g., Metformin, Lisinopril, Warfarin',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            // Results list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cache indicator
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          _fromCache ? LucideIcons.database : LucideIcons.cloud,
                          size: 14,
                          color: _fromCache
                              ? Colors.green
                              : GlassTheme.neonCyan,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _fromCache ? 'From database' : 'Fetched & saved',
                          style: TextStyle(
                            color: _fromCache
                                ? Colors.green
                                : GlassTheme.neonCyan,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_results.length} results',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final drug = _results[index];
                        return _DrugListItem(
                          drug: drug,
                          onTap: () => _openDrugDetail(drug),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DrugListItem extends StatelessWidget {
  final Drug drug;
  final VoidCallback onTap;

  const _DrugListItem({required this.drug, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: GlassTheme.neonPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.pill,
              color: GlassTheme.neonPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug.genericName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (drug.tradeNames.isNotEmpty)
                  Text(
                    drug.tradeNames.join(', '),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (drug.drugClass != null)
                  Text(
                    drug.drugClass!,
                    style: TextStyle(
                      color: GlassTheme.neonCyan.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 20),
        ],
      ),
    );
  }
}
