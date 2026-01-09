// lib/features/patients/presentation/lab_ranges_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lab_ranges_providers.dart';
import '../models/labs/lab_catalog.dart';

class LabRangesSettingsScreen extends ConsumerStatefulWidget {
  const LabRangesSettingsScreen({
    super.key,
    required this.hospitalName,
    required this.unitName,
    required this.title,
    required this.gender,
  });

  final String hospitalName;
  final String unitName;
  final String title;
  final String gender;

  @override
  ConsumerState<LabRangesSettingsScreen> createState() =>
      _LabRangesSettingsScreenState();
}

class _LabRangesSettingsScreenState
    extends ConsumerState<LabRangesSettingsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final overrides = ref.watch(
      labRangesForScopeProvider((
        hospitalName: widget.hospitalName,
        unitName: widget.unitName,
      )),
    );
    final notifier = ref.read(
      labRangesForScopeProvider((
        hospitalName: widget.hospitalName,
        unitName: widget.unitName,
      )).notifier,
    );

    final filteredGroups = LabCatalog.groups
        .map((g) {
          final tests = g.tests.where((t) {
            if (_query.trim().isEmpty) return true;
            final q = _query.trim().toLowerCase();
            return t.key.toLowerCase().contains(q) ||
                t.label.toLowerCase().contains(q) ||
                g.title.toLowerCase().contains(q);
          }).toList();
          return (g.title, tests);
        })
        .where((x) => x.$2.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Reset all',
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset ranges?'),
                  content: const Text(
                    'This will remove all custom ranges for this hospital/unit.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await notifier.resetAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Reset done')));
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search lab',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),

          ...filteredGroups.map((tuple) {
            final groupTitle = tuple.$1;
            final tests = tuple.$2;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...tests.map((t) {
                      final hasOverride = overrides.containsKey(t.key);
                      final effective = LabCatalog.effectiveRange(
                        def: t,
                        gender: widget.gender,
                        overrides: overrides,
                      );

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${t.label}  (${t.key})',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          'Normal: ${effective.normalText(unit: t.unit)}'
                          '${t.unit.isEmpty ? '' : '\nUnit: ${t.unit}'}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (hasOverride)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.14),
                                ),
                                child: const Text(
                                  'Custom',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () async {
                                final current =
                                    overrides[t.key] ??
                                    t.rangeForGender(widget.gender);
                                final res = await showDialog<_EditRangeResult>(
                                  context: context,
                                  builder: (_) => _EditRangeDialog(
                                    def: t,
                                    initial: current,
                                  ),
                                );
                                if (res == null) return;

                                if (res.clear) {
                                  await notifier.removeOverride(t.key);
                                } else if (res.range != null) {
                                  await notifier.setOverride(t.key, res.range!);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EditRangeResult {
  final LabRange? range;
  final bool clear;

  const _EditRangeResult({this.range, required this.clear});
}

class _EditRangeDialog extends StatefulWidget {
  const _EditRangeDialog({required this.def, required this.initial});
  final LabDef def;
  final LabRange initial;

  @override
  State<_EditRangeDialog> createState() => _EditRangeDialogState();
}

class _EditRangeDialogState extends State<_EditRangeDialog> {
  late final TextEditingController nLow;
  late final TextEditingController nHigh;
  late final TextEditingController cLow;
  late final TextEditingController cHigh;

  @override
  void initState() {
    super.initState();
    nLow = TextEditingController(text: _s(widget.initial.normalLow));
    nHigh = TextEditingController(text: _s(widget.initial.normalHigh));
    cLow = TextEditingController(text: _s(widget.initial.criticalLow));
    cHigh = TextEditingController(text: _s(widget.initial.criticalHigh));
  }

  @override
  void dispose() {
    nLow.dispose();
    nHigh.dispose();
    cLow.dispose();
    cHigh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit range • ${widget.def.key}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.def.label,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            if (widget.def.unit.isNotEmpty) Text('Unit: ${widget.def.unit}'),
            const SizedBox(height: 14),

            _numField(nLow, 'Normal low'),
            const SizedBox(height: 10),
            _numField(nHigh, 'Normal high'),
            const SizedBox(height: 10),
            _numField(cLow, 'Critical low'),
            const SizedBox(height: 10),
            _numField(cHigh, 'Critical high'),
            const SizedBox(height: 10),

            Text(
              'Leave empty if not applicable.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const _EditRangeResult(clear: true)),
          child: const Text('Clear custom'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.numbers),
      ),
    );
  }

  void _save() {
    double? p(TextEditingController c) {
      final raw = c.text.trim();
      if (raw.isEmpty) return null;
      final v = double.tryParse(raw.replaceAll(',', '.'));
      return v;
    }

    final range = LabRange(
      normalLow: p(nLow),
      normalHigh: p(nHigh),
      criticalLow: p(cLow),
      criticalHigh: p(cHigh),
    );

    Navigator.pop(context, _EditRangeResult(range: range, clear: false));
  }

  static String _s(double? v) {
    if (v == null) return '';
    final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
    return s.replaceAll(RegExp(r'\.?0+$'), '');
  }
}
