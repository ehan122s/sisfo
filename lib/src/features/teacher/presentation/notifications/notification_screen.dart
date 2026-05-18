import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/notification_repository.dart';
import '../../domain/notification_model.dart';
import '../../../authentication/data/auth_repository.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(teacherNotificationsProvider);
    final user = ref.read(authRepositoryProvider).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Riwayat Aktivitas',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (user != null) {
                ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
              }
            },
            child: Text(
              'Baca Semua',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 52,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada notifikasi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aktivitas siswa akan muncul di sini',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          // Pisahkan belum dibaca dan sudah dibaca
          final unread = notifications.where((n) => !n.isRead).toList();
          final read = notifications.where((n) => n.isRead).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(teacherNotificationsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Belum Dibaca ──────────────────────────────────────────
                if (unread.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Belum Dibaca (${unread.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...unread.map((n) => _NotificationCard(notification: n)),
                  const SizedBox(height: 16),
                ],

                // ── Sudah Dibaca ──────────────────────────────────────────
                if (read.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sudah Dibaca',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...read.map((n) => _NotificationCard(notification: n)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification.isRead;

    // Icon & warna berdasarkan tipe
    IconData iconData;
    Color iconColor;
    switch (notification.type) {
      case 'info':
        iconData = Icons.info_outline_rounded;
        iconColor = const Color(0xFF3B82F6);
        break;
      case 'success':
        iconData = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case 'warning':
      case 'alert':
        iconData = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
      case 'error':
        iconData = Icons.error_outline_rounded;
        iconColor = Colors.red;
        break;
      case 'journal':
        iconData = Icons.book_outlined;
        iconColor = const Color(0xFF8B5CF6);
        break;
      case 'attendance':
        iconData = Icons.location_on_outlined;
        iconColor = const Color(0xFF10B981);
        break;
      default:
        iconData = Icons.notifications_outlined;
        iconColor = const Color(0xFF3B82F6);
    }

    return GestureDetector(
      onTap: () async {
        // Tandai sudah dibaca
        if (!isRead) {
          await ref
              .read(notificationRepositoryProvider)
              .markAsRead(notification.id);
        }
        // Navigasi berdasarkan action_link
        if (notification.actionLink != null &&
            notification.actionLink!.isNotEmpty &&
            context.mounted) {
          context.go(notification.actionLink!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? Colors.grey.withValues(alpha: 0.1)
                : const Color(0xFF3B82F6).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: isRead
                  ? Colors.black.withValues(alpha: 0.03)
                  : const Color(0xFF3B82F6).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Konten
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Dot unread
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        // Arrow jika ada action link
                        if (notification.actionLink != null &&
                            notification.actionLink!.isNotEmpty) ...[
                          const Spacer(),
                          Text(
                            'Lihat →',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: iconColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}
