import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notification_model.dart';
import '../../authentication/data/auth_repository.dart';

final notificationRepositoryProvider = Provider((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final teacherNotificationsProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) return const Stream.empty();

      return ref
          .watch(notificationRepositoryProvider)
          .getNotificationsStream(user.id);
    });

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository(this._supabase);

  // Fetch notifications with Realtime subscription
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map(
          (data) => data
              .map((json) => NotificationModel.fromJson(json))
              .toList()
              .reversed
              .toList(),
        ); // Initial load order descending
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}
