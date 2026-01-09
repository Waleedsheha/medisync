//lib/features/drugs/presentation/drug_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/glass_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'drug_search_tab.dart';
import 'drug_interaction_tab.dart';
import 'drug_favorites_tab.dart';
import 'drug_library_tab.dart';

/// Main Drug Library screen with tabs
class DrugLibraryScreen extends ConsumerStatefulWidget {
  const DrugLibraryScreen({super.key});

  @override
  ConsumerState<DrugLibraryScreen> createState() => _DrugLibraryScreenState();
}

class _DrugLibraryScreenState extends ConsumerState<DrugLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Drug Library',
      showBottomNavBar: true,
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: GlassTheme.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: GlassTheme.neonPurple.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: GlassTheme.neonPurple,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(icon: Icon(LucideIcons.search, size: 20), text: 'Search'),
                Tab(
                  icon: Icon(LucideIcons.alertTriangle, size: 20),
                  text: 'Interact',
                ),
                Tab(icon: Icon(LucideIcons.star, size: 20), text: 'Favorites'),
                Tab(icon: Icon(LucideIcons.library, size: 20), text: 'Library'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                DrugSearchTab(),
                DrugInteractionTab(),
                DrugFavoritesTab(),
                DrugLibraryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
