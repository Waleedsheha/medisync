// lib/features/patients/presentation/patient_details/patient_report_pdf.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/patient_details_ui_models.dart';
import '../../models/labs/lab_catalog.dart';

// ✅ AUTO-LOAD header logo from Hive (unit -> hospital) when headerLogoBytes is null
import '../../../hierarchy/data/hierarchy_meta_repository.dart';

/// Clean PDF builder (Kotlin-like order)
/// - Header: optional logo (left) + centered "Medical Report" + QR (right)
/// - Patient name/location shown ONLY inside the info card
/// - Uses ASCII-safe replacements for symbols that Helvetica can't render.
class PatientReportPdf {
  static Future<Uint8List> build({
    required PatientDetailsUiModel patient,
    required String hospitalName,
    required String unitName,
    Uint8List? headerLogoBytes,
    String? qrData,
  }) async {
    final doc = pw.Document();

    final locationText = _compact([hospitalName, unitName]).join(' • ');

    // QR payload fallback (must never be empty)
    final safeQr = (qrData ?? '').trim().isNotEmpty
        ? (qrData ?? '').trim()
        : (patient.mrn.trim().isNotEmpty ? patient.mrn.trim() : 'PATIENT');

    // Load radiology images (file paths).
    final radiologyImages = await _loadImages(patient.radiologyImages);

    // ✅ Resolve header logo bytes HERE (this file is the PDF builder)
    final resolvedHeaderLogoBytes =
        headerLogoBytes ??
        await _resolveHeaderLogoBytes(
          hospitalName: hospitalName,
          unitName: unitName,
        );

    final baseTheme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    final portraitTheme = pw.PageTheme(
      theme: baseTheme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 34),
    );

    final landscapeTheme = pw.PageTheme(
      theme: baseTheme,
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 28),
    );

    // ===================== 1) TEXT REPORT (portrait) =====================
    doc.addPage(
      pw.MultiPage(
        pageTheme: portraitTheme,
        build: (ctx) => [
          _topHeader(
            title: 'Medical Report',
            headerLogoBytes: resolvedHeaderLogoBytes,
            qrData: safeQr,
          ),
          pw.SizedBox(height: 12),

          // Patient name/location ONLY inside card
          _patientInfoCard(patient: patient, locationText: locationText),
          pw.SizedBox(height: 10),

          // Complaint / Present history / Diagnoses / History / Course / Consultations
          ..._sectionIfText('Complaint', patient.complaint),
          ..._sectionIfText(
            'Present History',
            patient.presentHistory,
            after: pw.Text(
              _asciiSafe(
                'Laboratory and radiology documents are attached below.',
              ),
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),

          ..._sectionIfList(
            'Provisional Diagnosis',
            patient.provisionalDiagnosis,
          ),
          ..._sectionIfList('Final Diagnosis', patient.finalDiagnosis),

          ..._sectionIfList(
            'Past History',
            patient.pastHistory,
            topDivider: true,
          ),
          ..._sectionIfList('Hospital Course', patient.hospitalCourse),
          ..._sectionIfList('Consultations', patient.consultations),

          // Plans
          ..._plansSection(patient.plans),

          // Medications
          ..._medicationsSection(patient.meds, patient.discontinuedMeds),

          // Radiology (studies list)
          ..._radiologySection(
            patient.radiologyStudies,
            radiologyImages.length,
          ),

          // Notes (optional)
          ..._notesSection(patient.notes),
        ],
      ),
    );

    // ===================== 2) Radiology image attachments (portrait) =====================
    if (radiologyImages.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageTheme: portraitTheme,
          build: (ctx) => [
            _simpleTitle('Radiology Attachments'),
            pw.SizedBox(height: 10),
            ...radiologyImages.asMap().entries.map((e) {
              final i = e.key + 1;
              final img = e.value;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Text(
                      _asciiSafe('Image $i'),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.ClipRRect(
                    horizontalRadius: 10,
                    verticalRadius: 10,
                    child: pw.Image(img, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(height: 14),
                ],
              );
            }),
          ],
        ),
      );
    }

    // ===================== 3) Labs table (landscape) =====================
    if (patient.labs.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageTheme: landscapeTheme,
          build: (ctx) => [
            _simpleTitle('Labs (Cumulative View)'),
            pw.SizedBox(height: 10),
            _labsCumulativeTable(patient.labs, patient.gender),
          ],
        ),
      );
    }

    return doc.save();
  }
}

/// Backward-compatible wrappers
Future<Uint8List> buildPatientReportPdfBytes({
  required PatientDetailsUiModel patient,
  required String hospitalName,
  required String unitName,
  Uint8List? headerLogoBytes,
  String? qrData,
}) {
  return PatientReportPdf.build(
    patient: patient,
    hospitalName: hospitalName,
    unitName: unitName,
    headerLogoBytes: headerLogoBytes,
    qrData: qrData,
  );
}

Future<Uint8List> buildReportPdfBytes({
  required PatientDetailsUiModel patient,
  required String hospitalName,
  required String unitName,
  Uint8List? headerLogoBytes,
  String? qrData,
}) {
  return buildPatientReportPdfBytes(
    patient: patient,
    hospitalName: hospitalName,
    unitName: unitName,
    headerLogoBytes: headerLogoBytes,
    qrData: qrData,
  );
}

// ========================= UI helpers =========================

pw.Widget _topHeader({
  required String title,
  required Uint8List? headerLogoBytes,
  required String qrData,
}) {
  final logo = headerLogoBytes != null ? pw.MemoryImage(headerLogoBytes) : null;

  const sideBox = 46.0;

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(14),
      color: PdfColors.grey100,
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Left: logo (or spacer)
        pw.SizedBox(
          width: sideBox,
          height: sideBox,
          child: logo == null
              ? pw.SizedBox.shrink()
              : pw.ClipRRect(
                  horizontalRadius: 10,
                  verticalRadius: 10,
                  child: pw.Image(logo, fit: pw.BoxFit.cover),
                ),
        ),

        pw.Expanded(
          child: pw.Center(
            child: pw.Text(
              _asciiSafe(title),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),

        // Right: QR
        pw.SizedBox(
          width: sideBox,
          height: sideBox,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(3),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.BarcodeWidget(
              data: qrData.trim().isNotEmpty ? qrData.trim() : 'PATIENT',
              barcode: pw.Barcode.qrCode(),
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _patientInfoCard({
  required PatientDetailsUiModel patient,
  required String locationText,
}) {
  final items = <_KV>[
    _KV('MRN', patient.mrn),
    _KV('ID', patient.patientId),
    _KV('Phone', patient.phone),
    _KV('Age', patient.age),
    _KV('Gender', patient.gender),
    _KV('Date of Admission', patient.admissionDate),
    _KV('Date of Discharge', patient.dischargeDate),
    _KV('Location', locationText),
  ].where((x) => _clean(x.value).isNotEmpty).toList();

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(14),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _asciiSafe(
            _clean(patient.name).isNotEmpty ? _clean(patient.name) : 'Patient',
          ),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),

        if (items.isEmpty)
          pw.SizedBox.shrink()
        else
          pw.Wrap(
            spacing: 14,
            runSpacing: 10,
            children: items.map((kv) {
              return pw.Container(
                width: 240,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _asciiSafe(kv.label),
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _asciiSafe(_clean(kv.value)),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    ),
  );
}

pw.Widget _simpleTitle(String text) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Text(
      _asciiSafe(text),
      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
    ),
  );
}

List<pw.Widget> _sectionIfText(
  String title,
  String text, {
  pw.Widget? after,
  bool topDivider = false,
}) {
  final v = _clean(text);
  if (v.isEmpty) return const [];

  return [
    if (topDivider) ...[
      pw.SizedBox(height: 10),
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 8),
    ] else
      pw.SizedBox(height: 10),
    _sectionTitle(title),
    pw.SizedBox(height: 6),
    pw.Text(_asciiSafe(v), style: const pw.TextStyle(fontSize: 11)),
    if (after != null) ...[pw.SizedBox(height: 6), after],
  ];
}

List<pw.Widget> _sectionIfList(
  String title,
  List<String> items, {
  bool topDivider = false,
}) {
  final data = items.map(_clean).where((e) => e.isNotEmpty).toList();
  if (data.isEmpty) return const [];

  return [
    if (topDivider) ...[
      pw.SizedBox(height: 10),
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 8),
    ] else
      pw.SizedBox(height: 10),
    _sectionTitle(title),
    pw.SizedBox(height: 6),
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: data
          .map(
            (e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Bullet(
                text: _asciiSafe(e),
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          )
          .toList(),
    ),
  ];
}

pw.Widget _sectionTitle(String title) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Text(
      _asciiSafe(title),
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
  );
}

List<pw.Widget> _plansSection(List<PlanUi> plans) {
  if (plans.isEmpty) return const [];

  final sorted = [...plans]
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  return [
    pw.SizedBox(height: 10),
    pw.Divider(color: PdfColors.grey300),
    pw.SizedBox(height: 8),
    _sectionTitle('Plans'),
    pw.SizedBox(height: 6),
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: sorted.map((p) {
        final when = _fmtDateTime(p.scheduledAt);
        final line = when.isNotEmpty ? '${p.title} - $when' : p.title;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Bullet(
            text: _asciiSafe(_clean(line)),
            style: const pw.TextStyle(fontSize: 11),
          ),
        );
      }).toList(),
    ),
  ];
}

List<pw.Widget> _medicationsSection(
  List<MedicationUi> active,
  List<MedicationUi> discontinued,
) {
  final a = [...active];
  final d = [...discontinued];

  if (a.isEmpty && d.isEmpty) return const [];

  return [
    pw.SizedBox(height: 10),
    pw.Divider(color: PdfColors.grey300),
    pw.SizedBox(height: 8),
    _sectionTitle('Medications'),
    pw.SizedBox(height: 6),

    if (a.isNotEmpty) ...[
      pw.Text(
        'Current',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: a.map((m) {
          final since = m.startDate != null
              ? ' (since ${_fmtDate(m.startDate!)})'
              : '';
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Bullet(
              text: _asciiSafe('${_clean(m.name)}$since'),
              style: const pw.TextStyle(fontSize: 11),
            ),
          );
        }).toList(),
      ),
      pw.SizedBox(height: 8),
    ],

    if (d.isNotEmpty) ...[
      pw.Text(
        'Discontinued',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: d.map((m) {
          final start = m.startDate != null ? _fmtDate(m.startDate!) : '';
          final stop = m.stopDate != null ? _fmtDate(m.stopDate!) : '';
          final range = (start.isNotEmpty || stop.isNotEmpty)
              ? ' ($start -> $stop)'
              : '';
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Bullet(
              text: _asciiSafe('${_clean(m.name)}$range'),
              style: const pw.TextStyle(fontSize: 11),
            ),
          );
        }).toList(),
      ),
    ],
  ];
}

List<pw.Widget> _radiologySection(
  List<RadiologyStudyUi> studies,
  int imagesCount,
) {
  if (studies.isEmpty && imagesCount == 0) return const [];

  return [
    pw.SizedBox(height: 10),
    pw.Divider(color: PdfColors.grey300),
    pw.SizedBox(height: 8),
    _sectionTitle('Radiology'),
    pw.SizedBox(height: 6),

    if (imagesCount > 0)
      pw.Text(
        _asciiSafe('Images are attached below. Images: $imagesCount'),
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),

    if (studies.isNotEmpty) ...[
      pw.SizedBox(height: 6),
      pw.Text(
        'Radiology studies:',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: studies.map((s) {
          final dt = _fmtDate(s.date);
          final line = dt.isNotEmpty
              ? '${_clean(s.title)} ($dt)'
              : _clean(s.title);
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Bullet(
              text: _asciiSafe(line),
              style: const pw.TextStyle(fontSize: 11),
            ),
          );
        }).toList(),
      ),
    ],
  ];
}

List<pw.Widget> _notesSection(List<NoteUi> notes) {
  final data = notes.where((n) => _clean(n.text).isNotEmpty).toList();
  if (data.isEmpty) return const [];

  return [
    pw.SizedBox(height: 10),
    pw.Divider(color: PdfColors.grey300),
    pw.SizedBox(height: 8),
    _sectionTitle('Notes'),
    pw.SizedBox(height: 6),
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: data.map((n) {
        final when = _fmtDateTime(n.createdAt);
        final line = when.isNotEmpty
            ? '${_clean(n.text)} - $when'
            : _clean(n.text);
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Bullet(
            text: _asciiSafe(line),
            style: const pw.TextStyle(fontSize: 11),
          ),
        );
      }).toList(),
    ),
  ];
}

// ========================= Labs (landscape) =========================

pw.Widget _labsCumulativeTable(List<LabEntryUi> entries, String gender) {
  final dayMap = <String, List<LabEntryUi>>{};
  for (final e in entries) {
    final k = _dayKey(e.date);
    dayMap.putIfAbsent(k, () => []).add(e);
  }

  final keys = dayMap.keys.toList()..sort();
  final snaps = <_DaySnap>[];

  for (final k in keys) {
    final list = [...dayMap[k]!]..sort((a, b) => a.date.compareTo(b.date));
    final latest = <String, double>{};
    for (final entry in list) {
      entry.values.forEach((labKey, v) => latest[labKey] = v);
    }
    final d = list.last.date;
    snaps.add(_DaySnap(date: DateTime(d.year, d.month, d.day), values: latest));
  }

  if (snaps.isEmpty) return pw.Text('No lab results available.');

  bool anyValueForKey(String key) =>
      snaps.any((s) => s.values.containsKey(key));

  final rows = <pw.TableRow>[];

  rows.add(
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _cell('Lab Test', isHeader: true, align: pw.Alignment.centerLeft),
        ...snaps.map((s) => _cell(_fmtDateCol(s.date), isHeader: true)),
      ],
    ),
  );

  rows.add(
    pw.TableRow(
      children: List.generate(
        1 + snaps.length,
        (_) => pw.Container(height: 1, color: PdfColors.grey300),
      ),
    ),
  );

  // Collect custom lab keys (encoded) found in snapshots, grouped by groupId.
  final customKeysByGroupId = <String, List<String>>{};
  for (final snap in snaps) {
    for (final key in snap.values.keys) {
      if (!isCustomLabKey(key)) continue;
      final parsed = parseCustomLabKey(key);
      if (parsed == null) continue;

      final list = customKeysByGroupId.putIfAbsent(
        parsed.groupId,
        () => <String>[],
      );
      if (!list.contains(key)) list.add(key);
    }
  }

  for (final g in LabCatalog.groups) {
    final groupId = slugGroupId(g.title);
    final customKeys = customKeysByGroupId[groupId] ?? const <String>[];
    final hasAnyBuiltIn = g.tests.any((t) => anyValueForKey(t.key));
    final hasAnyCustom = customKeys.any((k) => anyValueForKey(k));

    // Skip whole group if nothing has values
    if (!hasAnyBuiltIn && !hasAnyCustom) continue;

    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Text(
              _asciiSafe(g.title),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          for (int i = 0; i < snaps.length; i++) pw.SizedBox.shrink(),
        ],
      ),
    );

    // Built-in labs
    for (final t in g.tests) {
      if (!anyValueForKey(t.key)) continue;

      final unitSafe = _unitAsciiSafe(t.unit);
      final label = unitSafe.isNotEmpty ? '${t.key} ($unitSafe)' : t.key;

      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 8,
              ),
              child: pw.Text(
                _asciiSafe(label),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            ...snaps.map((s) {
              final v = s.values[t.key];
              final text = v == null ? '—' : _fmtNum(v);

              final r = LabCatalog.effectiveRange(
                def: t,
                gender: gender,
                overrides: const {},
              );
              final st = LabCatalog.evaluateWithRange(range: r, value: v);

              final bg = _bgForLabStatus(st);
              final fg = _fgForLabStatus(st);

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 6,
                ),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: bg,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  _asciiSafe(text),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: fg,
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    // Custom labs under this group
    for (final customKey in customKeys) {
      if (!anyValueForKey(customKey)) continue;
      final parsed = parseCustomLabKey(customKey);
      if (parsed == null) continue;

      final unitSafe = _unitAsciiSafe(parsed.unit);
      final label = unitSafe.isNotEmpty
          ? '${parsed.label} ($unitSafe)'
          : parsed.label;

      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 8,
              ),
              child: pw.Text(
                _asciiSafe(label),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            ...snaps.map((s) {
              final v = s.values[customKey];
              final text = v == null ? '—' : _fmtNum(v);

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 6,
                ),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  _asciiSafe(text),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    rows.add(
      pw.TableRow(
        children: List.generate(
          1 + snaps.length,
          (_) => pw.SizedBox(height: 6),
        ),
      ),
    );
  }

  // "Other" custom labs group
  final otherKeys = customKeysByGroupId['other'] ?? const <String>[];
  final hasAnyOther = otherKeys.any((k) => anyValueForKey(k));
  if (hasAnyOther) {
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Text(
              'Other',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          for (int i = 0; i < snaps.length; i++) pw.SizedBox.shrink(),
        ],
      ),
    );

    for (final customKey in otherKeys) {
      if (!anyValueForKey(customKey)) continue;
      final parsed = parseCustomLabKey(customKey);
      if (parsed == null) continue;

      final unitSafe = _unitAsciiSafe(parsed.unit);
      final label = unitSafe.isNotEmpty
          ? '${parsed.label} ($unitSafe)'
          : parsed.label;

      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 8,
              ),
              child: pw.Text(
                _asciiSafe(label),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            ...snaps.map((s) {
              final v = s.values[customKey];
              final text = v == null ? '—' : _fmtNum(v);

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 6,
                ),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  _asciiSafe(text),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    rows.add(
      pw.TableRow(
        children: List.generate(
          1 + snaps.length,
          (_) => pw.SizedBox(height: 6),
        ),
      ),
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
    columnWidths: {
      0: const pw.FixedColumnWidth(190),
      for (int i = 1; i <= snaps.length; i++) i: const pw.FixedColumnWidth(88),
    },
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: rows,
  );
}

pw.Widget _cell(
  String text, {
  bool isHeader = false,
  pw.Alignment align = pw.Alignment.center,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    alignment: align,
    child: pw.Text(
      _asciiSafe(text),
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: isHeader ? PdfColors.grey800 : PdfColors.grey900,
      ),
    ),
  );
}

PdfColor _bgForLabStatus(LabStatus s) {
  switch (s) {
    case LabStatus.normal:
      return const PdfColor(0.90, 0.98, 0.92);
    case LabStatus.warning:
      return const PdfColor(1.00, 0.97, 0.85);
    case LabStatus.critical:
      return const PdfColor(1.00, 0.90, 0.90);
    case LabStatus.missing:
      return PdfColors.white;
  }
}

PdfColor _fgForLabStatus(LabStatus s) {
  switch (s) {
    case LabStatus.normal:
      return const PdfColor(0.10, 0.55, 0.20);
    case LabStatus.warning:
      return const PdfColor(0.70, 0.45, 0.00);
    case LabStatus.critical:
      return const PdfColor(0.70, 0.10, 0.10);
    case LabStatus.missing:
      return PdfColors.grey700;
  }
}

// ========================= Data helpers =========================

// ✅ Load logo (unit -> hospital) from Hive when headerLogoBytes isn't passed.
Future<Uint8List?> _resolveHeaderLogoBytes({
  required String hospitalName,
  required String unitName,
}) async {
  try {
    final meta = HierarchyMetaRepository();

    final hospitalId = meta.normalizeId(hospitalName);

    // Match UnitsScreen scheme:
    // unitId = normalizeId('${hospitalId}::$unitName')
    final unitId = meta.normalizeId('$hospitalId::$unitName');

    // 1) Unit logo first
    final unitPath = await meta.getLogoPath(scope: 'units', id: unitId);
    final unitBytes = await meta.loadLogoBytesFromPath(unitPath);
    if (unitBytes != null && unitBytes.isNotEmpty) return unitBytes;

    // 2) Hospital logo fallback
    final hospitalPath = await meta.getLogoPath(
      scope: 'hospitals',
      id: hospitalId,
    );
    final hospitalBytes = await meta.loadLogoBytesFromPath(hospitalPath);
    if (hospitalBytes != null && hospitalBytes.isNotEmpty) return hospitalBytes;

    return null;
  } catch (_) {
    return null;
  }
}

Future<List<pw.ImageProvider>> _loadImages(List<String> paths) async {
  final out = <pw.ImageProvider>[];
  for (final raw in paths) {
    final p = raw.trim();
    if (p.isEmpty) continue;

    if (p.startsWith('sb:')) {
      try {
        final rest = p.substring(3);
        final i = rest.indexOf(':');
        if (i > 0 && i < rest.length - 1) {
          final bucket = rest.substring(0, i);
          final path = rest.substring(i + 1);
          final bytes = await Supabase.instance.client.storage
              .from(bucket)
              .download(path);
          if (bytes.isNotEmpty) out.add(pw.MemoryImage(bytes));
          continue;
        }
      } catch (_) {
        // ignore
      }
    }

    try {
      final f = File(p);
      if (!await f.exists()) continue;
      final bytes = await f.readAsBytes();
      out.add(pw.MemoryImage(bytes));
    } catch (_) {
      // ignore
    }
  }
  return out;
}

List<String> _compact(List<String> items) =>
    items.map(_clean).where((e) => e.isNotEmpty).toList();

String _clean(String s) =>
    s.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

String _fmtNum(double v) {
  final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
  return s.replaceAll(RegExp(r'\.?0+$'), '');
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().padLeft(4, '0')}';

String _fmtDateTime(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${_fmtDate(d)} $hh:$mm';
}

String _fmtDateCol(DateTime d) {
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

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Replace symbols that Helvetica often can't render (prevents □ and weird chars in PDF)
String _asciiSafe(String s) {
  // map superscript digits
  const sup = {
    '⁰': '0',
    '¹': '1',
    '²': '2',
    '³': '3',
    '⁴': '4',
    '⁵': '5',
    '⁶': '6',
    '⁷': '7',
    '⁸': '8',
    '⁹': '9',
  };

  // map subscript digits (optional but useful)
  const sub = {
    '₀': '0',
    '₁': '1',
    '₂': '2',
    '₃': '3',
    '₄': '4',
    '₅': '5',
    '₆': '6',
    '₇': '7',
    '₈': '8',
    '₉': '9',
  };

  String out = s
      .replaceAll('—', '-') // em dash
      .replaceAll('–', '-') // en dash
      .replaceAll('→', '->') // arrow
      .replaceAll('×', 'x') // multiplication
      .replaceAll('µ', 'u') // micro
      .replaceAll('•', '-') // bullet
      .replaceAll('\\', '/') // IMPORTANT: "\" in units
      .replaceAll('·', '.'); // dot operator

  // convert superscript sequences: 10⁹ -> 10^9
  out = out.replaceAllMapped(RegExp(r'[⁰¹²³⁴⁵⁶⁷⁸⁹]+'), (m) {
    final seq = m.group(0)!;
    final digits = seq.split('').map((c) => sup[c] ?? '').join();
    return '^$digits';
  });

  // convert subscript sequences: HCO₃ -> HCO3
  out = out.replaceAllMapped(RegExp(r'[₀₁₂₃₄₅₆₇₈₉]+'), (m) {
    final seq = m.group(0)!;
    final digits = seq.split('').map((c) => sub[c] ?? '').join();
    return digits;
  });

  return out;
}

String _unitAsciiSafe(String unit) => _asciiSafe(_clean(unit));

class _KV {
  final String label;
  final String value;
  const _KV(this.label, this.value);
}

class _DaySnap {
  final DateTime date;
  final Map<String, double> values;
  const _DaySnap({required this.date, required this.values});
}
