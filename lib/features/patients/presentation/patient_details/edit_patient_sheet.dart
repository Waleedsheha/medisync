// lib/features/patients/presentation/patient_details/edit_patient_sheet.dart
import 'package:flutter/material.dart';

import '../../models/patient_details_ui_models.dart';

Future<void> showEditPatientSheet({
  required BuildContext context,
  required PatientDetailsUiModel initial,
  required void Function(PatientDetailsUiModel updated) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => EditPatientSheet(initial: initial, onSave: onSave),
  );
}

class EditPatientSheet extends StatefulWidget {
  const EditPatientSheet({
    super.key,
    required this.initial,
    required this.onSave,
  });

  final PatientDetailsUiModel initial;
  final void Function(PatientDetailsUiModel updated) onSave;

  @override
  State<EditPatientSheet> createState() => _EditPatientSheetState();
}

class _EditPatientSheetState extends State<EditPatientSheet> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _admissionDateCtrl;
  late final TextEditingController _dischargeDateCtrl;
  late final TextEditingController _complaintCtrl;
  late final TextEditingController _presentHistoryCtrl;
  late final TextEditingController _provisionalDiagnosisCtrl;
  late final TextEditingController _finalDiagnosisCtrl;
  late final TextEditingController _pastHistoryCtrl;
  late final TextEditingController _hospitalCourseCtrl;
  late final TextEditingController _consultationsCtrl;

  String _gender = '';

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.initial.phone);
    _ageCtrl = TextEditingController(text: widget.initial.age);
    _admissionDateCtrl = TextEditingController(
      text: widget.initial.admissionDate,
    );
    _dischargeDateCtrl = TextEditingController(
      text: widget.initial.dischargeDate,
    );
    _complaintCtrl = TextEditingController(text: widget.initial.complaint);
    _presentHistoryCtrl = TextEditingController(
      text: widget.initial.presentHistory,
    );
    _provisionalDiagnosisCtrl = TextEditingController(
      text: widget.initial.provisionalDiagnosis.join('\n'),
    );
    _finalDiagnosisCtrl = TextEditingController(
      text: widget.initial.finalDiagnosis.join('\n'),
    );
    _pastHistoryCtrl = TextEditingController(
      text: widget.initial.pastHistory.join('\n'),
    );
    _hospitalCourseCtrl = TextEditingController(
      text: widget.initial.hospitalCourse.join('\n'),
    );
    _consultationsCtrl = TextEditingController(
      text: widget.initial.consultations.join('\n'),
    );
    _gender = widget.initial.gender;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _admissionDateCtrl.dispose();
    _dischargeDateCtrl.dispose();
    _complaintCtrl.dispose();
    _presentHistoryCtrl.dispose();
    _provisionalDiagnosisCtrl.dispose();
    _finalDiagnosisCtrl.dispose();
    _pastHistoryCtrl.dispose();
    _hospitalCourseCtrl.dispose();
    _consultationsCtrl.dispose();
    super.dispose();
  }

  List<String> _parseList(String text) {
    return text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      ctrl.text = text;
    }
  }

  void _save() {
    final updated = PatientDetailsUiModel(
      name: widget.initial.name,
      mrn: widget.initial.mrn,
      patientId: widget.initial.patientId,
      phone: _phoneCtrl.text.trim(),
      age: _ageCtrl.text.trim(),
      gender: _gender,
      admissionDate: _admissionDateCtrl.text.trim(),
      dischargeDate: _dischargeDateCtrl.text.trim(),
      complaint: _complaintCtrl.text.trim(),
      presentHistory: _presentHistoryCtrl.text.trim(),
      provisionalDiagnosis: _parseList(_provisionalDiagnosisCtrl.text),
      finalDiagnosis: _parseList(_finalDiagnosisCtrl.text),
      pastHistory: _parseList(_pastHistoryCtrl.text),
      hospitalCourse: _parseList(_hospitalCourseCtrl.text),
      consultations: _parseList(_consultationsCtrl.text),
      plans: widget.initial.plans,
      meds: widget.initial.meds,
      discontinuedMeds: widget.initial.discontinuedMeds,
      radiologyStudies: widget.initial.radiologyStudies,
      radiologyImages: widget.initial.radiologyImages,
      labs: widget.initial.labs,
      notes: widget.initial.notes,
    );

    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Edit Medical Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _ageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _gender.isEmpty ? null : _gender,
                          items: const [
                            DropdownMenuItem(
                              value: 'Male',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'Female',
                              child: Text('Female'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _gender = v ?? ''),
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.wc_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _admissionDateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Admission Date',
                            prefixIcon: Icon(Icons.event_outlined),
                          ),
                          readOnly: true,
                          onTap: () => _pickDate(_admissionDateCtrl),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _dischargeDateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Discharge Date',
                            prefixIcon: Icon(Icons.event_busy_outlined),
                          ),
                          readOnly: true,
                          onTap: () => _pickDate(_dischargeDateCtrl),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _complaintCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Complaint',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _presentHistoryCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Present History',
                      prefixIcon: Icon(Icons.history),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _provisionalDiagnosisCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Provisional Diagnosis (one per line)',
                      prefixIcon: Icon(Icons.assignment_outlined),
                      helperText: 'Each line is a separate diagnosis',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _finalDiagnosisCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Final Diagnosis (one per line)',
                      prefixIcon: Icon(Icons.assignment_turned_in_outlined),
                      helperText: 'Each line is a separate diagnosis',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pastHistoryCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Past History (one per line)',
                      prefixIcon: Icon(Icons.fact_check_outlined),
                      helperText: 'Each line is a separate item',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hospitalCourseCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Hospital Course (one per line)',
                      prefixIcon: Icon(Icons.local_hospital_outlined),
                      helperText: 'Each line is a separate event',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _consultationsCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Consultations (one per line)',
                      prefixIcon: Icon(Icons.people_outlined),
                      helperText: 'Each line is a separate consultation',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
