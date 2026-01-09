import 'package:flutter/material.dart';

import '../../models/patient_details_ui_models.dart';
import 'shared_widgets.dart';

class MedsTab extends StatefulWidget {
  const MedsTab({
    super.key,
    required this.active,
    required this.discontinued,
    required this.onAdd,
    required this.onDiscontinue,
    required this.onDelete,
    required this.toast,
  });

  final List<MedicationUi> active;
  final List<MedicationUi> discontinued;

  final void Function(String name) onAdd;
  final void Function(MedicationUi m) onDiscontinue;
  final void Function(MedicationUi m) onDelete;

  final ToastFn toast;

  @override
  State<MedsTab> createState() => _MedsTabState();
}

class _MedsTabState extends State<MedsTab> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _d(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';

  void _add() {
    final med = _ctrl.text.trim();
    if (med.isEmpty) return;
    widget.onAdd(med);
    _ctrl.clear();
    widget.toast('OK');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Medications'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Add medication',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  onSubmitted: (_) => _add(),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Current'),
                const SizedBox(height: 10),
                if (widget.active.isEmpty)
                  Text('—', style: Theme.of(context).textTheme.bodyMedium)
                else
                  ...widget.active.map((m) {
                    final since = m.startDate != null ? ' (since ${_d(m.startDate!)})' : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(child: Text('• ${m.name}$since')),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'discontinue') widget.onDiscontinue(m);
                              if (v == 'delete') widget.onDelete(m);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'discontinue', child: Text('Discontinue')),
                              PopupMenuItem(value: 'delete', child: Text('Delete permanently')),
                            ],
                            child: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Discontinued'),
                const SizedBox(height: 10),
                if (widget.discontinued.isEmpty)
                  Text('—', style: Theme.of(context).textTheme.bodyMedium)
                else
                  ...widget.discontinued.map((m) {
                    final start = m.startDate != null ? _d(m.startDate!) : '';
                    final stop = m.stopDate != null ? _d(m.stopDate!) : '';
                    final range = (start.isNotEmpty || stop.isNotEmpty) ? ' ($start → $stop)' : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• ${m.name}$range'),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


