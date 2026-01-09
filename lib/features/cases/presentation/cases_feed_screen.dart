import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medisynch/app/glass_theme.dart';
import 'package:medisynch/core/widgets/app_scaffold.dart';
import '../data/cases_repository.dart';
import '../models/case_model.dart';

final casesStreamProvider = StreamProvider<List<CaseModel>>((ref) {
  return ref.watch(casesRepositoryProvider).watchCases();
});

class CasesFeedScreen extends ConsumerWidget {
  const CasesFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesStreamProvider);

    return AppScaffold(
      title: 'Online Cases',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/cases/create'),
        backgroundColor: GlassTheme.neonCyan,
        child: const Icon(LucideIcons.plus, color: Colors.black),
      ),
      body: casesAsync.when(
        data: (cases) {
          if (cases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.fileText,
                    size: 64,
                    color: GlassTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active cases',
                    style: GlassTheme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to post a case!',
                    style: GlassTheme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cases.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final caseItem = cases[index];
              return _CaseCard(caseItem: caseItem);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final CaseModel caseItem;
  const _CaseCard({required this.caseItem});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/cases/detail',
        extra: caseItem,
      ), // Fixed route to match router structure later
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GlassTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GlassTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: GlassTheme.neonPurple.withValues(alpha: 0.2),
                  child: Text(
                    (caseItem.authorName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: GlassTheme.neonPurple),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseItem.authorName ?? 'Unknown User',
                        style: const TextStyle(
                          color: GlassTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(caseItem.createdAt),
                        style: TextStyle(
                          color: GlassTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(caseItem.title, style: GlassTheme.textTheme.titleLarge),
            if (caseItem.body != null) ...[
              const SizedBox(height: 8),
              Text(
                caseItem.body!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GlassTheme.textTheme.bodyMedium,
              ),
            ],
            if (caseItem.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  caseItem.images.first,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 150,
                    color: Colors.grey[900],
                    child: const Icon(LucideIcons.imageOff),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  LucideIcons.messageSquare,
                  size: 16,
                  color: GlassTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Discuss',
                  style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
