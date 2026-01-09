import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/glass_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../data/clinic_providers.dart';

class ClinicsScreen extends ConsumerStatefulWidget {
  const ClinicsScreen({super.key});

  @override
  ConsumerState<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends ConsumerState<ClinicsScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinicsAsync = ref.watch(clinicsControllerProvider);
    final ctrl = ref.read(clinicsControllerProvider.notifier);

    return AppScaffold(
      title: 'Clinics',
      actions: [
        IconButton(
          onPressed: () => ctrl.refresh(),
          icon: const Icon(LucideIcons.refreshCcw),
          tooltip: 'Refresh',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClinicSheet(context, ctrl),
        icon: const Icon(LucideIcons.plus),
        label: const Text(
          'Add Clinic',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search clinics...',
                prefixIcon: Icon(LucideIcons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: clinicsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (clinics) {
                final q = _q.text.trim().toLowerCase();

                final filtered = clinics.where((c) {
                  if (q.isEmpty) return true;
                  return c.name.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No clinics'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = filtered[i];

                    return Container(
                      decoration: BoxDecoration(
                        color: GlassTheme.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GlassTheme.glassBorder),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          final clinicName = Uri.encodeComponent(c.name);
                          context.push('/clinic-patients?clinic=$clinicName');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: GlassTheme.neonPurple.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  LucideIcons.stethoscope,
                                  color: GlassTheme.neonPurple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        color: GlassTheme.textWhite,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.subtitle,
                                      style: TextStyle(
                                        color: GlassTheme.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  LucideIcons.moreVertical,
                                  color: GlassTheme.textMuted,
                                ),
                                color: GlassTheme.cardBackground,
                                onSelected: (action) =>
                                    _onClinicAction(context, c, action, ctrl),
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(LucideIcons.edit2),
                                      title: Text('Edit'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
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
                                color: GlassTheme.textMuted,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Future<void> _onClinicAction(
    BuildContext context,
    ClinicItem c,
    String action,
    ClinicsController ctrl,
  ) async {
    switch (action) {
      case 'edit':
        await _showEditClinicSheet(context, c, ctrl);
        setState(() {});
        return;
      case 'delete':
        final ok = await _confirmDelete(
          context,
          title: 'Delete clinic?',
          message: 'This will remove the clinic.',
        );
        if (ok != true) return;
        await ctrl.deleteClinic(c.id);
        setState(() {});
        return;
    }
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

  Future<void> _showAddClinicSheet(
    BuildContext context,
    ClinicsController ctrl,
  ) async {
    final name = TextEditingController();
    String? clinicNameToAdd;

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
                'Add Clinic',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Clinic name',
                  prefixIcon: Icon(LucideIcons.stethoscope),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  final n = name.text.trim();
                  if (n.isEmpty) return;
                  clinicNameToAdd = n;
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

    // Add clinic after sheet is fully closed (controller GC'd naturally)
    if (clinicNameToAdd != null) {
      final added = await ctrl.addClinic(clinicNameToAdd!);
      if (!added && context.mounted) {
        _snack(context, 'A clinic with that name already exists.');
      }
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

  Future<void> _showEditClinicSheet(
    BuildContext context,
    ClinicItem c,
    ClinicsController ctrl,
  ) async {
    final nameCtrl = TextEditingController(text: c.name);

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
                'Edit Clinic',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Clinic name',
                  prefixIcon: Icon(LucideIcons.edit2),
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
                  await ctrl.renameClinic(clinicId: c.id, newName: newName);
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
