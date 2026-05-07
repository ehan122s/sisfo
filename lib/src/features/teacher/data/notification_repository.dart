// lib/features/teacher/data/notification_repository.dart
//
// Terhubung ke tabel: notifications
// Kolom: id, user_id, title, message, type, is_read, action_link, created_at

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';
import '../../authentication/data/auth_repository.dart';

/// Model notifikasi
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'alert' | 'info' | 'success' | 'warning'
  final bool isRead;
  final String? actionLink;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.actionLink,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String? ?? 'info',
      isRead: map['is_read'] as bool? ?? false,
      actionLink: map['action_link'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      actionLink: actionLink,
      createdAt: createdAt,
    );
  }
}

class NotificationRepository {
  /// Ambil semua notifikasi milik user tertentu (terbaru dulu)
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return data
        .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Tandai satu notifikasi sebagai sudah dibaca
  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
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

  /// Realtime stream notifikasi (opsional — untuk badge live update)
  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .map((e) => NotificationModel.fromMap(e))
              .toList(),
        );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Provider notifikasi guru — dipakai di badge icon dashboard
/// ref.watch(teacherNotificationsProvider)
final teacherNotificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();

  return ref
      .read(notificationRepositoryProvider)
      .notificationsStream(user.id);
});