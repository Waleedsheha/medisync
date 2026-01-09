//lib/features/drugs/presentation/drug_interaction_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/glass_theme.dart';
import '../../../core/presentation/glass_widgets.dart';
import '../../../core/models/drug.dart';
import '../../../core/models/drug_interaction.dart';
import '../../../core/providers/interaction_provider.dart';
import 'drug_search_tab.dart';

/// Drug Interaction Checker Tab
class DrugInteractionTab extends ConsumerStatefulWidget {
  const DrugInteractionTab({super.key});

  @override
  ConsumerState<DrugInteractionTab> createState() => _DrugInteractionTabState();
}

class _DrugInteractionTabState extends ConsumerState<DrugInteractionTab> {
  List<DrugInteraction> _interactions = [];
  bool _isLoading = false;
  bool _hasChecked = false;

  void _addDrug() async {
    final selectedDrugs = ref.read(selectedDrugsForInteractionProvider);
    final service = ref.read(drugDatabaseProvider);
    await service.initialize();
    final cachedDrugs = await service.getAllCachedDrugs();

    if (!mounted) return;

    if (cachedDrugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search for drugs first to add them to your library'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show drug picker
    final selected = await showModalBottomSheet<Drug>(
      context: context,
      backgroundColor: GlassTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DrugPickerSheet(
        drugs: cachedDrugs,
        excludeIds: selectedDrugs.map((d) => d.id).toList(),
      ),
    );

    if (selected != null) {
      ref.read(selectedDrugsForInteractionProvider.notifier).addDrug(selected);
      setState(() {
        _hasChecked = false;
        _interactions = [];
      });
    }
  }

  void _removeDrug(Drug drug) {
    ref.read(selectedDrugsForInteractionProvider.notifier).removeDrug(drug.id);
    setState(() {
      _hasChecked = false;
      _interactions = [];
    });
  }

  Future<void> _checkInteractions() async {
    final selectedDrugs = ref.read(selectedDrugsForInteractionProvider);
    if (selectedDrugs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least 2 drugs to check interactions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(drugDatabaseProvider);
      final drugIds = selectedDrugs.map((d) => d.id).toList();
      final interactions = await service.checkInteractions(drugIds);

      setState(() {
        _interactions = interactions;
        _hasChecked = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking interactions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDrugs = ref.watch(selectedDrugsForInteractionProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Selected drugs
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.pill,
                      color: GlassTheme.neonPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Selected Drugs',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${selectedDrugs.length} drugs',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Drug chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...selectedDrugs.map(
                      (drug) => Chip(
                        label: Text(
                          drug.genericName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: GlassTheme.neonPurple.withValues(
                          alpha: 0.2,
                        ),
                        deleteIconColor: Colors.white54,
                        onDeleted: () => _removeDrug(drug),
                        side: BorderSide(
                          color: GlassTheme.neonPurple.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    // Add button
                    ActionChip(
                      avatar: const Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: GlassTheme.neonCyan,
                      ),
                      label: const Text(
                        'Add Drug',
                        style: TextStyle(
                          color: GlassTheme.neonCyan,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: GlassTheme.neonCyan.withValues(
                        alpha: 0.1,
                      ),
                      side: BorderSide(
                        color: GlassTheme.neonCyan.withValues(alpha: 0.5),
                      ),
                      onPressed: _addDrug,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Check button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: selectedDrugs.length >= 2 && !_isLoading
                  ? _checkInteractions
                  : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.search),
              label: Text(_isLoading ? 'Checking...' : 'Check Interactions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.neonPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _hasChecked
                ? _interactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.checkCircle,
                                  color: Colors.green,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No interactions found',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'These drugs appear safe to use together',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _interactions.length,
                          itemBuilder: (context, index) {
                            return _InteractionCard(
                              interaction: _interactions[index],
                            );
                          },
                        )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add drugs to check for interactions',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select from your cached drug library',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InteractionCard extends StatelessWidget {
  final DrugInteraction interaction;

  const _InteractionCard({required this.interaction});

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    switch (interaction.severity) {
      case InteractionSeverity.major:
        severityColor = Colors.red;
        break;
      case InteractionSeverity.moderate:
        severityColor = Colors.orange;
        break;
      case InteractionSeverity.minor:
        severityColor = Colors.green;
        break;
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: severityColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      interaction.severity.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      interaction.severity.displayName.toUpperCase(),
                      style: TextStyle(
                        color: severityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                interaction.source,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Drug names
          Row(
            children: [
              Expanded(
                child: Text(
                  interaction.drug1Name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  LucideIcons.arrowLeftRight,
                  color: Colors.white38,
                  size: 16,
                ),
              ),
              Expanded(
                child: Text(
                  interaction.drug2Name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            interaction.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          // Management
          if (interaction.management != null &&
              interaction.management!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.lightbulb,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      interaction.management!,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrugPickerSheet extends StatelessWidget {
  final List<Drug> drugs;
  final List<String> excludeIds;

  const _DrugPickerSheet({required this.drugs, required this.excludeIds});

  @override
  Widget build(BuildContext context) {
    final availableDrugs = drugs
        .where((d) => !excludeIds.contains(d.id))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: SizedBox(
              width: 40,
              child: Divider(thickness: 3, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a Drug',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'From your cached library',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: availableDrugs.isEmpty
                ? const Center(
                    child: Text(
                      'No drugs available',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: availableDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = availableDrugs[index];
                      return ListTile(
                        leading: Container(
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
                        title: Text(
                          drug.genericName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: drug.tradeNames.isNotEmpty
                            ? Text(
                                drug.tradeNames.first,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        onTap: () => Navigator.pop(context, drug),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
