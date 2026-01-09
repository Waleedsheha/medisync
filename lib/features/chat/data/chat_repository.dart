import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository());

class ChatRepository {
  final _supabase = Supabase.instance.client;

  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((maps) => maps.map((e) => ChatMessage.fromJson(e)).toList());
  }

  // Alternative: One-time fetch if stream is too expensive or for initial load
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final response = await _supabase
        .from('messages')
        .select('*, profiles:sender_id(full_name)')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<void> sendMessage(String conversationId, String body) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'body': body,
    });
  }

  Future<List<ChatConversation>> getConversations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // This is a simplified fetch. complex joins are hard in client-side Supabase
    // Ideally we use a View for this. For now, fetch conversations user is in.
    // final data = await _supabase.rpc('get_my_conversations');
    // We would need a postgres function for this or nice chaining.
    // Fallback simple query:

    // 1. Get Conversation IDs
    final members = await _supabase
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', user.id);

    final ids = (members as List).map((e) => e['conversation_id']).toList();
    if (ids.isEmpty) return [];

    // 2. Get Conversations
    final response = await _supabase
        .from('conversations')
        .select()
        .inFilter('id', ids)
        .order('created_at', ascending: false);

    return (response as List).map((e) => ChatConversation.fromJson(e)).toList();
  }

  /// Returns existing direct conversation ID or creates a new one.
  Future<String> getOrCreateDirectChat(String otherUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // 1. Get all direct (non-group) conversations for current user
    final myMemberships = await _supabase
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', user.id);

    final myConvIds = (myMemberships as List)
        .map((e) => e['conversation_id'])
        .toList();

    if (myConvIds.isNotEmpty) {
      // 2. Find conversations where the other user is also a member
      final otherMemberships = await _supabase
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', otherUserId)
          .inFilter('conversation_id', myConvIds);

      final sharedConvIds = (otherMemberships as List)
          .map((e) => e['conversation_id'])
          .toList();

      if (sharedConvIds.isNotEmpty) {
        // 3. Check if any of these is a direct (non-group) chat
        final directConvs = await _supabase
            .from('conversations')
            .select('id')
            .inFilter('id', sharedConvIds)
            .eq('is_group', false)
            .limit(1);

        if ((directConvs as List).isNotEmpty) {
          return directConvs.first['id'] as String;
        }
      }
    }

    // No existing DM found – create one
    return startDirectChat(otherUserId);
  }

  Future<String> startDirectChat(String otherUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // 1. Create conversation
    final conv = await _supabase
        .from('conversations')
        .insert({'is_group': false})
        .select()
        .single();

    final convId = conv['id'];

    // 2. Add members
    await _supabase.from('conversation_members').insert([
      {'conversation_id': convId, 'user_id': user.id},
      {'conversation_id': convId, 'user_id': otherUserId},
    ]);

    return convId;
  }
}
