//lib/features/patients/presentation/patient_details/overview_tab.dart
import 'package:flutter/material.dart';

import '../../models/patient_details_ui_models.dart';
import 'shared_widgets.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.patient,
    required this.hospitalName,
    required this.unitName,
    required this.onCall,
    required this.onAddPlan,
    required this.onAddProvisionalDiagnosis,
    required this.onAddFinalDiagnosis,
    required this.onAddPastHistory,
    required this.onAddHospitalCourse,
    required this.onAddConsultation,
    required this.onEditComplaint,
    required this.onEditPresentHistory,
    required this.toast,
  });

  final PatientDetailsUiModel patient;
  final String hospitalName;
  final String unitName;

  final VoidCallback onCall;
  final void Function(PlanUi plan) onAddPlan;

  // ✅ new callbacks for "Add" buttons
  final void Function(String text) onAddProvisionalDiagnosis;
  final void Function(String text) onAddFinalDiagnosis;
  final void Function(String text) onAddPastHistory;
  final void Function(String text)
  onAddHospitalCourse; // timestamp handled in controller
  final void Function(String text) onAddConsultation;

  final void Function(String text) onEditComplaint;
  final void Function(String text) onEditPresentHistory;

  final ToastFn toast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final sortedPlans = [...patient.plans]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final locationText = [
      hospitalName.trim(),
      unitName.trim(),
    ].where((e) => e.isNotEmpty).join(' • ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer.withValues(alpha: 0.9),
                scheme.surfaceContainer,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primary.withValues(alpha: 0.14),
                child: Text(
                  patient.name.isNotEmpty
                      ? patient.name.trim()[0].toUpperCase()
                      : 'P',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name.isNotEmpty ? patient.name : 'Patient',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('MRN: ${patient.mrn.isNotEmpty ? patient.mrn : '—'}'),
                    if (locationText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        locationText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Patient info'),
                const SizedBox(height: 10),
                InfoRow(label: 'ID', value: patient.patientId),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InfoRow(label: 'Age', value: patient.age),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoRow(label: 'Gender', value: patient.gender),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        patient.phone.isNotEmpty ? patient.phone : '—',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(onPressed: onCall, child: const Text('Call')),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InfoRow(
                        label: 'Admission',
                        value: patient.admissionDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoRow(
                        label: 'Discharge',
                        value: patient.dischargeDate,
                      ),
                    ),
                  ],
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
                _SectionHeader(
                  title: 'Complaint',
                  onAction: () async {
                    final text = await _promptAddText(
                      context,
                      title: 'Edit Complaint',
                      initialValue: patient.complaint,
                      actionLabel: 'Save',
                    );
                    if (text == null) return;
                    onEditComplaint(text);
                    toast('Saved');
                  },
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                ),
                const SizedBox(height: 8),
                Text(
                  patient.complaint.trim().isNotEmpty ? patient.complaint : '—',
                ),
                const SizedBox(height: 12),
                _SectionHeader(
                  title: 'Present History',
                  onAction: () async {
                    final text = await _promptAddText(
                      context,
                      title: 'Edit Present History',
                      initialValue: patient.presentHistory,
                      actionLabel: 'Save',
                    );
                    if (text == null) return;
                    onEditPresentHistory(text);
                    toast('Saved');
                  },
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                ),
                const SizedBox(height: 8),
                Text(
                  patient.presentHistory.trim().isNotEmpty
                      ? patient.presentHistory
                      : '—',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ✅ Diagnosis: add buttons like Plans
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Diagnosis'),
                const SizedBox(height: 10),

                _ListSectionWithAdd(
                  title: 'Provisional',
                  items: patient.provisionalDiagnosis,
                  onAdd: () async {
                    final text = await _promptAddText(
                      context,
                      title: 'Add Provisional diagnosis',
                    );
                    if (text == null) return;
                    onAddProvisionalDiagnosis(text);
                    toast('Saved');
                  },
                ),

                const SizedBox(height: 10),

                _ListSectionWithAdd(
                  title: 'Final',
                  items: patient.finalDiagnosis,
                  onAdd: () async {
                    final text = await _promptAddText(
                      context,
                      title: 'Add Final diagnosis',
                    );
                    if (text == null) return;
                    onAddFinalDiagnosis(text);
                    toast('Saved');
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ✅ History & Course: add buttons like Plans
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('History & Course'),
                const SizedBox(height: 10),

                _ListSectionWithAdd(
                  title: 'Past history',
                  items: patient.pastHistory,
                  onAdd: () async {
                    final text = await _promptAddText(
                      context,
                      title: 'Add Past history',
                    );
                    if (text == null) return;
                    onAddPastHistory(text);
                    toast('Saved');
                  },
                ),

                const SizedBox(height: 10),

                _ListSectionWithAdd(
                  title: 'Hospital course',
                  items: patient.hospitalCourse,
                  onAdd: () async {
                    final text = await _promptAddText(
                      context,
                      title: 'Add Hospital course',
                    );
                    if (text == null) return;
                    // ✅ timestamp is added inside controller
                    onAddHospitalCourse(text);
                    toast('Saved');
                  },
                ),

                const SizedBox(height: 10),

                _ListSectionWithAdd(
                  title: 'Consultations',
                  items: patient.consultations,
                  onAdd: () async {
                    final text = await _promptAddText(
                      context,
                      title: 'Add Consultation',
                    );
                    if (text == null) return;
                    onAddConsultation(text);
                    toast('Saved');
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Plans (as-is)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SectionTitle('Plans'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showAddPlanSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (sortedPlans.isEmpty)
                  Text('—', style: Theme.of(context).textTheme.bodyMedium)
                else
                  ...sortedPlans.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• ${p.title}${p.whenText.isNotEmpty ? ' — ${p.whenText}' : ''}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= dialogs/helpers =================

  Future<String?> _promptAddText(
    BuildContext context, {
    required String title,
    String? initialValue,
    String actionLabel = 'Add',
  }) async {
    final c = TextEditingController(text: initialValue);

    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: c,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Write here...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(ctx).unfocus();
                Navigator.of(ctx, rootNavigator: true).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final v = c.text.trim();
                FocusScope.of(ctx).unfocus();
                Navigator.of(
                  ctx,
                  rootNavigator: true,
                ).pop(v.isEmpty ? null : v);
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );

    c.dispose();
    return res;
  }

  void _showAddPlanSheet(BuildContext context) {
    final title = TextEditingController();
    DateTime date = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final bottom = MediaQuery.of(sheetCtx).viewInsets.bottom;
            String dateText(DateTime d) =>
                '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Add Plan',
                        style: Theme.of(sheetCtx).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          FocusScope.of(sheetCtx).unfocus();
                          Navigator.of(sheetCtx, rootNavigator: true).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Plan title',
                      prefixIcon: Icon(Icons.task_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: sheetCtx,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && sheetCtx.mounted) {
                        setSheetState(() {
                          date = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(dateText(date)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      final t = title.text.trim();
                      if (t.isEmpty) return;
                      onAddPlan(PlanUi(title: t, scheduledAt: date));
                      FocusScope.of(sheetCtx).unfocus();
                      Navigator.of(sheetCtx, rootNavigator: true).pop();
                      toast('Saved');
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => title.dispose());
  }
}

class _ListSectionWithAdd extends StatelessWidget {
  const _ListSectionWithAdd({
    required this.title,
    required this.items,
    required this.onAdd,
  });

  final String title;
  final List<String> items;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = items.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionTitle(title),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (t.isEmpty)
          Text('—', style: Theme.of(context).textTheme.bodyMedium)
        else
          ...t.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $e'),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onAction,
    required this.icon,
    required this.label,
  });

  final String title;
  final VoidCallback onAction;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SectionTitle(title),
        const Spacer(),
        // Visual density compact to keep it aligned nicely
        TextButton.icon(
          onPressed: onAction,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }
}
