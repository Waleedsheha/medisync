import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/patients_providers.dart';
import '../data/patients_repository.dart';
import '../data/patient_details_providers.dart';
import '../models/patient_details_ui_models.dart';

class AddPatientScreen extends ConsumerStatefulWidget {
  const AddPatientScreen({
    super.key,
    required this.hospitalName,
    required this.unitName,
  });

  final String hospitalName;
  final String unitName;

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _mrnCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  String _gender = '';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mrnCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationText = [
      widget.hospitalName.trim(),
      widget.unitName.trim(),
    ].where((e) => e.isNotEmpty).join(' • ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Patient'),
        bottom: locationText.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(22),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    locationText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Patient name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mrnCtrl,
                      decoration: const InputDecoration(
                        labelText: 'MRN',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Age (optional)',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                            textInputAction: TextInputAction.next,
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
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hospital = widget.hospitalName.trim();
    final unit = widget.unitName.trim();
    if (hospital.isEmpty || unit.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing location (hospital/room). Please go back and open Add Patient from a room.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(patientsRepositoryProvider);

      final name = _nameCtrl.text.trim();
      final mrn = _mrnCtrl.text.trim();

      final key = PatientsRepository.makeKey(
        hospitalName: hospital,
        unitName: unit,
        mrn: mrn,
      );

      final record = PatientRecord(
        key: key,
        mrn: mrn,
        name: name,
        hospitalName: hospital,
        unitName: unit,
        phone: _phoneCtrl.text.trim(),
        age: _ageCtrl.text.trim(),
        gender: _gender.trim(),
      );

      await repo.upsert(record);

      final detailsRepo = ref.read(patientDetailsRepositoryProvider);

      final detailsKey = PatientsRepository.makeKey(
        hospitalName: hospital,
        unitName: unit,
        mrn: mrn,
      );

      await detailsRepo.upsertByKey(
        detailsKey,
        PatientDetailsUiModel(
          name: name,
          mrn: mrn,
          patientId: mrn,
          phone: _phoneCtrl.text.trim(),
          age: _ageCtrl.text.trim(),
          gender: _gender.trim(),
          admissionDate: '',
          dischargeDate: '',
          complaint: '',
          presentHistory: '',
          provisionalDiagnosis: const [],
          finalDiagnosis: const [],
          pastHistory: const [],
          hospitalCourse: const [],
          consultations: const [],
          plans: const [],
          meds: const [],
          discontinuedMeds: const [],
          radiologyStudies: const [],
          radiologyImages: const [],
          labs: const [],
          notes: const [],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
