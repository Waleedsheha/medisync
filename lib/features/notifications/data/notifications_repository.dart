import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

final notificationsRepositoryProvider = Provider(
  (ref) => NotificationsRepository(),
);

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).getUnreadCountStream();
});

class NotificationsRepository {
  final _supabase = Supabase.instance.client;

  Future<List<NotificationItem>> getNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((e) => NotificationItem.fromJson(e)).toList();
  }

  Stream<List<NotificationItem>> watchNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((e) => NotificationItem.fromJson(e)).toList());
  }

  Stream<int> getUnreadCountStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(0);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) => data.where((e) => e['read'] == false).length);
  }

  Future<void> markAsRead(String id) async {
    await _supabase.from('notifications').update({'read': true}).eq('id', id);
  }

  Future<void> markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('user_id', user.id);
  }
}
