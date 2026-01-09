//lib/features/calculators/presentation/medicalc_list_screen.dart
library;

/// Medicalc Calculator List Screen with Tabbed Categories
/// Displays calculators organized by tier/category in separate tabs.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medisynch/app/glass_theme.dart';
import 'package:medisynch/core/presentation/glass_widgets.dart';
import 'package:medisynch/core/widgets/app_scaffold.dart';
import '../domain/calculators.dart';

class MedicalcListScreen extends StatefulWidget {
  const MedicalcListScreen({super.key});

  @override
  State<MedicalcListScreen> createState() => _MedicalcListScreenState();
}

class _MedicalcListScreenState extends State<MedicalcListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<MedicalCalculator> _allCalculators = defaultCalculators();
  late Map<String, List<MedicalCalculator>> _groupedCalculators;
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    _groupedCalculators = _groupCalculatorsByCategory();
    _categories = _groupedCalculators.keys.toList();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, List<MedicalCalculator>> _groupCalculatorsByCategory() {
    final Map<String, List<MedicalCalculator>> grouped = {};
    for (final calc in _allCalculators) {
      grouped.putIfAbsent(calc.category, () => []).add(calc);
    }
    return grouped;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hemodynamics':
        return LucideIcons.heartPulse;
      case 'Renal & Fluids':
        return LucideIcons.droplets;
      case 'Cardiac Risk':
        return LucideIcons.heart;
      case 'Respiratory':
        return LucideIcons.wind;
      case 'Liver':
        return LucideIcons.pill;
      case 'Major Clinical Scores':
        return LucideIcons.star;
      case 'General':
      default:
        return LucideIcons.calculator;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Hemodynamics':
        return GlassTheme.neonCyan;
      case 'Renal & Fluids':
        return GlassTheme.neonBlue;
      case 'Cardiac Risk':
        return GlassTheme.neonPurple;
      case 'Respiratory':
        return const Color(0xFF4CAF50);
      case 'Liver':
        return const Color(0xFFFF9800);
      case 'Major Clinical Scores':
        return GlassTheme.neonCyan;
      default:
        return Colors.white70;
    }
  }

  String _getShortCategoryName(String category) {
    switch (category) {
      case 'Hemodynamics':
        return 'Vitals';
      case 'Renal & Fluids':
        return 'Renal';
      case 'Cardiac Risk':
        return 'Cardiac';
      case 'Major Clinical Scores':
        return 'Scores';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Medicalc',
      showBottomNavBar: true,
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: GlassTheme.neonCyan.withValues(alpha: 0.2),
                border: Border.all(
                  color: GlassTheme.neonCyan.withValues(alpha: 0.5),
                ),
              ),
              labelColor: GlassTheme.neonCyan,
              unselectedLabelColor: Colors.white54,
              labelStyle: GlassTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GlassTheme.textTheme.labelMedium,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.all(4),
              tabs: _categories.map((category) {
                return Tab(
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getCategoryIcon(category), size: 16),
                        const SizedBox(width: 6),
                        Text(_getShortCategoryName(category)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                final calculators = _groupedCalculators[category]!;
                final categoryColor = _getCategoryColor(category);

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: calculators.length,
                  itemBuilder: (context, index) {
                    final calc = calculators[index];
                    return _CalculatorCard(
                      calculator: calc,
                      color: categoryColor,
                      onTap: () => context.push('/medicalc/${calc.id}'),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final MedicalCalculator calculator;
  final Color color;
  final VoidCallback onTap;

  const _CalculatorCard({
    required this.calculator,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Short name badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  calculator.shortName,
                  style: GlassTheme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontSize: calculator.shortName.length > 5 ? 10 : 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    calculator.fullName,
                    style: GlassTheme.textTheme.headlineMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    calculator.description,
                    style: GlassTheme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
