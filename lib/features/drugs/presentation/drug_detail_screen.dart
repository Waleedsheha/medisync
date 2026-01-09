//lib/features/drugs/presentation/drug_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/glass_theme.dart';
import '../../../core/presentation/glass_widgets.dart';
import '../../../core/models/drug.dart';
import '../../../core/providers/interaction_provider.dart';
import 'drug_search_tab.dart';

/// Drug Detail Screen - Full drug monograph
class DrugDetailScreen extends ConsumerStatefulWidget {
  final Drug drug;

  const DrugDetailScreen({super.key, required this.drug});

  @override
  ConsumerState<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends ConsumerState<DrugDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  void _checkFavorite() {
    final service = ref.read(drugDatabaseProvider);
    setState(() {
      _isFavorite = service.isFavorite(widget.drug.id);
    });
  }

  void _toggleFavorite() async {
    final service = ref.read(drugDatabaseProvider);
    if (_isFavorite) {
      await service.removeFavorite(widget.drug.id);
    } else {
      await service.addFavorite(widget.drug.id);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final drug = widget.drug;

    return Scaffold(
      backgroundColor: GlassTheme.deepBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          drug.genericName,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final selectedDrugs = ref.watch(
                selectedDrugsForInteractionProvider,
              );
              final isAlreadyAdded = selectedDrugs.any((d) => d.id == drug.id);

              return IconButton(
                icon: Icon(
                  isAlreadyAdded
                      ? LucideIcons.checkCircle
                      : LucideIcons.plusCircle,
                  color: isAlreadyAdded ? GlassTheme.neonCyan : Colors.white,
                ),
                tooltip: isAlreadyAdded ? 'Added to Checker' : 'Add to Checker',
                onPressed: () {
                  if (!isAlreadyAdded) {
                    ref
                        .read(selectedDrugsForInteractionProvider.notifier)
                        .addDrug(drug);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${drug.genericName} added to Interaction Checker',
                        ),
                        backgroundColor: GlassTheme.neonPurple,
                        action: SnackBarAction(
                          label: 'CHECK NOW',
                          textColor: Colors.white,
                          onPressed: () {
                            // This depends on the parent navigation, usually better to just let them switch tabs
                          },
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? LucideIcons.star : LucideIcons.star,
              color: _isFavorite ? Colors.amber : Colors.white54,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                drug.genericName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (drug.tradeNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Trade names: ${drug.tradeNames.join(', ')}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),

              // Main Data Table
              Table(
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                columnWidths: const {
                  0: FixedColumnWidth(140), // Label column
                  1: FlexColumnWidth(), // Content column
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                children: [
                  if (drug.drugClass != null)
                    _buildTableRow(
                      'Class',
                      Text(drug.drugClass!, style: _contentStyle),
                    ),

                  if (drug.mechanism != null && drug.mechanism!.isNotEmpty)
                    _buildTableRow(
                      'Mechanism',
                      Text(drug.mechanism!, style: _contentStyle),
                    ),

                  if (drug.indications.isNotEmpty)
                    _buildTableRow(
                      'Indications',
                      _buildBulletList(drug.indications, Colors.green),
                    ),

                  if (drug.contraindications.isNotEmpty)
                    _buildTableRow(
                      'Contraindications',
                      _buildBulletList(drug.contraindications, Colors.red),
                    ),

                  if (drug.warnings.isNotEmpty)
                    _buildTableRow(
                      'Warnings',
                      _buildBulletList(drug.warnings, Colors.orange),
                    ),

                  if (drug.blackBoxWarnings.isNotEmpty)
                    _buildTableRow(
                      'Black Box Warning',
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _buildBulletList(
                          drug.blackBoxWarnings,
                          Colors.redAccent,
                        ),
                      ),
                    ),
                ],
              ),

              // Side Effects
              if (drug.sideEffects.isNotEmpty ||
                  drug.commonSideEffects.isNotEmpty ||
                  drug.rareSideEffects.isNotEmpty ||
                  drug.seriousSideEffects.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text(
                  'SIDE EFFECTS',
                  style: TextStyle(
                    color: GlassTheme.neonCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(140),
                    1: FlexColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.top,
                  children: [
                    if (drug.seriousSideEffects.isNotEmpty)
                      _buildTableRow(
                        'Serious',
                        _buildBulletList(
                          drug.seriousSideEffects,
                          Colors.redAccent,
                        ),
                      ),
                    if (drug.commonSideEffects.isNotEmpty)
                      _buildTableRow(
                        'Common',
                        _buildBulletList(
                          drug.commonSideEffects,
                          Colors.orangeAccent,
                        ),
                      ),
                    if (drug.rareSideEffects.isNotEmpty)
                      _buildTableRow(
                        'Rare',
                        _buildBulletList(
                          drug.rareSideEffects,
                          Colors.orangeAccent,
                        ),
                      ),
                    if (drug.sideEffects.isNotEmpty &&
                        drug.commonSideEffects.isEmpty &&
                        drug.rareSideEffects.isEmpty &&
                        drug.seriousSideEffects.isEmpty)
                      _buildTableRow(
                        'Side Effects',
                        _buildBulletList(drug.sideEffects, Colors.orangeAccent),
                      ),
                  ],
                ),
              ],

              // Interactions Section
              const SizedBox(height: 32),
              Row(
                children: [
                  const Text(
                    'DRUG INTERACTIONS',
                    style: TextStyle(
                      color: GlassTheme.neonCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Consumer(
                    builder: (context, ref, child) {
                      return TextButton.icon(
                        icon: const Icon(LucideIcons.plus, size: 14),
                        label: const Text(
                          'Add to Checker',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          ref
                              .read(
                                selectedDrugsForInteractionProvider.notifier,
                              )
                              .addDrug(drug);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: GlassTheme.neonCyan,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (drug.interactsWith.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.info,
                        color: Colors.white38,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No major specific interactions listed for this drug record.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Could trigger a specific AI fetch for generic interactions
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassTheme.neonCyan.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: GlassTheme.neonCyan,
                          elevation: 0,
                          side: const BorderSide(color: GlassTheme.neonCyan),
                        ),
                        child: const Text(
                          'Check for Interactions with another Drug',
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildInteractionCard(drug.interactsWith),

              // Dosage Section (Separate Header)
              const SizedBox(height: 32),
              const Text(
                'DOSAGE & ADMINISTRATION',
                style: TextStyle(
                  color: GlassTheme.neonCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              Table(
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                columnWidths: const {
                  0: FixedColumnWidth(140),
                  1: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                children: [
                  // Standard Dosing
                  if (drug.dosageInfo != null &&
                      drug.dosageInfo!.standardDoses.isNotEmpty)
                    _buildTableRow(
                      'Standard Dosing',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: drug.dosageInfo!.standardDoses.map((dose) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dose.indication,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Route: ${dose.route}',
                                  style: _contentStyle,
                                ),
                                Text(
                                  'Dose: ${dose.dose}',
                                  style: _contentStyle,
                                ),
                                Text(
                                  'Freq: ${dose.frequency}',
                                  style: _contentStyle,
                                ),
                                if (dose.notes != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Note: ${dose.notes}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Renal Dosing
                  if (drug.dosageInfo?.renalDosing != null)
                    _buildTableRow(
                      'Renal Adjustments',
                      _buildRenalTable(drug.dosageInfo!.renalDosing!),
                    ),

                  // Hepatic Dosing
                  if (drug.dosageInfo?.hepaticDosing != null)
                    _buildTableRow(
                      'Hepatic Adjustments',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSimpleRow(
                            'Class A',
                            drug.dosageInfo!.hepaticDosing!.childPughA,
                          ),
                          _buildSimpleRow(
                            'Class B',
                            drug.dosageInfo!.hepaticDosing!.childPughB,
                          ),
                          _buildSimpleRow(
                            'Class C',
                            drug.dosageInfo!.hepaticDosing!.childPughC,
                          ),
                          if (drug.dosageInfo!.hepaticDosing!.notes != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                drug.dosageInfo!.hepaticDosing!.notes!,
                                style: _subNoteStyle,
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Pediatric
                  if (drug.dosageInfo?.pediatricDosing != null)
                    _buildTableRow(
                      'Pediatric',
                      Text(
                        drug.dosageInfo!.pediatricDosing!.notes ??
                            'See details',
                        style: _contentStyle,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Cached: ${_formatDate(drug.cachedAt)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final TextStyle _contentStyle = const TextStyle(
    color: Colors.white70,
    fontSize: 14,
    height: 1.5,
  );
  final TextStyle _subNoteStyle = const TextStyle(
    color: Colors.white38,
    fontSize: 12,
    fontStyle: FontStyle.italic,
  );

  TableRow _buildTableRow(String label, Widget content) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: content,
        ),
      ],
    );
  }

  Widget _buildBulletList(List<String> items, Color bulletColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: bulletColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(child: Text(item, style: _contentStyle)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSimpleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenalTable(RenalDosing data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSimpleRow('CrCl > 50 mL/min', data.crClGreater50),
        _buildSimpleRow('CrCl 30-50 mL/min', data.crCl30to50),
        _buildSimpleRow('CrCl 10-30 mL/min', data.crCl10to30),
        _buildSimpleRow('CrCl < 10 mL/min', data.crClLess10),
        if (data.dialysis != null) _buildSimpleRow('Dialysis', data.dialysis!),
        if (data.notes != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(data.notes!, style: _subNoteStyle),
          ),
      ],
    );
  }

  Widget _buildInteractionCard(List<String> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.orange.withValues(alpha: 0.1), height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            dense: true,
            leading: const Icon(
              LucideIcons.alertTriangle,
              color: Colors.orange,
              size: 16,
            ),
            title: Text(
              item,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
