import 'package:flutter/material.dart';

import '../../models/labs/lab_catalog.dart';
import 'shared_widgets.dart';

Future<LabEntryUi?> showAddLabEntryDialog({
  required BuildContext context,
  required String gender,
  required Map<String, LabRange> overrides,
}) {
  return showDialog<LabEntryUi>(
    context: context,
    builder: (ctx) => AddLabEntryDialog(gender: gender, overrides: overrides),
  );
}

class CriticalFinding {
  final String key;
  final String label;
  final double value;
  final String unit;

  const CriticalFinding({
    required this.key,
    required this.label,
    required this.value,
    required this.unit,
  });
}

List<CriticalFinding> criticalFindings({
  required LabEntryUi entry,
  required String gender,
  required Map<String, LabRange> overrides,
}) {
  final out = <CriticalFinding>[];
  entry.values.forEach((key, value) {
    final def = LabCatalog.byKey[key];
    if (def == null) return;

    final r = LabCatalog.effectiveRange(
      def: def,
      gender: gender,
      overrides: overrides,
    );
    final st = LabCatalog.evaluateWithRange(range: r, value: value);

    if (st == LabStatus.critical) {
      out.add(
        CriticalFinding(
          key: key,
          label: def.label,
          value: value,
          unit: def.unit,
        ),
      );
    }
  });
  return out;
}

Future<void> showCriticalLabDialog(
  BuildContext context,
  List<CriticalFinding> critical,
  DateTime date,
) {
  String d(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('⚠️ Critical lab value'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date: ${d(date)}'),
          const SizedBox(height: 10),
          ...critical.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• ${c.label}: ${_fmt(c.value)} ${c.unit}'.trim()),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please verify the result & act according to clinical context and local lab policy.',
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

String _fmt(double v) {
  final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
  return s.replaceAll(RegExp(r'\.?0+$'), '');
}

class LabsTab extends StatelessWidget {
  const LabsTab({
    super.key,
    required this.entries,
    required this.gender,
    required this.overrides,
    required this.onRequestAddEntry,
    required this.onDeleteEntry,
  });

  final List<LabEntryUi> entries;
  final String gender;
  final Map<String, LabRange> overrides;

  final Future<void> Function() onRequestAddEntry;
  final void Function(int index) onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const SectionTitle('Labs'),
            const Spacer(),
            TextButton.icon(
              onPressed: onRequestAddEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add entry'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.biotech_outlined, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    'No lab entries yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add a new lab entry and it will appear as a new column on the right.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onRequestAddEntry,
                    icon: const Icon(Icons.add),
                    label: const Text('Add lab entry'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          CumulativeLabCard(
            entries: entries,
            gender: gender,
            overrides: overrides,
          ),
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              title: const Text(
                'Manage entries',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'Delete wrong days if needed',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: entries.asMap().entries.map((e) {
                      final idx = e.key;
                      final entry = e.value;
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              CumulativeLabCard.fmtDateShort(entry.date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => onDeleteEntry(idx),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete entry',
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ===================== LABS UI (same logic you already had) =====================

class CumulativeLabCard extends StatelessWidget {
  const CumulativeLabCard({
    super.key,
    required this.entries,
    required this.gender,
    required this.overrides,
  });

  final List<LabEntryUi> entries;
  final String gender;
  final Map<String, LabRange> overrides;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final dayMap = <String, List<LabEntryUi>>{};
    for (final e in entries) {
      final k = _dayKey(e.date);
      dayMap.putIfAbsent(k, () => []).add(e);
    }

    final sortedKeys = dayMap.keys.toList()..sort();
    final snapshots = <_DaySnapshot>[];

    for (final k in sortedKeys) {
      final list = [...dayMap[k]!]..sort((a, b) => a.date.compareTo(b.date));
      final latest = <String, double>{};
      for (final entry in list) {
        entry.values.forEach((labKey, v) {
          latest[labKey] = v;
        });
      }
      final d = list.last.date;
      snapshots.add(
        _DaySnapshot(date: DateTime(d.year, d.month, d.day), values: latest),
      );
    }

    final colCount = 1 + snapshots.length;

    return Card(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cumulative Lab View',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                defaultColumnWidth: const FixedColumnWidth(92),
                columnWidths: const {0: FixedColumnWidth(140)},
                children: [
                  _headerRow(context, snapshots),
                  _dividerRow(
                    colCount,
                    scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  ...LabCatalog.groups.expand((g) sync* {
                    yield TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                          child: Text(
                            g.title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        for (int i = 0; i < snapshots.length; i++)
                          const SizedBox.shrink(),
                      ],
                    );

                    for (final t in g.tests) {
                      yield TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: Text(
                              t.key,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          ...snapshots.map((snap) {
                            final v = snap.values[t.key];
                            final text = v == null ? '-' : _fmt(v);

                            final r = LabCatalog.effectiveRange(
                              def: t,
                              gender: gender,
                              overrides: overrides,
                            );
                            final st = LabCatalog.evaluateWithRange(
                              range: r,
                              value: v,
                            );

                            final bg = _bgForStatus(st);
                            final fg = _fgForStatus(st, scheme);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 6,
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  text,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: fg,
                                      ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }

                    yield _spacerRow(colCount, 6);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TableRow _headerRow(BuildContext context, List<_DaySnapshot> snaps) {
    final scheme = Theme.of(context).colorScheme;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Text(
            'Lab Test',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        ...snaps.map((s) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Text(
              fmtDateCol(s.date),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurfaceVariant,
              ),
            ),
          );
        }),
      ],
    );
  }

  static TableRow _dividerRow(int colCount, Color c) => TableRow(
    children: List.generate(colCount, (_) => Container(height: 1, color: c)),
  );

  static TableRow _spacerRow(int colCount, double h) =>
      TableRow(children: List.generate(colCount, (_) => SizedBox(height: h)));

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String fmtDateCol(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  static String fmtDateShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmt(double v) {
    final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
    return s.replaceAll(RegExp(r'\.?0+$'), '');
  }

  static Color _bgForStatus(LabStatus s) {
    switch (s) {
      case LabStatus.normal:
        return Colors.green.withValues(alpha: 0.14);
      case LabStatus.warning:
        return Colors.amber.withValues(alpha: 0.18);
      case LabStatus.critical:
        return Colors.red.withValues(alpha: 0.18);
      case LabStatus.missing:
        return Colors.transparent;
    }
  }

  static Color _fgForStatus(LabStatus s, ColorScheme scheme) {
    switch (s) {
      case LabStatus.normal:
        return Colors.green.shade800;
      case LabStatus.warning:
        return Colors.amber.shade900;
      case LabStatus.critical:
        return Colors.red.shade800;
      case LabStatus.missing:
        return scheme.onSurfaceVariant;
    }
  }
}

class _DaySnapshot {
  final DateTime date;
  final Map<String, double> values;
  const _DaySnapshot({required this.date, required this.values});
}

class _CustomLabRow {
  String groupId;
  String name;
  String unit;
  String value;
  _CustomLabRow({required this.groupId}) : name = '', unit = '', value = '';
}

class AddLabEntryDialog extends StatefulWidget {
  const AddLabEntryDialog({
    super.key,
    required this.gender,
    required this.overrides,
  });

  final String gender;
  final Map<String, LabRange> overrides;

  @override
  State<AddLabEntryDialog> createState() => _AddLabEntryDialogState();
}

class _AddLabEntryDialogState extends State<AddLabEntryDialog> {
  DateTime _date = DateTime.now();
  late final Map<String, TextEditingController> _ctrls;
  final List<_CustomLabRow> _customLabs = [];

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final g in LabCatalog.groups)
        for (final t in g.tests) t.key: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String d(DateTime x) =>
        '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';

    final groups = LabCatalog.groups
        .map((g) => (id: slugGroupId(g.title), title: g.title))
        .toList();

    const customTitleStyle = TextStyle(fontWeight: FontWeight.w600);

    return AlertDialog(
      title: const Text('Add Lab Entry'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.date_range_outlined),
                label: Text('Date: ${d(_date)}'),
              ),
              const SizedBox(height: 12),
              ...LabCatalog.groups.map((g) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      ...g.tests.map((t) {
                        final eff = LabCatalog.effectiveRange(
                          def: t,
                          gender: widget.gender,
                          overrides: widget.overrides,
                        );
                        final rangeText = eff.normalText(unit: t.unit);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextField(
                            controller: _ctrls[t.key],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: t.label,
                              hintText: 'Numbers only',
                              helperText: rangeText == '—'
                                  ? null
                                  : 'Normal: $rangeText',
                              prefixIcon: const Icon(Icons.numbers),
                              suffixText: t.unit.isEmpty ? null : t.unit,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
              Text(
                'Tip: Leave empty fields blank; only filled results will be saved.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              // ---------- Custom Labs ----------
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Text('Custom labs', style: customTitleStyle),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _customLabs.add(
                            _CustomLabRow(
                              groupId: groups.isNotEmpty
                                  ? groups.first.id
                                  : 'other',
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add custom test'),
                    ),
                  ],
                ),
              ),

              ..._customLabs.asMap().entries.map((e) {
                final idx = e.key;
                final row = e.value;

                return Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: row.groupId,
                                items: [
                                  ...groups.map(
                                    (g) => DropdownMenuItem(
                                      value: g.id,
                                      child: Text(g.title),
                                    ),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'other',
                                    child: Text('Other'),
                                  ),
                                ],
                                onChanged: (v) => setState(
                                  () => row.groupId = v ?? row.groupId,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Group',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _customLabs.removeAt(idx)),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: row.name,
                                onChanged: (v) => row.name = v,
                                decoration: const InputDecoration(
                                  labelText: 'Test name',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: row.unit,
                                onChanged: (v) => row.unit = v,
                                decoration: const InputDecoration(
                                  labelText: 'Unit (optional)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: row.value,
                                onChanged: (v) => row.value = v,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Value',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final values = <String, double>{};

    for (final entry in _ctrls.entries) {
      final key = entry.key;
      final raw = entry.value.text.trim();
      if (raw.isEmpty) continue;

      final normalized = raw.replaceAll(',', '.');
      final v = double.tryParse(normalized);
      if (v == null) continue;

      values[key] = v;
    }

    for (final c in _customLabs) {
      final name = c.name.trim();
      final val = double.tryParse(c.value.trim());
      if (name.isEmpty || val == null) continue;

      final key = encodeCustomLabKey(
        groupId: c.groupId.trim().isEmpty ? 'other' : c.groupId.trim(),
        label: name,
        unit: c.unit.trim(),
      );
      values[key] = val;
    }

    if (values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one numeric value')),
      );
      return;
    }

    Navigator.pop(context, LabEntryUi(date: _date, values: values));
  }
}
