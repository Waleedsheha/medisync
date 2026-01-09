import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medisynch/app/glass_theme.dart';
import 'package:medisynch/core/widgets/app_scaffold.dart';
import '../data/cases_repository.dart';
import '../models/case_model.dart';

final caseCommentsProvider = FutureProvider.family<List<CaseComment>, String>((
  ref,
  caseId,
) async {
  return ref.watch(casesRepositoryProvider).getComments(caseId);
});

class CaseDetailScreen extends ConsumerStatefulWidget {
  final CaseModel caseItem;
  const CaseDetailScreen({super.key, required this.caseItem});

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await ref
          .read(casesRepositoryProvider)
          .addComment(widget.caseItem.id, _commentController.text.trim());
      _commentController.clear();
      ref.invalidate(caseCommentsProvider(widget.caseItem.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(caseCommentsProvider(widget.caseItem.id));
    final caseItem = widget.caseItem;

    return AppScaffold(
      title: 'Case Discussion',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // === Main Case Content ===
                Container(
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
                            radius: 20,
                            backgroundColor: GlassTheme.neonPurple.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              (caseItem.authorName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: GlassTheme.neonPurple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                caseItem.authorName ?? 'Unknown User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Posted on ${_formatDate(caseItem.createdAt)}',
                                style: const TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        caseItem.title,
                        style: GlassTheme.textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      if (caseItem.body != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          caseItem.body!,
                          style: GlassTheme.textTheme.bodyMedium,
                        ),
                      ],
                      if (caseItem.images.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...caseItem.images.map(
                          (img) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(img),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Comments',
                  style: TextStyle(
                    color: GlassTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // === Comments List ===
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No comments yet. Start the discussion!',
                          style: TextStyle(color: GlassTheme.textMuted),
                        ),
                      );
                    }
                    return Column(
                      children: comments
                          .map((c) => _CommentTile(comment: c))
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text(
                    'Error loading comments: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

          // === Comment Input ===
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GlassTheme.cardBackground,
              border: Border(top: BorderSide(color: GlassTheme.glassBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: GlassTheme.textMuted),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isPosting ? null : _postComment,
                  icon: _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          LucideIcons.send,
                          color: GlassTheme.neonCyan,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CommentTile extends StatelessWidget {
  final CaseComment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.authorName ?? 'Unknown',
                style: const TextStyle(
                  color: GlassTheme.neonBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${comment.createdAt.hour}:${comment.createdAt.minute}',
                style: const TextStyle(
                  color: GlassTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment.body, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
