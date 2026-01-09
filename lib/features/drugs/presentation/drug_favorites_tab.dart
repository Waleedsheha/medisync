//lib/features/drugs/presentation/drug_favorites_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/glass_theme.dart';
import '../../../core/presentation/glass_widgets.dart';
import '../../../core/models/drug.dart';
import 'drug_search_tab.dart';
import 'drug_detail_screen.dart';

/// Drug Favorites Tab
class DrugFavoritesTab extends ConsumerStatefulWidget {
  const DrugFavoritesTab({super.key});

  @override
  ConsumerState<DrugFavoritesTab> createState() => _DrugFavoritesTabState();
}

class _DrugFavoritesTabState extends ConsumerState<DrugFavoritesTab> {
  List<Drug> _favorites = [];
  List<Drug> _recent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = ref.read(drugDatabaseProvider);
    await service.initialize();

    final favorites = await service.getFavorites();
    final recent = await service.getRecentDrugs();

    setState(() {
      _favorites = favorites;
      _recent = recent;
      _isLoading = false;
    });
  }

  void _openDrugDetail(Drug drug) {
    ref.read(drugDatabaseProvider).addToRecent(drug.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrugDetailScreen(drug: drug)),
    ).then((_) => _loadData()); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: GlassTheme.neonPurple),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: GlassTheme.neonPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Favorites section
            Row(
              children: [
                const Icon(LucideIcons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Favorites',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_favorites.length} drugs',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_favorites.isEmpty)
              GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.star,
                      color: Colors.amber.withValues(alpha: 0.3),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No favorites yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Star drugs to add them here',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ...(_favorites.map(
                (drug) => _DrugListTile(
                  drug: drug,
                  onTap: () => _openDrugDetail(drug),
                  trailing: const Icon(
                    LucideIcons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              )),

            const SizedBox(height: 24),

            // Recent section
            Row(
              children: [
                const Icon(
                  LucideIcons.clock,
                  color: GlassTheme.neonCyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recently Viewed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_recent.length} drugs',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_recent.isEmpty)
              GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      color: GlassTheme.neonCyan.withValues(alpha: 0.3),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No recent drugs',
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Search and view drugs to see them here',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ...(_recent.map(
                (drug) => _DrugListTile(
                  drug: drug,
                  onTap: () => _openDrugDetail(drug),
                ),
              )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DrugListTile extends StatelessWidget {
  final Drug drug;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DrugListTile({required this.drug, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: GlassTheme.neonPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.pill,
              color: GlassTheme.neonPurple,
              size: 18,
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
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (drug.tradeNames.isNotEmpty)
                  Text(
                    drug.tradeNames.join(', '),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          const SizedBox(width: 4),
          const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 18),
        ],
      ),
    );
  }
}
