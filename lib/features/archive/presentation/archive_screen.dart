import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../data/archive_providers.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archiveAsync = ref.watch(archiveControllerProvider);
    final ctrl = ref.read(archiveControllerProvider.notifier);

    return AppScaffold(
      title: 'Archive',
      actions: [
        IconButton(
          onPressed: () => ctrl.refresh(),
          icon: const Icon(LucideIcons.refreshCcw),
          tooltip: 'Refresh',
        ),
      ],
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Hospitals'),
              Tab(text: 'Clinics'),
            ],
          ),
          Expanded(
            child: archiveAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildArchiveList(
                      context,
                      items.where((a) => a.type == 'hospital').toList(),
                      ctrl,
                      'hospital',
                      LucideIcons.building,
                    ),
                    _buildArchiveList(
                      context,
                      items.where((a) => a.type == 'clinic').toList(),
                      ctrl,
                      'clinic',
                      LucideIcons.stethoscope,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveList(
    BuildContext context,
    List<ArchivedItem> items,
    ArchiveController ctrl,
    String type,
    IconData icon,
  ) {
    if (items.isEmpty) {
      return Center(child: Text('No archived ${type}s'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final item = items[i];
        final scheme = Theme.of(context).colorScheme;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Archived ${_formatDate(item.archivedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await ctrl.restoreItem(item.id, item.type);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Restored')));
                    }
                  },
                  icon: const Icon(LucideIcons.rotateCcw),
                  tooltip: 'Restore',
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, item, ctrl),
                  icon: const Icon(LucideIcons.trash2),
                  tooltip: 'Delete permanently',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ArchivedItem item,
    ArchiveController ctrl,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: const Text('This cannot be undone.'),
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

    if (ok == true) {
      await ctrl.deleteFromArchive(item.id, item.type);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deleted permanently')));
      }
    }
  }
}
