import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/patient_details_ui_models.dart';
import 'shared_widgets.dart';

class RadiologyTab extends StatefulWidget {
  const RadiologyTab({
    super.key,
    required this.studies,
    required this.images,
    required this.onPickImage,
    required this.onAddStudy,
    required this.onRemoveStudy,
    required this.onRemoveImage,
    required this.toast,
  });

  final List<RadiologyStudyUi> studies;
  final List<String> images;

  final VoidCallback onPickImage;
  final void Function(RadiologyStudyUi study) onAddStudy;
  final void Function(int index) onRemoveStudy;
  final void Function(int index) onRemoveImage;

  final ToastFn toast;

  @override
  State<RadiologyTab> createState() => _RadiologyTabState();
}

class _RadiologyTabState extends State<RadiologyTab> {
  final _studyTitleCtrl = TextEditingController();
  DateTime _studyDate = DateTime.now();

  @override
  void dispose() {
    _studyTitleCtrl.dispose();
    super.dispose();
  }

  String _dateText(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickStudyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _studyDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _studyDate = picked);
  }

  void _addStudy() {
    final t = _studyTitleCtrl.text.trim();
    if (t.isEmpty) return;

    widget.onAddStudy(RadiologyStudyUi(title: t, date: _studyDate));
    _studyTitleCtrl.clear();
    setState(() => _studyDate = DateTime.now());
    widget.toast('Saved');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const SectionTitle('Radiology'),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.onPickImage,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Image'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Add study'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _studyTitleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Radiology study',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _pickStudyDate,
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(_dateText(_studyDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _addStudy,
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
                const SectionTitle('Studies'),
                const SizedBox(height: 10),
                if (widget.studies.isEmpty)
                  Text('—', style: Theme.of(context).textTheme.bodyMedium)
                else
                  ...widget.studies.asMap().entries.map((e) {
                    final i = e.key;
                    final s = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('• ${s.title} (${_dateText(s.date)})'),
                          ),
                          IconButton(
                            onPressed: () => widget.onRemoveStudy(i),
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove',
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
                const SectionTitle('Images'),
                const SizedBox(height: 10),
                if (widget.images.isEmpty)
                  Text('—', style: Theme.of(context).textTheme.bodyMedium)
                else
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        return Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 92,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: _thumb(widget.images[i]),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                onPressed: () => widget.onRemoveImage(i),
                                icon: const Icon(Icons.close),
                                tooltip: 'Remove',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _thumb(String path) {
    if (kIsWeb) {
      return const Center(child: Icon(Icons.image_outlined));
    }

    final v = path.trim();
    if (v.startsWith('sb:')) {
      return FutureBuilder<File?>(
        future: _ensureCachedFromStorageRef(v),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: Icon(Icons.downloading_outlined));
          }
          final f = snap.data;
          if (f == null || !f.existsSync()) {
            return const Center(child: Icon(Icons.broken_image_outlined));
          }
          return Image.file(f, fit: BoxFit.cover);
        },
      );
    }

    final f = File(v);
    if (!f.existsSync()) return const Center(child: Icon(Icons.broken_image_outlined));
    return Image.file(f, fit: BoxFit.cover);
  }

  ({String bucket, String path})? _parseStorageRef(String value) {
    final v = value.trim();
    if (!v.startsWith('sb:')) return null;
    final rest = v.substring(3);
    final i = rest.indexOf(':');
    if (i <= 0 || i >= rest.length - 1) return null;
    final bucket = rest.substring(0, i);
    final path = rest.substring(i + 1);
    if (bucket.trim().isEmpty || path.trim().isEmpty) return null;
    return (bucket: bucket, path: path);
  }

  Future<File?> _ensureCachedFromStorageRef(String ref) async {
    final parsed = _parseStorageRef(ref);
    if (parsed == null) return null;

    try {
      final base = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(p.join(base.path, 'media_cache', parsed.bucket));
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final hash = sha1.convert(utf8.encode(ref)).toString();
      final ext = p.extension(parsed.path).toLowerCase();
      final safeExt = (ext == '.png' || ext == '.jpg' || ext == '.jpeg') ? ext : '.jpg';
      final file = File(p.join(cacheDir.path, '$hash$safeExt'));
      if (await file.exists() && (await file.length()) > 0) return file;

      final bytes = await Supabase.instance.client.storage
          .from(parsed.bucket)
          .download(parsed.path);
      if (bytes.isEmpty) return null;

      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }
}
