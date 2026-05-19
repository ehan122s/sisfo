// lib/src/features/teacher/data/notification_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/notification_model.dart'; // Model sudah ada di domain, pakai dari sini

class NotificationRepository {
  /// Ambil semua notifikasi milik user (terbaru dulu)
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return data
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Tandai satu notifikasi sebagai sudah dibaca
  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  /// Tandai semua notifikasi user sebagai sudah dibaca
  Future<void> markAllAsRead(String userId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Hapus notifikasi tertentu
  Future<void> deleteNotification(String notificationId) async {
    await supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }

  /// Realtime stream notifikasi untuk badge live update
  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .map((e) => NotificationModel.fromJson(e))
              .toList(),
        );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Provider notifikasi guru — realtime stream untuk badge & notification screen
/// Dipakai sebagai: ref.watch(teacherNotificationsProvider)
final teacherNotificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();

  return ref
      .read(notificationRepositoryProvider)
      .notificationsStream(user.id);
});