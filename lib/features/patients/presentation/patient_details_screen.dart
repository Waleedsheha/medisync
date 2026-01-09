// lib/features/patients/presentation/patient_details_screen.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/labs/lab_catalog.dart';
import '../models/patient_details_ui_models.dart';
import '../models/patient_nav_data.dart';

import '../data/lab_ranges_providers.dart';
import '../data/patient_details_providers.dart';
import '../data/facility_resolver.dart';

import '../../hierarchy/data/hierarchy_meta_repository.dart';
import '../../../core/utils/image_compression_manager.dart';

import 'lab_ranges_settings_screen.dart';

import 'patient_details/overview_tab.dart';
import 'patient_details/labs_tab.dart';
import 'patient_details/radiology_tab.dart';
import 'patient_details/meds_tab.dart';
import 'patient_details/notes_tab.dart';
import 'patient_details/report_tab.dart';
import 'patient_details/patient_report_pdf.dart' show buildReportPdfBytes;
import 'patient_details/edit_patient_sheet.dart';

/// internal (no UI) result
class _LogoPick {
  final Uint8List? bytes;
  final String? pickedKey;
  final String? pickedPath;
  const _LogoPick({
    required this.bytes,
    required this.pickedKey,
    required this.pickedPath,
  });
}

class PatientDetailsScreen extends ConsumerStatefulWidget {
  const PatientDetailsScreen({super.key, required this.data});

  final PatientNavData data;

  @override
  ConsumerState<PatientDetailsScreen> createState() =>
      _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends ConsumerState<PatientDetailsScreen> {
  final _hierMeta = HierarchyMetaRepository();
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final args = (
      patientName: widget.data.patientName,
      mrn: widget.data.mrn,
      hospitalName: widget.data.hospitalName,
      unitName: widget.data.unitName,
    );

    final patientAsync = ref.watch(patientDetailsControllerProvider(args));
    final overrides = ref.watch(
      labRangesForScopeProvider((
        hospitalName: widget.data.hospitalName,
        unitName: widget.data.unitName,
      )),
    );

    return patientAsync.when(
      data: (patient) => _buildContent(context, patient, args, overrides),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Patient Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('Patient Details')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PatientDetailsUiModel patient,
    PatientDetailsArgs args,
    Map<String, LabRange> overrides,
  ) {
    final ctrl = ref.read(patientDetailsControllerProvider(args).notifier);

    final locationText = [
      args.hospitalName.trim(),
      args.unitName.trim(),
    ].where((e) => e.isNotEmpty).join(' • ');

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient.name.isNotEmpty ? patient.name : 'Patient Details'),
              const SizedBox(height: 2),
              Text(
                'MRN: ${patient.mrn.isNotEmpty ? patient.mrn : '—'}'
                '${locationText.isNotEmpty ? '   •   $locationText' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Labs'),
              Tab(text: 'Radiology'),
              Tab(text: 'Meds'),
              Tab(text: 'Notes'),
              Tab(text: 'Report + QR + Print'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _openRangesSettings(context, patient, args),
              icon: const Icon(Icons.tune),
              tooltip: 'Ranges',
            ),
            IconButton(
              onPressed: () =>
                  _requestAddLabEntry(context, patient, ctrl, overrides),
              icon: const Icon(Icons.biotech),
              tooltip: 'Add Lab Entry',
            ),
            IconButton(
              onPressed: () => _pickRadiologyImages(context, args, ctrl),
              icon: const Icon(Icons.camera_alt_outlined),
              tooltip: 'Add Radiology',
            ),
            IconButton(
              onPressed: _shareReportPdf,
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share PDF',
            ),
            IconButton(
              onPressed: () => showPatientQrDialog(
                context: context,
                mrn: patient.mrn,
                toast: (msg) => _toast(context, msg),
              ),
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'QR',
            ),
            IconButton(
              onPressed: _printReportPdf,
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print',
            ),
            IconButton(
              onPressed: () => _openEditSheet(context, patient, args, ctrl),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: () => _toast(context, 'Archive'),
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archive',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ✅ PATCH: added callbacks needed by OverviewTab
            OverviewTab(
              patient: patient,
              hospitalName: args.hospitalName,
              unitName: args.unitName,
              onCall: () {
                if (patient.phone.trim().isEmpty) {
                  _toast(context, 'No phone');
                } else {
                  _toast(context, 'Call');
                }
              },
              onAddPlan: ctrl.addPlan,

              // ✅ NEW callbacks
              onAddProvisionalDiagnosis: ctrl.addProvisionalDiagnosisItem,
              onAddFinalDiagnosis: ctrl.addFinalDiagnosisItem,
              onAddPastHistory: ctrl.addPastHistoryItem,
              onAddHospitalCourse: ctrl.addHospitalCourseItem,
              onAddConsultation: ctrl.addConsultationItem,

              onEditComplaint: ctrl.updateComplaint,
              onEditPresentHistory: ctrl.updatePresentHistory,

              toast: (msg) => _toast(context, msg),
            ),

            LabsTab(
              entries: patient.labs,
              gender: patient.gender,
              overrides: overrides,
              onRequestAddEntry: () =>
                  _requestAddLabEntry(context, patient, ctrl, overrides),
              onDeleteEntry: ctrl.deleteLabEntry,
            ),

            RadiologyTab(
              studies: patient.radiologyStudies,
              images: patient.radiologyImages,
              onPickImage: () => _pickRadiologyImages(context, args, ctrl),
              onAddStudy: ctrl.addRadiologyStudy,
              onRemoveStudy: ctrl.removeRadiologyStudy,
              onRemoveImage: (i) => ctrl.removeRadiologyImageAt(i),
              toast: (msg) => _toast(context, msg),
            ),

            MedsTab(
              active: patient.meds,
              discontinued: patient.discontinuedMeds,
              onAdd: (name) => ctrl.addMedication(
                MedicationUi(name: name, startDate: DateTime.now()),
              ),
              onDiscontinue: ctrl.discontinueMedication,
              onDelete: ctrl.deleteMedication,
              toast: (msg) => _toast(context, msg),
            ),

            NotesTab(
              notes: patient.notes,
              onAdd: (text) =>
                  ctrl.addNote(NoteUi(text: text, createdAt: DateTime.now())),
              onDelete: ctrl.deleteNote,
              toast: (msg) => _toast(context, msg),
            ),

            ReportTab(
              mrn: patient.mrn,
              onPdf: _printReportPdf,
              onPrint: _printReportPdf,
              onShare: _shareReportPdf,
              toast: (msg) => _toast(context, msg),
            ),
          ],
        ),
      ),
    );
  }

  // ================== helpers ==================
  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 850)),
    );
  }

  void _openRangesSettings(
    BuildContext context,
    PatientDetailsUiModel patient,
    PatientDetailsArgs args,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LabRangesSettingsScreen(
          hospitalName: args.hospitalName,
          unitName: args.unitName,
          title: 'Lab Ranges • ${args.hospitalName} • ${args.unitName}',
          gender: patient.gender,
        ),
      ),
    );
  }

  // ================== labs ==================
  Future<void> _requestAddLabEntry(
    BuildContext context,
    PatientDetailsUiModel patient,
    PatientDetailsController ctrl,
    Map<String, LabRange> overrides,
  ) async {
    final entry = await showAddLabEntryDialog(
      context: context,
      gender: patient.gender,
      overrides: overrides,
    );
    if (entry == null) return;

    ctrl.addLabEntry(entry);

    final critical = criticalFindings(
      entry: entry,
      gender: patient.gender,
      overrides: overrides,
    );
    if (context.mounted) {
      if (critical.isNotEmpty) {
        showCriticalLabDialog(context, critical, entry.date);
      } else {
        _toast(context, 'Lab entry saved');
      }
    }
  }

  // ================== Edit ==================
  void _openEditSheet(
    BuildContext context,
    PatientDetailsUiModel patient,
    PatientDetailsArgs args,
    PatientDetailsController ctrl,
  ) {
    showEditPatientSheet(
      context: context,
      initial: patient,
      onSave: (updated) {
        ctrl.updateAll(updated);
        _toast(context, 'Saved');
      },
    );
  }

  // ================== Radiology ==================
  Future<void> _pickRadiologyImages(
    BuildContext context,
    PatientDetailsArgs args,
    PatientDetailsController ctrl,
  ) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    final paths =
        res?.files.map((f) => f.path).whereType<String>().toList() ?? [];
    if (paths.isEmpty) return;

    if (context.mounted) {
      _toast(context, 'Compressing ${paths.length} images...');
    }

    final compressedPaths = <String>[];
    for (final p in paths) {
      final compressed = await ImageCompressionManager().compressImage(p);
      if (compressed != null) {
        compressedPaths.add(compressed.path);
      } else {
        // Fallback to original if compression fails
        compressedPaths.add(p);
      }
    }

    final stored = await _uploadRadiologyImagesBestEffort(
      args: args,
      localPaths: compressedPaths,
    );

    ctrl.addRadiologyImages(stored);

    if (context.mounted) {
      _toast(context, 'Images added & compressed');
    }
  }

  bool _isStorageRef(String value) => value.trim().startsWith('sb:');

  Future<List<String>> _uploadRadiologyImagesBestEffort({
    required PatientDetailsArgs args,
    required List<String> localPaths,
  }) async {
    if (kIsWeb) return localPaths;
    if (localPaths.isEmpty) return const [];

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return localPaths;

    const bucket = 'patient-radiology';

    // Shared model: put hospital_id in the object path so Storage RLS can enforce membership.
    final resolver = FacilityResolver(client);
    var hospitalId = await resolver.findHospitalIdByName(
      args.hospitalName.trim(),
    );
    hospitalId ??= await resolver.getOrCreateHospitalId(
      ownerId: user.id,
      hospitalName: args.hospitalName,
    );

    final mrnFolder = _hierMeta.normalizeId(args.mrn);

    final out = <String>[];

    for (final rawPath in localPaths) {
      final fp = rawPath.trim();
      if (fp.isEmpty) continue;
      if (_isStorageRef(fp)) {
        out.add(fp);
        continue;
      }

      try {
        final f = File(fp);
        if (!await f.exists()) {
          out.add(fp);
          continue;
        }

        final bytes = await f.readAsBytes();
        if (bytes.isEmpty) {
          out.add(fp);
          continue;
        }

        final ext = p.extension(fp).toLowerCase();
        final safeExt = (ext == '.png' || ext == '.jpg' || ext == '.jpeg')
            ? ext
            : '.jpg';
        final objectPath =
            'radiology/$hospitalId/$mrnFolder/${_uuid.v4()}$safeExt';

        String? contentType;
        if (safeExt == '.png') contentType = 'image/png';
        if (safeExt == '.jpg' || safeExt == '.jpeg') contentType = 'image/jpeg';

        await client.storage
            .from(bucket)
            .uploadBinary(
              objectPath,
              bytes,
              fileOptions: FileOptions(upsert: false, contentType: contentType),
            );

        out.add('sb:$bucket:$objectPath');
      } catch (_) {
        // If anything fails (offline / bucket missing), keep local path for now.
        out.add(fp);
      }
    }

    return out;
  }

  // ================== PDF Report ==================
  PatientDetailsUiModel? _readCurrentPatientOrNull() {
    final patientAsync = ref.read(
      patientDetailsControllerProvider((
        patientName: widget.data.patientName,
        mrn: widget.data.mrn,
        hospitalName: widget.data.hospitalName,
        unitName: widget.data.unitName,
      )),
    );
    return patientAsync.value;
  }

  // 1) try direct candidates
  Future<Uint8List?> _tryLoadLogoByCandidates() async {
    const scope = 'hospitals';
    final rawName = widget.data.hospitalName;

    final candidates = <String>{
      _hierMeta.normalizeId(rawName),
      rawName.trim(),
      rawName.trim().toLowerCase(),
      rawName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
    }.where((e) => e.trim().isNotEmpty).toList();

    for (final id in candidates) {
      final path = await _hierMeta.getLogoPath(scope: scope, id: id);
      final bytes = await _hierMeta.loadLogoBytesFromPath(path);
      if (bytes != null && bytes.isNotEmpty) return bytes;
    }
    return null;
  }

  // 2) fallback: scan Hive and pick best match (NO UI debug)
  Future<_LogoPick> _scanAndPickLogoBestEffort() async {
    const boxName = 'hierarchy_meta_v1';
    final b = Hive.isBoxOpen(boxName)
        ? Hive.box<String>(boxName)
        : await Hive.openBox<String>(boxName);

    final hospitalRaw = widget.data.hospitalName.trim();
    final hospitalNorm = _hierMeta.normalizeId(hospitalRaw);
    final hospitalLower = hospitalRaw.toLowerCase();
    final hospitalUnderscore = hospitalLower.replaceAll(RegExp(r'\s+'), '_');

    int scoreKey(String fullKey) {
      final parts = fullKey.split(':');
      final scope = parts.isNotEmpty ? parts[0] : '';
      final id = parts.length >= 2 ? parts[1] : '';

      var score = 0;
      if (scope == 'hospitals') {
        score += 200;
      }

      if (id == hospitalNorm) {
        score += 400;
      }
      if (id == hospitalLower) {
        score += 350;
      }
      if (id == hospitalUnderscore) {
        score += 340;
      }

      if (id.contains(hospitalNorm) || hospitalNorm.contains(id)) {
        score += 220;
      }
      if (id.contains(hospitalUnderscore) || hospitalUnderscore.contains(id)) {
        score += 200;
      }
      if (id.contains(hospitalLower) || hospitalLower.contains(id)) {
        score += 170;
      }

      score -= id.length;
      return score;
    }

    String? bestKey;
    int bestScore = -999999;
    String? bestPath;

    final hospitalsLogoKeys = <String>[];

    for (final k in b.keys) {
      if (k is! String) continue;
      if (!k.endsWith(':logoPath')) continue;

      final path = (b.get(k) ?? '').trim();
      if (path.isEmpty) continue;

      if (k.startsWith('hospitals:')) hospitalsLogoKeys.add(k);

      final s = scoreKey(k);
      if (s > bestScore) {
        bestScore = s;
        bestKey = k;
        bestPath = path;
      }
    }

    if (bestPath == null && hospitalsLogoKeys.length == 1) {
      final onlyKey = hospitalsLogoKeys.first;
      final onlyPath = (b.get(onlyKey) ?? '').trim();
      if (onlyPath.isNotEmpty) {
        final bytes = await _hierMeta.loadLogoBytesFromPath(onlyPath);
        return _LogoPick(
          bytes: (bytes?.isNotEmpty ?? false) ? bytes : null,
          pickedKey: onlyKey,
          pickedPath: onlyPath,
        );
      }
    }

    if (bestPath == null) {
      return const _LogoPick(bytes: null, pickedKey: null, pickedPath: null);
    }

    final bytes = await _hierMeta.loadLogoBytesFromPath(bestPath);
    return _LogoPick(
      bytes: (bytes != null && bytes.isNotEmpty) ? bytes : null,
      pickedKey: bestKey,
      pickedPath: bestPath,
    );
  }

  Future<Uint8List?> _loadHospitalLogoBytesBestEffort() async {
    final direct = await _tryLoadLogoByCandidates();
    if (direct != null && direct.isNotEmpty) return direct;

    final pick = await _scanAndPickLogoBestEffort();
    if (kDebugMode) {
      debugPrint(
        'PDF LOGO PICK: key=${pick.pickedKey} path=${pick.pickedPath} bytes=${pick.bytes?.length}',
      );
    }
    return pick.bytes;
  }

  Future<void> _printReportPdf() async {
    try {
      final patient = _readCurrentPatientOrNull();
      if (patient == null) {
        if (context.mounted) _toast(context, 'Patient data not ready yet');
        return;
      }

      final bytes = await _buildReportPdfBytes(patient);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) _toast(context, 'Print failed: $e');
    }
  }

  Future<void> _shareReportPdf() async {
    try {
      final patient = _readCurrentPatientOrNull();
      if (patient == null) {
        if (context.mounted) _toast(context, 'Patient data not ready yet');
        return;
      }

      final bytes = await _buildReportPdfBytes(patient);
      final safeMrn = patient.mrn.trim().isNotEmpty
          ? patient.mrn.trim()
          : 'patient';
      await Printing.sharePdf(bytes: bytes, filename: 'patient_$safeMrn.pdf');
    } catch (e) {
      if (mounted) _toast(context, 'Share failed: $e');
    }
  }

  Future<Uint8List> _buildReportPdfBytes(PatientDetailsUiModel patient) async {
    final logoBytes = await _loadHospitalLogoBytesBestEffort();

    return buildReportPdfBytes(
      patient: patient,
      hospitalName: widget.data.hospitalName,
      unitName: widget.data.unitName,
      headerLogoBytes: logoBytes,
    );
  }
}
