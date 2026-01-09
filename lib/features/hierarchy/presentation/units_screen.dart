// lib/features/hierarchy/presentation/units_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/premium_action_button.dart';
import '../data/hierarchy_meta_repository.dart';
import '../data/hierarchy_providers.dart';
import '../../patients/data/facility_resolver.dart';

@immutable
class UnitsScreenLabels {
  final String screenTitleFallback;
  final String addFabLabel;
  final String searchHint;
  final String emptyText;
  final String itemSubtitle;
  final String pinLimitSnack;

  final String deleteDialogTitle;
  final String deleteDialogMessage;

  final String addSheetTitle;
  final String addFieldLabel;
  final IconData addFieldIcon;
  final String duplicateNameSnack;

  final String editSheetTitle;
  final String editFieldLabel;
  final IconData editFieldIcon;

  const UnitsScreenLabels({
    required this.screenTitleFallback,
    required this.addFabLabel,
    required this.searchHint,
    required this.emptyText,
    required this.itemSubtitle,
    required this.pinLimitSnack,
    required this.deleteDialogTitle,
    required this.deleteDialogMessage,
    required this.addSheetTitle,
    required this.addFieldLabel,
    required this.addFieldIcon,
    required this.duplicateNameSnack,
    required this.editSheetTitle,
    required this.editFieldLabel,
    required this.editFieldIcon,
  });

  static const UnitsScreenLabels units = UnitsScreenLabels(
    screenTitleFallback: 'Units',
    addFabLabel: 'Add Clinic',
    searchHint: 'Search units...',
    emptyText: 'No units',
    itemSubtitle: 'Tap to view patients',
    pinLimitSnack: 'You can pin only 3 units. Unpin one first.',
    deleteDialogTitle: 'Delete unit?',
    deleteDialogMessage: 'This will remove the unit.',
    addSheetTitle: 'Add Clinic',
    addFieldLabel: 'Clinic name',
    addFieldIcon: LucideIcons.stethoscope,
    duplicateNameSnack: 'A unit with that name already exists.',
    editSheetTitle: 'Edit Unit',
    editFieldLabel: 'Unit name',
    editFieldIcon: LucideIcons.edit2,
  );

  static const UnitsScreenLabels departments = UnitsScreenLabels(
    screenTitleFallback: 'Departments',
    addFabLabel: 'Add Department',
    searchHint: 'Search departments...',
    emptyText: 'No departments',
    itemSubtitle: 'Tap to view patients',
    pinLimitSnack: 'You can pin only 3 departments. Unpin one first.',
    deleteDialogTitle: 'Delete department?',
    deleteDialogMessage: 'This will remove the department.',
    addSheetTitle: 'Add Department',
    addFieldLabel: 'Department name',
    addFieldIcon: LucideIcons.building2,
    duplicateNameSnack: 'A department with that name already exists.',
    editSheetTitle: 'Edit Department',
    editFieldLabel: 'Department name',
    editFieldIcon: LucideIcons.edit2,
  );
}

enum _UnitAction { edit, pinToggle, delete }

class UnitsScreen extends ConsumerStatefulWidget {
  const UnitsScreen({
    super.key,
    required this.hospitalName,
    this.hospitalId = '',
    this.labels = UnitsScreenLabels.units,
  });

  final String hospitalName;

  /// Optional stable id (recommended). If empty, we derive from hospitalName.
  final String hospitalId;

  final UnitsScreenLabels labels;

  @override
  ConsumerState<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends ConsumerState<UnitsScreen> {
  final _q = TextEditingController();
  final _meta = HierarchyMetaRepository();

  String _hospitalId = '';

  @override
  void initState() {
    super.initState();
    _hospitalId = widget.hospitalId.trim().isNotEmpty
        ? widget.hospitalId.trim()
        : _meta.normalizeId(widget.hospitalName);

    // If launched without an id (legacy routes), try to resolve to Supabase uuid.
    if (widget.hospitalId.trim().isEmpty && widget.hospitalName.trim().isNotEmpty) {
      Future.microtask(() async {
        try {
          final client = Supabase.instance.client;
          final id = await FacilityResolver(client).findHospitalIdByName(widget.hospitalName);
          if (!mounted) return;
          if (id != null && id.trim().isNotEmpty && id.trim() != _hospitalId) {
            setState(() => _hospitalId = id.trim());
          }
        } catch (_) {
          // ignore
        }
      });
    }
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(unitsControllerProvider(_hospitalId));
    final ctrl = ref.read(unitsControllerProvider(_hospitalId).notifier);

    return AppScaffold(
      title:
          widget.hospitalName.isEmpty ? widget.labels.screenTitleFallback : widget.hospitalName,
      actions: [
        IconButton(
          onPressed: () => ctrl.refresh(),
          icon: const Icon(LucideIcons.refreshCcw),
          tooltip: 'Refresh',
        ),
      ],
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PremiumActionButton(
        onPressed: () => _showAddUnitSheet(context, ctrl),
        icon: LucideIcons.plus,
        label: widget.labels.addFabLabel,
      ),
      body: Column(
        children: [
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.labels.searchHint,
              prefixIcon: const Icon(LucideIcons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: unitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (units) {
                final q = _q.text.trim().toLowerCase();

                final filtered = units.where((u) {
                  if (q.isEmpty) return true;
                  return u.name.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text(widget.labels.emptyText));
                }

                return FutureBuilder<List<String>>(
                  future: _meta.listPinnedIds(
                    scope: 'units',
                    idPrefix: '${_hospitalId}__',
                    limit: 3,
                  ),
                  builder: (context, pinSnap) {
                    final pinnedIds = pinSnap.data ?? const <String>[];

                    filtered.sort((a, b) {
                      final aid = '${_hospitalId}__${a.id}';
                      final bid = '${_hospitalId}__${b.id}';
                      final ai = pinnedIds.indexOf(aid);
                      final bi = pinnedIds.indexOf(bid);
                      final ap = ai != -1;
                      final bp = bi != -1;
                      if (ap && bp) return ai.compareTo(bi);
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
                        final u = filtered[i];
                        final pinKeyId = '${_hospitalId}__${u.id}';
                        final isPinned = pinnedIds.contains(pinKeyId);

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          tileColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainer,
                          leading: CircleAvatar(
                            child: Icon(
                              isPinned ? LucideIcons.pin : LucideIcons.building,
                            ),
                          ),
                          title: Text(
                            u.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(widget.labels.itemSubtitle),
                          trailing: PopupMenuButton<_UnitAction>(
                            icon: const Icon(LucideIcons.moreVertical),
                            onSelected: (a) =>
                                _onUnitAction(context, ctrl, u, a, isPinned),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: _UnitAction.edit,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(LucideIcons.edit2),
                                  title: Text('Edit'),
                                ),
                              ),
                              PopupMenuItem(
                                value: _UnitAction.pinToggle,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isPinned
                                        ? LucideIcons.pinOff
                                        : LucideIcons.pin,
                                  ),
                                  title: Text(isPinned ? 'Unpin' : 'Pin'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: _UnitAction.delete,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(LucideIcons.trash2),
                                  title: Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            final h = Uri.encodeComponent(widget.hospitalName);
                            final unit = Uri.encodeComponent(u.name);
                            context.push('/patients?hospital=$h&room=$unit');
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

  Future<void> _onUnitAction(
    BuildContext context,
    UnitsController ctrl,
    UnitItem u,
    _UnitAction action,
    bool isPinned,
  ) async {
    final pinId = '${_hospitalId}__${u.id}';

    switch (action) {
      case _UnitAction.edit:
        await _showEditUnitSheet(context, ctrl, u);
        setState(() {});
        return;

      case _UnitAction.pinToggle:
        final pinned = await _meta.getPinnedAt(scope: 'units', id: pinId);
        if (pinned == null) {
          final pinnedIds = await _meta.listPinnedIds(
            scope: 'units',
            idPrefix: '${_hospitalId}__',
            limit: 3,
          );
          if (pinnedIds.length >= 3) {
            if (context.mounted) {
                                      _snack(context, widget.labels.pinLimitSnack);
            }
            return;
          }
          await _meta.setPinnedAt(
            scope: 'units',
            id: pinId,
            pinnedAt: DateTime.now(),
          );
          if (context.mounted) _snack(context, 'Pinned');
        } else {
          await _meta.setPinnedAt(scope: 'units', id: pinId, pinnedAt: null);
          if (context.mounted) _snack(context, 'Unpinned');
        }
        setState(() {});
        return;

      case _UnitAction.delete:
        final ok = await _confirmDelete(
          context,
          title: widget.labels.deleteDialogTitle,
          message: widget.labels.deleteDialogMessage,
        );
        if (ok != true) return;

        await ctrl.deleteUnit(u.id);
        await _meta.setPinnedAt(scope: 'units', id: pinId, pinnedAt: null);

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

  Future<void> _showAddUnitSheet(
    BuildContext context,
    UnitsController ctrl,
  ) async {
    final name = TextEditingController();
    String? unitNameToAdd;

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
                widget.labels.addSheetTitle,
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: widget.labels.addFieldLabel,
                  prefixIcon: Icon(widget.labels.addFieldIcon),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  final n = name.text.trim();
                  if (n.isEmpty) return;
                  unitNameToAdd = n;
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

    // Add unit after sheet is fully closed (controller GC'd naturally)
    if (unitNameToAdd != null) {
      final added = await ctrl.addUnit(unitNameToAdd!);
      if (!added && context.mounted) {
        _snack(context, widget.labels.duplicateNameSnack);
      }
    }
  }

  Future<void> _showEditUnitSheet(
    BuildContext context,
    UnitsController ctrl,
    UnitItem u,
  ) async {
    final nameCtrl = TextEditingController(text: u.name);

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
                widget.labels.editSheetTitle,
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: widget.labels.editFieldLabel,
                  prefixIcon: Icon(widget.labels.editFieldIcon),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  if (newName.isEmpty) return;

                  // Pop first to avoid race condition
                  FocusScope.of(ctx).unfocus();
                  Navigator.of(ctx, rootNavigator: true).pop();

                  // Rename after pop
                  await ctrl.renameUnit(unitId: u.id, newName: newName);
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

    nameCtrl.dispose();
  }
}
