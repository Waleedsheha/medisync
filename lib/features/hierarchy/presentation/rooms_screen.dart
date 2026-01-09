import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/premium_action_button.dart';
import '../data/hierarchy_meta_repository.dart';
import '../data/hierarchy_providers.dart';

enum _RoomAction { edit, pinToggle, delete }

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
    required this.departmentId,
    required this.departmentName,
  });

  final String hospitalId;
  final String hospitalName;
  final String departmentId;
  final String departmentName;

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  final _q = TextEditingController();
  final _meta = HierarchyMetaRepository();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(
      roomsControllerProvider((
        hospitalId: widget.hospitalId,
        departmentId: widget.departmentId,
      )),
    );

    final ctrl = ref.read(
      roomsControllerProvider((
        hospitalId: widget.hospitalId,
        departmentId: widget.departmentId,
      )).notifier,
    );

    return AppScaffold(
      title: widget.departmentName.isEmpty ? 'Rooms' : widget.departmentName,
      actions: [
        IconButton(
          onPressed: () => ctrl.refresh(),
          icon: const Icon(LucideIcons.refreshCcw),
          tooltip: 'Refresh',
        ),
      ],
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PremiumActionButton(
        onPressed: () => _showAddRoomSheet(context, ctrl),
        icon: LucideIcons.plus,
        label: 'Add Room',
      ),
      body: Column(
        children: [
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search rooms...',
              prefixIcon: Icon(LucideIcons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: roomsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (rooms) {
                final q = _q.text.trim().toLowerCase();
                final filtered = rooms.where((r) {
                  if (q.isEmpty) return true;
                  return r.name.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No rooms'));
                }

                return FutureBuilder<List<String>>(
                  future: _meta.listPinnedIds(
                    scope: 'rooms',
                    idPrefix: '${widget.departmentId}__',
                    limit: 3,
                  ),
                  builder: (context, pinSnap) {
                    final pinnedIds = pinSnap.data ?? const <String>[];

                    filtered.sort((a, b) {
                      final aid = '${widget.departmentId}__${a.id}';
                      final bid = '${widget.departmentId}__${b.id}';
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
                        final r = filtered[i];
                        final pinKeyId = '${widget.departmentId}__${r.id}';
                        final isPinned = pinnedIds.contains(pinKeyId);

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          tileColor: Theme.of(context).colorScheme.surfaceContainer,
                          leading: CircleAvatar(
                            child: Icon(isPinned ? LucideIcons.pin : LucideIcons.doorOpen),
                          ),
                          title: Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text('Tap to view patients'),
                          trailing: PopupMenuButton<_RoomAction>(
                            icon: const Icon(LucideIcons.moreVertical),
                            onSelected: (a) => _onRoomAction(context, ctrl, r, a, isPinned),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: _RoomAction.edit,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(LucideIcons.edit2),
                                  title: Text('Edit'),
                                ),
                              ),
                              PopupMenuItem(
                                value: _RoomAction.pinToggle,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(isPinned ? LucideIcons.pinOff : LucideIcons.pin),
                                  title: Text(isPinned ? 'Unpin' : 'Pin'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: _RoomAction.delete,
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
                            final room = Uri.encodeComponent(r.name);
                            context.push('/patients?hospital=$h&room=$room');
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

  Future<void> _onRoomAction(
    BuildContext context,
    RoomsController ctrl,
    RoomItem r,
    _RoomAction action,
    bool isPinned,
  ) async {
    final pinId = '${widget.departmentId}__${r.id}';

    switch (action) {
      case _RoomAction.edit:
        await _showEditRoomSheet(context, ctrl, r);
        setState(() {});
        return;

      case _RoomAction.pinToggle:
        final pinned = await _meta.getPinnedAt(scope: 'rooms', id: pinId);
        if (pinned == null) {
          final pinnedIds = await _meta.listPinnedIds(
            scope: 'rooms',
            idPrefix: '${widget.departmentId}__',
            limit: 3,
          );
          if (pinnedIds.length >= 3) {
            if (context.mounted) {
              _snack(context, 'You can pin only 3 rooms. Unpin one first.');
            }
            return;
          }
          await _meta.setPinnedAt(scope: 'rooms', id: pinId, pinnedAt: DateTime.now());
          if (context.mounted) _snack(context, 'Pinned');
        } else {
          await _meta.setPinnedAt(scope: 'rooms', id: pinId, pinnedAt: null);
          if (context.mounted) _snack(context, 'Unpinned');
        }
        setState(() {});
        return;

      case _RoomAction.delete:
        final ok = await _confirmDelete(
          context,
          title: 'Delete room?',
          message: 'This will remove the room.',
        );
        if (ok != true) return;

        await ctrl.deleteRoom(r.id);
        await _meta.setPinnedAt(scope: 'rooms', id: pinId, pinnedAt: null);
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

  Future<void> _showAddRoomSheet(
    BuildContext context,
    RoomsController ctrl,
  ) async {
    final name = TextEditingController();
    String? roomNameToAdd;

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
                'Add Room',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Room name',
                  prefixIcon: Icon(LucideIcons.doorOpen),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  final n = name.text.trim();
                  if (n.isEmpty) return;
                  roomNameToAdd = n;
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

    if (roomNameToAdd != null) {
      final added = await ctrl.addRoom(roomNameToAdd!);
      if (!added && context.mounted) {
        _snack(context, 'A room with that name already exists.');
      }
    }
  }

  Future<void> _showEditRoomSheet(
    BuildContext context,
    RoomsController ctrl,
    RoomItem r,
  ) async {
    final nameCtrl = TextEditingController(text: r.name);

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
                'Edit Room',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Room name',
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
                  await ctrl.renameRoom(roomId: r.id, newName: newName);
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
