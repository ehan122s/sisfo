import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common_widgets/skeleton_widget.dart';

import 'dart:ui'; // For ImageFilter

import '../../authentication/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../offline/presentation/sync_status_indicator.dart';
import '../../journal/data/journal_repository.dart';
import 'announcement_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF0F4F8), // Biru sangat muda & kalem
      body: Stack(
        children: [
          // 1. Background Decorations (Ubah ke Biru)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Premium Header with Glassmorphism
                _buildHeader(context, user, profileAsync),

                const SizedBox(height: 16),

                // Announcement Banner
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AnnouncementBanner(),
                ),

                const Spacer(),

                // 3. Center Action Button (Pulse) with Premium Look
                const _PulseCheckInButton(),

                const Spacer(),

                // 4. Status Summary Cards
                _buildStatusSummary(ref),

                const SizedBox(height: 30), // Spacing for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic user,
    AsyncValue<Map<String, dynamic>?> profileAsync,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final placementAsync = ref.watch(studentPlacementProvider);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1976D2), // Biru primer
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFE3F2FD), // Biru muda
                        child: Text(
                          user?.email?.substring(0, 2).toUpperCase() ?? "ST",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1976D2),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          profileAsync.when(
                            data: (profile) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?['full_name'] ?? 'Siswa Magang',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1F2937),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.school_outlined,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            profile?['class_name'] ?? '-',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            loading: () => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonWidget(
                                  width: 120,
                                  height: 20,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SkeletonWidget(
                                  width: 80,
                                  height: 14,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                            error: (e, s) => const Text("User"),
                          ),
                          const SizedBox(height: 8),
                          placementAsync.when(
                            data: (placement) {
                              final companyName =
                                  placement?['companies']?['name'] ??
                                  'Belum Penempatan';
                              return Row(
                                children: [
                                  Icon(
                                    Icons.business_center_outlined,
                                    size: 14,
                                    color: Colors.blue[700], // Biru
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      companyName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.blue[800], // Biru
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (e, s) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const SyncStatusIndicator(),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF1976D2), // Biru
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSummary(WidgetRef ref) {
    final todayLogAsync = ref.watch(todaysAttendanceLogProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: todayLogAsync.when(
                data: (log) {
                  String status = "Belum Absen";
                  Color iconColor = Colors.orange;
                  Color textColor = Colors.black;
                  Color subLabelColor = Colors.grey[500]!;
                  Color? backgroundColor;
                  IconData icon = Icons.access_time_filled_rounded;

                  if (log != null) {
                    if (log['check_out_time'] != null) {
                      status = "Sudah Pulang";
                      iconColor = Colors.white;
                      backgroundColor = Colors.grey[700];
                      textColor = Colors.white;
                      subLabelColor = Colors.white70;
                      icon = Icons.check_circle_outline_rounded;
                    } else {
                      status = log['status'] ?? "Hadir";
                      if (status == 'Terlambat') {
                        status = "Telat";
                        backgroundColor = Colors.orange;
                        iconColor = Colors.white;
                        textColor = Colors.white;
                        subLabelColor = Colors.white.withValues(alpha: 0.8);
                        icon = Icons.warning_amber_rounded;
                      } else {
                        backgroundColor = Colors.blue; // Ubah ke Biru
                        iconColor = Colors.white;
                        textColor = Colors.white;
                        subLabelColor = Colors.white.withValues(alpha: 0.8);
                        icon = Icons.timer_outlined;
                      }
                    }
                  }

                  return _StatusCard(
                    label: "Status Hari Ini",
                    value: status,
                    subLabel: "Masuk: 07.30",
                    icon: icon,
                    iconColor: iconColor,
                    textColor: textColor,
                    subLabelColor: subLabelColor,
                    backgroundColor: backgroundColor,
                  );
                },
                loading: () =>
                    const _StatusCardSkeleton(label: "Status Hari Ini"),
                error: (e, s) => const _StatusCard(
                  label: "Status Hari Ini",
                  value: "Error",
                  subLabel: "Masuk: 07.30",
                  icon: Icons.error,
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  subLabelColor: Colors.red,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: todayLogAsync.when(
                data: (log) {
                  String durationStr = "0 Jam";
                  if (log != null &&
                      log['check_in_time'] != null &&
                      log['check_out_time'] != null) {
                    final start = DateTime.parse(log['check_in_time']);
                    final end = DateTime.parse(log['check_out_time']);
                    final duration = end.difference(start);
                    final hours = duration.inHours;
                    final minutes = duration.inMinutes.remainder(60);
                    durationStr = "${hours}j ${minutes}m";
                  }

                  return _StatusCard(
                    label: "Durasi Kerja",
                    value: durationStr,
                    subLabel: "Target: 8 Jam",
                    icon: Icons.timelapse_rounded,
                    iconColor: Colors.blue,
                    textColor: Colors.black,
                    subLabelColor: Colors.grey[400]!,
                    backgroundColor: Colors.white,
                  );
                },
                loading: () => const _StatusCardSkeleton(label: "Durasi Kerja"),
                error: (e, s) => const _StatusCard(
                  label: "Durasi Kerja",
                  value: "-",
                  subLabel: "Target: 8 Jam",
                  icon: Icons.timelapse,
                  iconColor: Colors.blue,
                  textColor: Colors.black,
                  subLabelColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subLabel;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color subLabelColor;
  final Color? backgroundColor;

  const _StatusCard({
    required this.label,
    required this.value,
    this.subLabel,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.subLabelColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? Colors.black).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor != null
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: subLabelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subLabel != null)
                Text(
                  subLabel!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: subLabelColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseCheckInButton extends ConsumerStatefulWidget {
  const _PulseCheckInButton();

  @override
  ConsumerState<_PulseCheckInButton> createState() =>
      _PulseCheckInButtonState();
}

class _PulseCheckInButtonState extends ConsumerState<_PulseCheckInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayLogAsync = ref.watch(todaysAttendanceLogProvider);
    final journalStatusAsync = ref.watch(todaysJournalStatusProvider);

    return todayLogAsync.when(
      data: (log) {
        bool isCheckedIn = false;
        bool isDone = false;

        if (log != null) {
          if (log['check_out_time'] != null) {
            isDone = true;
          } else {
            isCheckedIn = true;
          }
        }

        if (isDone) {
          _controller.stop();

          return journalStatusAsync.when(
            data: (hasFilledJournal) {
              if (hasFilledJournal) {
                return _buildFinishedState();
              } else {
                return _buildJournalRequiredState(context, ref);
              }
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
        }

        return _buildActiveState(context, isCheckedIn);
      },
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildFinishedState() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3), // Ubah ke Biru
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Selesai",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          Text(
            "Sampai Jumpa Besok!",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalRequiredState(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final result = await context.push('/journal/create');
        if (result == true && mounted) {
          ref.invalidate(todaysJournalStatusProvider);
          ref.invalidate(todaysAttendanceLogProvider);
        }
      },
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Isi Jurnal",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Lengkapi jurnal hari ini",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveState(BuildContext context, bool isCheckedIn) {
    return GestureDetector(
      onTap: () {
        if (isCheckedIn) {
          final now = DateTime.now();
          if (now.hour < 14) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Belum waktunya pulang (Jadwal pulang: 14:00)',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            return;
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceScreen(
              mode: isCheckedIn
                  ? AttendanceMode.checkOut
                  : AttendanceMode.checkIn,
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isCheckedIn
                      ? [const Color(0xFFFF5252), const Color(0xFFC62828)]
                      : [const Color(0xFF42A5F5), const Color(0xFF1565C0)], // Biru Kalem
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCheckedIn ? Colors.red : Colors.blue).withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 30,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 10,
                    blurStyle: BlurStyle.inner,
                    offset: const Offset(-5, -5),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 4,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCheckedIn
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCheckedIn ? "Absen Pulang" : "Absen Masuk",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCheckedIn ? "Waktunya istirahat" : "Semangat berkarya!",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusCardSkeleton extends StatelessWidget {
  final String label;

  const _StatusCardSkeleton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonWidget.circular(width: 32, height: 32),
          const SizedBox(height: 16),
          const SkeletonWidget(
            width: 100,
            height: 24,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}