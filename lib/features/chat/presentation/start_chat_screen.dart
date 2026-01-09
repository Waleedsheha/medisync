import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medisynch/app/glass_theme.dart';
import 'package:medisynch/core/widgets/app_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/chat_repository.dart';
import '../models/chat_models.dart';

class StartChatScreen extends ConsumerStatefulWidget {
  const StartChatScreen({super.key});

  @override
  ConsumerState<StartChatScreen> createState() => _StartChatScreenState();
}

class _StartChatScreenState extends ConsumerState<StartChatScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return AppScaffold(
      title: 'Start Chat',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users…',
                hintStyle: const TextStyle(color: GlassTheme.textMuted),
                filled: true,
                fillColor: GlassTheme.cardBackground,
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: GlassTheme.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<_ProfileUser>>(
              future: _fetchProfiles(currentUserId: currentUserId, query: _query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final users = snapshot.data ?? const [];
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.userX,
                          size: 56,
                          color: GlassTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No users found',
                          style: GlassTheme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try a different name',
                          style: GlassTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserTile(
                      user: user,
                      onTap: () async {
                        final convId = await ref
                            .read(chatRepositoryProvider)
                            .getOrCreateDirectChat(user.id);

                        if (!context.mounted) return;

                        final conversation = ChatConversation(
                          id: convId,
                          name: user.fullName,
                          isGroup: false,
                          createdAt: DateTime.now(),
                        );

                        context.push('/chat/room', extra: conversation);
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

  Future<List<_ProfileUser>> _fetchProfiles({
    required String? currentUserId,
    required String query,
  }) async {
    final client = Supabase.instance.client;

    final q = query.trim();
    final filter = q.isEmpty ? null : q;

    var request = client.from('profiles').select('id, full_name, role');

    if (filter != null) {
      request = request.ilike('full_name', '%$filter%');
    }

    final rows = await request.order('full_name', ascending: true).limit(50);
    final out = (rows as List)
        .map((e) => _ProfileUser.fromJson(e as Map<String, dynamic>))
        .where((u) => currentUserId == null ? true : u.id != currentUserId)
        .toList();

    return out;
  }
}

class _ProfileUser {
  final String id;
  final String fullName;
  final String? role;

  const _ProfileUser({required this.id, required this.fullName, this.role});

  factory _ProfileUser.fromJson(Map<String, dynamic> json) {
    return _ProfileUser(
      id: json['id']?.toString() ?? '',
      fullName: (json['full_name']?.toString().trim().isNotEmpty ?? false)
          ? json['full_name'].toString()
          : 'Unknown',
      role: json['role']?.toString(),
    );
  }
}

class _UserTile extends StatelessWidget {
  final _ProfileUser user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: onTap,
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
              child: Text(
                initials,
                style: const TextStyle(
                  color: GlassTheme.neonBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: GlassTheme.textTheme.titleMedium,
                  ),
                  if (user.role != null && user.role!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.role!,
                      style: const TextStyle(
                        color: GlassTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
