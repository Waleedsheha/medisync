import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/premium_action_button.dart';
import '../data/hierarchy_meta_repository.dart';
import '../data/hierarchy_providers.dart';

enum _DepartmentAction { edit, pinToggle, delete }

class DepartmentsScreen extends ConsumerStatefulWidget {
  const DepartmentsScreen({
    super.key,
    required this.hospitalName,
    required this.hospitalId,
  });

  final String hospitalName;
  final String hospitalId;

  @override
  ConsumerState<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends ConsumerState<DepartmentsScreen> {
  final _q = TextEditingController();
  final _meta = HierarchyMetaRepository();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsControllerProvider(widget.hospitalId));
    final ctrl = ref.read(departmentsControllerProvider(widget.hospitalId).notifier);

    return AppScaffold(
      title: widget.hospitalName.isEmpty ? 'Departments' : widget.hospitalName,
      actions: [
        IconButton(
          onPressed: () => ctrl.refresh(),
          icon: const Icon(LucideIcons.refreshCcw),
          tooltip: 'Refresh',
        ),
      ],
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PremiumActionButton(
        onPressed: () => _showAddDepartmentSheet(context, ctrl),
        icon: LucideIcons.plus,
        label: 'Add Department',
      ),
      body: Column(
        children: [
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search departments...',
              prefixIcon: Icon(LucideIcons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: departmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (departments) {
                final q = _q.text.trim().toLowerCase();
                final filtered = departments.where((d) {
                  if (q.isEmpty) return true;
                  return d.name.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No departments'));
                }

                return FutureBuilder<List<String>>(
                  future: _meta.listPinnedIds(
                    scope: 'departments',
                    idPrefix: '${widget.hospitalId}__',
                    limit: 3,
                  ),
                  builder: (context, pinSnap) {
                    final pinnedIds = pinSnap.data ?? const <String>[];

                    filtered.sort((a, b) {
                      final aid = '${widget.hospitalId}__${a.id}';
                      final bid = '${widget.hospitalId}__${b.id}';
                      final ai = pinnedIds.indexOf(aid);
                      final bi = pinnedIds.indexOf(bid);
                      final ap = ai != -1;
                      final bp = bi != -1;
                      if (ap && bp) return ai.compareTo(bi);
                      if (ap) return -1;
                      if (bp) return 1;
                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                    });

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final d = filtered[i];
                        final pinKeyId = '${widget.hospitalId}__${d.id}';
                        final isPinned = pinnedIds.contains(pinKeyId);

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          tileColor: Theme.of(context).colorScheme.surfaceContainer,
                          leading: CircleAvatar(
                            child: Icon(isPinned ? LucideIcons.pin : LucideIcons.layers),
                          ),
                          title: Text(
                            d.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text('Tap to view rooms'),
                          trailing: PopupMenuButton<_DepartmentAction>(
                            icon: const Icon(LucideIcons.moreVertical),
                            onSelected: (a) => _onDepartmentAction(
                              context,
                              ctrl,
                              d,
                              a,
                              isPinned,
                            ),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: _DepartmentAction.edit,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(LucideIcons.edit2),
                                  title: Text('Edit'),
                                ),
                              ),
                              PopupMenuItem(
                                value: _DepartmentAction.pinToggle,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isPinned ? LucideIcons.pinOff : LucideIcons.pin,
                                  ),
                                  title: Text(isPinned ? 'Unpin' : 'Pin'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: _DepartmentAction.delete,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(LucideIcons.trash2),
                                  title: Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            context.push(
                              '/rooms',
                              extra: {
                                'hospitalId': widget.hospitalId,
                                'hospitalName': widget.hospitalName,
                                'departmentId': d.id,
                                'departmentName': d.name,
                              },
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

  Future<void> _onDepartmentAction(
    BuildContext context,
    DepartmentsController ctrl,
    DepartmentItem d,
    _DepartmentAction action,
    bool isPinned,
  ) async {
    final pinId = '${widget.hospitalId}__${d.id}';

    switch (action) {
      case _DepartmentAction.edit:
        await _showEditDepartmentSheet(context, ctrl, d);
        setState(() {});
        return;

      case _DepartmentAction.pinToggle:
        final pinned = await _meta.getPinnedAt(scope: 'departments', id: pinId);
        if (pinned == null) {
          final pinnedIds = await _meta.listPinnedIds(
            scope: 'departments',
            idPrefix: '${widget.hospitalId}__',
            limit: 3,
          );
          if (pinnedIds.length >= 3) {
            if (context.mounted) {
              _snack(context, 'You can pin only 3 departments. Unpin one first.');
            }
            return;
          }
          await _meta.setPinnedAt(scope: 'departments', id: pinId, pinnedAt: DateTime.now());
          if (context.mounted) _snack(context, 'Pinned');
        } else {
          await _meta.setPinnedAt(scope: 'departments', id: pinId, pinnedAt: null);
          if (context.mounted) _snack(context, 'Unpinned');
        }
        setState(() {});
        return;

      case _DepartmentAction.delete:
        final ok = await _confirmDelete(
          context,
          title: 'Delete department?',
          message: 'This will remove the department.',
        );
        if (ok != true) return;

        await ctrl.deleteDepartment(d.id);
        await _meta.setPinnedAt(scope: 'departments', id: pinId, pinnedAt: null);
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

  Future<void> _showAddDepartmentSheet(
    BuildContext context,
    DepartmentsController ctrl,
  ) async {
    final name = TextEditingController();
    String? deptNameToAdd;

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
                'Add Department',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Department name',
                  prefixIcon: Icon(LucideIcons.layers),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  final n = name.text.trim();
                  if (n.isEmpty) return;
                  deptNameToAdd = n;
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

    if (deptNameToAdd != null) {
      final added = await ctrl.addDepartment(deptNameToAdd!);
      if (!added && context.mounted) {
        _snack(context, 'A department with that name already exists.');
      }
    }
  }

  Future<void> _showEditDepartmentSheet(
    BuildContext context,
    DepartmentsController ctrl,
    DepartmentItem d,
  ) async {
    final nameCtrl = TextEditingController(text: d.name);

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
                'Edit Department',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Department name',
                  prefixIcon: Icon(LucideIcons.edit2),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  if (newName.isEmpty) return;
                  FocusScope.of(ctx).unfocus();
                  Navigator.of(ctx, rootNavigator: true).pop();
                  await ctrl.renameDepartment(departmentId: d.id, newName: newName);
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
