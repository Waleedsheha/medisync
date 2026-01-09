//lib/features/drugs/presentation/drug_library_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/glass_theme.dart';
import '../../../core/presentation/glass_widgets.dart';
import '../../../core/models/drug.dart';
import 'drug_search_tab.dart';
import 'drug_detail_screen.dart';

/// Drug Library Tab - All cached drugs
class DrugLibraryTab extends ConsumerStatefulWidget {
  const DrugLibraryTab({super.key});

  @override
  ConsumerState<DrugLibraryTab> createState() => _DrugLibraryTabState();
}

class _DrugLibraryTabState extends ConsumerState<DrugLibraryTab> {
  List<Drug> _allDrugs = [];
  bool _isLoading = true;
  String _selectedLetter = 'A';
  int _favoritesCount = 0;
  int _recentCount = 0;

  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

  @override
  void initState() {
    super.initState();
    _loadDrugs();
  }

  Future<void> _loadDrugs() async {
    final service = ref.read(drugDatabaseProvider);
    await service.initialize();

    final drugs = await service.getAllCachedDrugs();
    final favs = await service.getFavorites();
    final recent = await service.getRecentDrugs();

    setState(() {
      _allDrugs = drugs;
      _favoritesCount = favs.length;
      _recentCount = recent.length;
      _isLoading = false;
    });
  }

  List<Drug> get _filteredDrugs {
    return _allDrugs.where((drug) {
      return drug.genericName.toUpperCase().startsWith(_selectedLetter);
    }).toList();
  }

  void _openDrugDetail(Drug drug) {
    ref.read(drugDatabaseProvider).addToRecent(drug.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrugDetailScreen(drug: drug)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: GlassTheme.neonPurple),
      );
    }

    return Column(
      children: [
        // Stats bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: LucideIcons.database,
                  label: 'Cached',
                  value: '${_allDrugs.length}',
                  color: GlassTheme.neonPurple,
                ),
                Container(width: 1, height: 30, color: Colors.white12),
                _StatItem(
                  icon: LucideIcons.star,
                  label: 'Favorites',
                  value: '$_favoritesCount',
                  color: Colors.amber,
                ),
                Container(width: 1, height: 30, color: Colors.white12),
                _StatItem(
                  icon: LucideIcons.clock,
                  label: 'Recent',
                  value: '$_recentCount',
                  color: GlassTheme.neonCyan,
                ),
              ],
            ),
          ),
        ),

        // A-Z selector
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _alphabet.length,
            itemBuilder: (context, index) {
              final letter = _alphabet[index];
              final isSelected = letter == _selectedLetter;
              final hasItems = _allDrugs.any(
                (d) => d.genericName.toUpperCase().startsWith(letter),
              );

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  onTap: hasItems
                      ? () => setState(() => _selectedLetter = letter)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GlassTheme.neonPurple.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? GlassTheme.neonPurple
                            : hasItems
                            ? Colors.white24
                            : Colors.white10,
                      ),
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: isSelected
                            ? GlassTheme.neonPurple
                            : hasItems
                            ? Colors.white
                            : Colors.white30,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Drug list
        Expanded(
          child: _allDrugs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.library,
                        size: 64,
                        color: GlassTheme.neonPurple.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your library is empty',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Search for drugs to add them here',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : _filteredDrugs.isEmpty
              ? Center(
                  child: Text(
                    'No drugs starting with "$_selectedLetter"',
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDrugs,
                  color: GlassTheme.neonPurple,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = _filteredDrugs[index];
                      return _DrugTile(
                        drug: drug,
                        onTap: () => _openDrugDetail(drug),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

class _DrugTile extends StatelessWidget {
  final Drug drug;
  final VoidCallback onTap;

  const _DrugTile({required this.drug, required this.onTap});

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
            child: Center(
              child: Text(
                drug.genericName[0].toUpperCase(),
                style: const TextStyle(
                  color: GlassTheme.neonPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                  ),
                ),
                if (drug.drugClass != null)
                  Text(
                    drug.drugClass!,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 18),
        ],
      ),
    );
  }
}
