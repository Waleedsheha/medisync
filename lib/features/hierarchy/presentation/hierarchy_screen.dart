// lib/features/hierarchy/presentation/hierarchy_screen.dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/premium_action_button.dart';
import '../data/hierarchy_meta_repository.dart';
import '../data/hierarchy_providers.dart';

enum _HospitalAction { edit, pinToggle, delete }

class HierarchyScreen extends ConsumerStatefulWidget {
  const HierarchyScreen({super.key});

  @override
  ConsumerState<HierarchyScreen> createState() => _HierarchyScreenState();
}

class _HierarchyScreenState extends ConsumerState<HierarchyScreen> {
  final _q = TextEditingController();
  final _meta = HierarchyMetaRepository();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final hospitalsAsync = ref.watch(hospitalsControllerProvider);
    final ctrl = ref.read(hospitalsControllerProvider.notifier);

    return AppScaffold(
      title: 'Hospitals',
      actions: [
        IconButton(
          onPressed: () => ctrl.refresh(),
          icon: const Icon(LucideIcons.refreshCcw),
          tooltip: 'Refresh',
        ),
      ],
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PremiumActionButton(
        onPressed: () => _showAddHospitalSheet(context, ctrl),
        icon: LucideIcons.plus,
        label: 'Add Hospital',
      ),
      body: Column(
        children: [
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search hospitals...',
              prefixIcon: Icon(LucideIcons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: hospitalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (hospitals) {
                final q = _q.text.trim().toLowerCase();

                final filtered = hospitals.where((h) {
                  if (q.isEmpty) return true;
                  return h.name.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No hospitals'));
                }

                return FutureBuilder<List<String>>(
                  future: _meta.listPinnedIds(scope: 'hospitals', limit: 3),
                  builder: (context, pinSnap) {
                    final pinnedIds = pinSnap.data ?? const <String>[];

                    filtered.sort((a, b) {
                      final ai = pinnedIds.indexOf(a.id);
                      final bi = pinnedIds.indexOf(b.id);
                      final ap = ai != -1;
                      final bp = bi != -1;
                      if (ap && bp) return ai.compareTo(bi); // pinned order
                      if (ap) return -1;
                      if (bp) return 1;
                      return a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                    });

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final h = filtered[i];

                        return FutureBuilder<_HospitalMeta>(
                          future: _loadHospitalMeta(h),
                          builder: (context, snap) {
                            final meta = snap.data;
                            final displayName = meta?.displayName ?? h.name;
                            final isPinned = pinnedIds.contains(h.id);

                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  // ✅ pass both hospitalId + hospitalName (router patch below)
                                  context.push(
                                    '/departments',
                                    extra: {
                                      'hospitalId': h.id,
                                      'hospitalName': displayName,
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      _LogoAvatar(
                                        bytes: meta?.logoBytes,
                                        fallbackColor: scheme.primary
                                            .withValues(alpha: 0.12),
                                        iconColor: scheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    displayName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                  ),
                                                ),
                                                if (isPinned) ...[
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    LucideIcons.pin,
                                                    size: 18,
                                                    color: scheme.primary,
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              h.subtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ✅ three dots menu (instead of pencil)
                                      PopupMenuButton<_HospitalAction>(
                                        icon: const Icon(
                                          LucideIcons.moreVertical,
                                        ),
                                        onSelected: (a) => _onHospitalAction(
                                          context,
                                          h,
                                          meta,
                                          a,
                                          ctrl,
                                        ),
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: _HospitalAction.edit,
                                            child: ListTile(
                                              dense: true,
                                              leading: Icon(LucideIcons.edit2),
                                              title: Text('Edit'),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: _HospitalAction.pinToggle,
                                            child: ListTile(
                                              dense: true,
                                              leading: Icon(
                                                isPinned
                                                    ? LucideIcons.pinOff
                                                    : LucideIcons.pin,
                                              ),
                                              title: Text(
                                                isPinned ? 'Unpin' : 'Pin',
                                              ),
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: _HospitalAction.delete,
                                            child: ListTile(
                                              dense: true,
                                              leading: Icon(LucideIcons.trash2),
                                              title: Text('Delete'),
                                            ),
                                          ),
                                        ],
                                      ),

                                      Icon(
                                        LucideIcons.chevronRight,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onHospitalAction(
    BuildContext context,
    HospitalItem h,
    _HospitalMeta? meta,
    _HospitalAction action,
    HospitalsController ctrl,
  ) async {
    switch (action) {
      case _HospitalAction.edit:
        await _showEditHospitalSheet(context, h);
        setState(() {});
        return;

      case _HospitalAction.pinToggle:
        final pinned = await _meta.getPinnedAt(scope: 'hospitals', id: h.id);
        if (pinned == null) {
          final pinnedIds = await _meta.listPinnedIds(
            scope: 'hospitals',
            limit: 3,
          );
          if (pinnedIds.length >= 3) {
            if (context.mounted) {
              _snack(context, 'You can pin only 3 hospitals. Unpin one first.');
            }
            return;
          }
          await _meta.setPinnedAt(
            scope: 'hospitals',
            id: h.id,
            pinnedAt: DateTime.now(),
          );
          if (context.mounted) _snack(context, 'Pinned');
        } else {
          await _meta.setPinnedAt(scope: 'hospitals', id: h.id, pinnedAt: null);
          if (context.mounted) _snack(context, 'Unpinned');
        }
        setState(() {});
        return;

      case _HospitalAction.delete:
        final ok = await _confirmDelete(
          context,
          title: 'Delete hospital?',
          message: 'This will remove the hospital and its metadata.',
        );
        if (ok != true) return;

        await ctrl.deleteHospital(h.id);
        await _meta.setNameOverride(scope: 'hospitals', id: h.id, name: null);
        await _meta.setLogoPath(scope: 'hospitals', id: h.id, path: null);
        await _meta.setPinnedAt(scope: 'hospitals', id: h.id, pinnedAt: null);

        setState(() {});
        return;
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<_HospitalMeta> _loadHospitalMeta(HospitalItem h) async {
    final nameOverride = await _meta.getNameOverride(
      scope: 'hospitals',
      id: h.id,
    );
    final logoPath = await _meta.getLogoPath(scope: 'hospitals', id: h.id);
    final logoBytes = await _meta.loadLogoBytesFromPath(logoPath);

    final display = (nameOverride ?? '').trim().isNotEmpty
        ? nameOverride!.trim()
        : h.name;

    return _HospitalMeta(
      displayName: display,
      logoBytes: (logoBytes != null && logoBytes.isNotEmpty) ? logoBytes : null,
    );
  }

  Future<void> _showAddHospitalSheet(
    BuildContext context,
    HospitalsController ctrl,
  ) async {
    final name = TextEditingController();
    String? hospitalNameToAdd;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Hospital',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Hospital name',
                  prefixIcon: Icon(LucideIcons.building),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  final n = name.text.trim();
                  if (n.isEmpty) return;
                  hospitalNameToAdd = n;
                  FocusScope.of(ctx).unfocus();
                  Navigator.of(ctx, rootNavigator: true).pop();
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    // Add hospital after sheet is fully closed (controller GC'd naturally)
    if (hospitalNameToAdd != null) {
      final added = await ctrl.addHospital(hospitalNameToAdd!);
      if (!added && context.mounted) {
        _snack(context, 'A hospital with that name already exists.');
      }
    }
  }

  Future<void> _showEditHospitalSheet(
    BuildContext context,
    HospitalItem h,
  ) async {
    final initialOverride = await _meta.getNameOverride(
      scope: 'hospitals',
      id: h.id,
    );
    final initialLogoPath = await _meta.getLogoPath(
      scope: 'hospitals',
      id: h.id,
    );

    final nameCtrl = TextEditingController(
      text: (initialOverride ?? '').trim(),
    );
    String? logoPath = (initialLogoPath ?? '').trim().isEmpty
        ? null
        : initialLogoPath!.trim();
    Uint8List? logoBytes = await _meta.loadLogoBytesFromPath(logoPath);
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;

        return StatefulBuilder(
          builder: (context, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit Hospital',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('Default name: ${h.name}'),
                  const SizedBox(height: 10),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name (optional override)',
                      prefixIcon: Icon(LucideIcons.edit2),
                      hintText: 'Leave empty to use default',
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      _LogoAvatar(
                        bytes: logoBytes,
                        fallbackColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        iconColor: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final res = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );
                            final p = res?.files.first.path;
                            if (p == null || p.trim().isEmpty) return;

                            final b = await _meta.loadLogoBytesFromPath(
                              p.trim(),
                            );
                            setSheet(() {
                              logoPath = p.trim();
                              logoBytes = (b != null && b.isNotEmpty)
                                  ? b
                                  : null;
                            });
                          },
                          icon: const Icon(LucideIcons.image),
                          label: const Text('Pick Logo'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          setSheet(() {
                            logoPath = null;
                            logoBytes = null;
                          });
                        },
                        icon: const Icon(LucideIcons.trash2),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () async {
                      final override = nameCtrl.text.trim();
                      final pathToSave = (logoPath ?? '').trim().isEmpty
                          ? null
                          : logoPath;

                      // Pop first to avoid race condition
                      FocusScope.of(context).unfocus();
                      Navigator.of(context, rootNavigator: true).pop();

                      // Save metadata after pop
                      await _meta.setNameOverride(
                        scope: 'hospitals',
                        id: h.id,
                        name: override.isEmpty ? null : override,
                      );

                      String? logoRef;
                      if (pathToSave != null) {
                        logoRef = await _meta.uploadLogoFromFile(
                          scope: 'hospitals',
                          id: h.id,
                          filePath: pathToSave,
                        );
                      }

                      await _meta.setLogoPath(
                        scope: 'hospitals',
                        id: h.id,
                        path: logoRef ?? pathToSave,
                      );
                    },
                    icon: const Icon(LucideIcons.save),
                    label: const Text('Save'),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
  }
}

class _HospitalMeta {
  final String displayName;
  final Uint8List? logoBytes;

  const _HospitalMeta({required this.displayName, required this.logoBytes});
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({
    required this.bytes,
    required this.fallbackColor,
    required this.iconColor,
  });

  final Uint8List? bytes;
  final Color fallbackColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final b = bytes;
    if (b != null && b.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.memory(b, width: 48, height: 48, fit: BoxFit.cover),
      );
    }

    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: fallbackColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(LucideIcons.building, color: iconColor),
    );
  }
}
