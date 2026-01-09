// lib/features/hierarchy/presentation/facility_list_screen.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/premium_action_button.dart';
import '../data/hierarchy_meta_repository.dart';

class FacilityListScreen extends StatefulWidget {
  const FacilityListScreen({super.key, required this.kind});

  /// hospitals | clinics | plans | archive
  final String kind;

  @override
  State<FacilityListScreen> createState() => _FacilityListScreenState();
}

class _FacilityListScreenState extends State<FacilityListScreen> {
  final _q = TextEditingController();
  late final List<_Item> _items;

  final _meta = HierarchyMetaRepository();

  // cached meta (to avoid FutureBuilder per tile)
  final Map<String, String?> _nameOverride = {};
  final Map<String, String?> _logoPath = {};

  String get _scope => widget.kind; // use kind as scope

  @override
  void initState() {
    super.initState();
    _items = List.generate(10, (i) {
      final n = i + 1;
      final title = '${_titlePrefix(widget.kind)} $n';
      return _Item(
        id: _meta.normalizeId(title),
        title: title,
        subtitle: _subtitleFor(widget.kind, n),
      );
    });

    _refreshAllMeta();
  }

  Future<void> _refreshAllMeta() async {
    for (final it in _items) {
      final id = it.id;
      _nameOverride[id] = await _meta.getNameOverride(scope: _scope, id: id);
      _logoPath[id] = await _meta.getLogoPath(scope: _scope, id: id);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String _effectiveTitle(_Item item) {
    final ov = _nameOverride[item.id];
    return (ov == null || ov.trim().isEmpty) ? item.title : ov.trim();
  }

  Widget _leadingFor(_Cfg cfg, _Item item) {
    final path = _logoPath[item.id];
    if (path != null && path.trim().isNotEmpty) {
      final f = File(path);
      if (f.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(f, width: 42, height: 42, fit: BoxFit.cover),
        );
      }
    }

    return CircleAvatar(child: Icon(cfg.leadingIcon));
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfgFor(context, widget.kind);

    final filtered = _items.where((x) {
      final q = _q.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return _effectiveTitle(x).toLowerCase().contains(q);
    }).toList();

    return AppScaffold(
      title: cfg.pageTitle,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PremiumActionButton(
        onPressed: () => _showAddSheet(context, cfg),
        icon: LucideIcons.plus,
        label: cfg.addButtonText,
      ),
      body: Column(
        children: [
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: cfg.searchHint,
              prefixIcon: const Icon(LucideIcons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = filtered[i];
                final title = _effectiveTitle(item);

                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: Theme.of(context).colorScheme.surfaceContainer,
                  leading: _leadingFor(cfg, item),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<_Action>(
                    tooltip: 'Actions',
                    onSelected: (a) => _handleAction(context, cfg, item, a),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _Action.edit,
                        child: Text('Edit name'),
                      ),
                      PopupMenuItem(
                        value: _Action.pickLogo,
                        child: Text('Pick logo'),
                      ),
                      PopupMenuItem(
                        value: _Action.removeLogo,
                        child: Text('Remove logo'),
                      ),
                    ],
                    child: const Icon(LucideIcons.moreVertical),
                  ),
                  onTap: () {
                    // Hospitals -> Departments
                    if (widget.kind == 'hospitals') {
                      context.push(
                        '/departments',
                        extra: {'hospitalId': item.id, 'hospitalName': title},
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Open: $title (next screen later)'),
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

  Future<void> _handleAction(
    BuildContext context,
    _Cfg cfg,
    _Item item,
    _Action a,
  ) async {
    switch (a) {
      case _Action.edit:
        await _editName(context, cfg, item);
        return;
      case _Action.pickLogo:
        await _pickLogo(context, item);
        return;
      case _Action.removeLogo:
        await _removeLogo(item);
        return;
    }
  }

  Future<void> _editName(BuildContext context, _Cfg cfg, _Item item) async {
    final controller = TextEditingController(text: _effectiveTitle(item));
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: cfg.nameFieldLabel,
                  prefixIcon: Icon(cfg.leadingIcon),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (result == null) return;

    // store override (even if equals original, ok)
    await _meta.setNameOverride(scope: _scope, id: item.id, name: result);
    _nameOverride[item.id] = result;
    if (mounted) setState(() {});
  }

  Future<void> _pickLogo(BuildContext context, _Item item) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = res?.files.single.path;
    if (path == null || path.trim().isEmpty) return;

    await _meta.setLogoPath(scope: _scope, id: item.id, path: path);
    _logoPath[item.id] = path;

    if (mounted) setState(() {});
  }

  Future<void> _removeLogo(_Item item) async {
    await _meta.setLogoPath(scope: _scope, id: item.id, path: null);
    _logoPath[item.id] = null;
    if (mounted) setState(() {});
  }

  void _showAddSheet(BuildContext context, _Cfg cfg) {
    final title = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                cfg.sheetTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: InputDecoration(
                  labelText: cfg.nameFieldLabel,
                  prefixIcon: Icon(cfg.leadingIcon),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final t = title.text.trim();
                  if (t.isEmpty) return;

                  final newItem = _Item(
                    title: t,
                    subtitle: cfg.defaultSubtitle,
                    id: _meta.normalizeId(t),
                  );
                  setState(() => _items.insert(0, newItem));

                  // initialize caches
                  _nameOverride[newItem.id] = await _meta.getNameOverride(
                    scope: _scope,
                    id: newItem.id,
                  );
                  _logoPath[newItem.id] = await _meta.getLogoPath(
                    scope: _scope,
                    id: newItem.id,
                  );

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).whenComplete(() => title.dispose());
  }
}

enum _Action { edit, pickLogo, removeLogo }

class _Item {
  final String id;
  final String title;
  final String subtitle;
  _Item({required this.id, required this.title, required this.subtitle});
}

String _titlePrefix(String kind) {
  switch (kind) {
    case 'clinics':
      return 'Clinic';
    case 'plans':
      return 'Plan';
    case 'archive':
      return 'File';
    case 'hospitals':
    default:
      return 'Hospital';
  }
}

String _subtitleFor(String kind, int n) {
  switch (kind) {
    case 'clinics':
      return 'Outpatient • ${(n % 20) + 5} visits';
    case 'plans':
      return 'Scheduled • ${(n % 5) + 1} tasks';
    case 'archive':
      return 'Reports • ${(n % 30) + 10} items';
    case 'hospitals':
    default:
      return '${(n % 4) + 1} units • ${(n % 12) + 5} patients';
  }
}

class _Cfg {
  final String pageTitle;
  final String addButtonText;
  final String searchHint;
  final String sheetTitle;
  final String nameFieldLabel;
  final String defaultSubtitle;
  final IconData leadingIcon;

  _Cfg({
    required this.pageTitle,
    required this.addButtonText,
    required this.searchHint,
    required this.sheetTitle,
    required this.nameFieldLabel,
    required this.defaultSubtitle,
    required this.leadingIcon,
  });
}

_Cfg _cfgFor(BuildContext context, String kind) {
  switch (kind) {
    case 'clinics':
      return _Cfg(
        pageTitle: 'Clinics',
        addButtonText: 'Add Clinic',
        searchHint: 'Search clinics...',
        sheetTitle: 'Add Clinic',
        nameFieldLabel: 'Clinic name',
        defaultSubtitle: 'Outpatient • 0 visits',
        leadingIcon: LucideIcons.stethoscope,
      );

    case 'plans':
      return _Cfg(
        pageTitle: 'Plans',
        addButtonText: 'Add Plan',
        searchHint: 'Search plans...',
        sheetTitle: 'Add Plan',
        nameFieldLabel: 'Plan title',
        defaultSubtitle: 'Scheduled • 0 tasks',
        leadingIcon: LucideIcons.calendarClock,
      );

    case 'archive':
      return _Cfg(
        pageTitle: 'Archive',
        addButtonText: 'Add File',
        searchHint: 'Search files...',
        sheetTitle: 'Add File',
        nameFieldLabel: 'File name',
        defaultSubtitle: 'Reports • 0 items',
        leadingIcon: LucideIcons.archive,
      );

    case 'hospitals':
    default:
      return _Cfg(
        pageTitle: 'Hospitals',
        addButtonText: 'Add Hospital',
        searchHint: 'Search hospitals...',
        sheetTitle: 'Add Hospital',
        nameFieldLabel: 'Hospital name',
        defaultSubtitle: '0 units • 0 patients',
        leadingIcon: LucideIcons.building,
      );
  }
}
