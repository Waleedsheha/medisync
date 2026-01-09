import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medisynch/app/glass_theme.dart';
import 'package:medisynch/core/widgets/app_scaffold.dart';
import '../models/chat_models.dart';
import '../data/chat_repository.dart';

// Provider for conversation list
final conversationsProvider = FutureProvider<List<ChatConversation>>((
  ref,
) async {
  return ref.watch(chatRepositoryProvider).getConversations();
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return AppScaffold(
      title: 'Messages',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/chat/start');
          ref.invalidate(conversationsProvider);
        },
        backgroundColor: GlassTheme.neonBlue,
        child: const Icon(LucideIcons.messageSquarePlus, color: Colors.white),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.messageCircle,
                    size: 64,
                    color: GlassTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: GlassTheme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a chat with a colleague',
                    style: GlassTheme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(conversationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return _ConversationTile(conversation: conv);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/chat/room', extra: conversation),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GlassTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GlassTheme.glassBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: GlassTheme.neonBlue.withValues(alpha: 0.2),
              child: const Icon(LucideIcons.user, color: GlassTheme.neonBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name ??
                        'Chat ${conversation.id.substring(0, 4)}',
                    style: GlassTheme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to view messages',
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: GlassTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
