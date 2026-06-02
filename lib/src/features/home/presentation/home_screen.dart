import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common_widgets/skeleton_widget.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../attendance/data/attendance_timer_provider.dart';
import '../../offline/presentation/sync_status_indicator.dart';
import '../../journal/data/journal_repository.dart';
import 'announcement_banner.dart';

// ============================================================================
// HOME SCREEN SISWA - PREMIUM GLASS TEACHER THEME
// ============================================================================

class HomeColors {
  static const Color primaryBlue = Color(0xFF1D4ED8);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color iceBlue = Color(0xFF93C5FD);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color background = Color(0xFFF0F5FA);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color glassBorder = Color(0xFFE2E8F0);
}

class HomeFonts {
  static TextStyle get _base => GoogleFonts.plusJakartaSans();

  static TextStyle display({Color? color}) => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color ?? HomeColors.textPrimary,
        letterSpacing: -0.9,
      );

  static TextStyle h1({Color? color}) => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: color ?? HomeColors.textPrimary,
        letterSpacing: -0.6,
      );

  static TextStyle h2({Color? color}) => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color ?? HomeColors.textPrimary,
        letterSpacing: -0.4,
      );

  static TextStyle title({Color? color}) => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color ?? HomeColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle body({Color? color}) => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color ?? HomeColors.textSecondary,
      );

  static TextStyle caption({Color? color}) => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color ?? HomeColors.textMuted,
      );

  static TextStyle label({Color? color}) => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: color ?? HomeColors.textMuted,
        letterSpacing: 0.7,
      );
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
    this.color,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: shadows ??
            [
              BoxShadow(
                color: HomeColors.primaryBlue.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: HomeColors.cyanAccent.withOpacity(0.03),
                blurRadius: 42,
                offset: const Offset(0, 20),
                spreadRadius: -6,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? Colors.white.withOpacity(0.62),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.70),
                width: 1.4,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final profileAsync = ref.watch(userProfileProvider);
    final placementAsync = ref.watch(studentPlacementProvider);

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _PremiumHeader(
                      user: user,
                      profileAsync: profileAsync,
                      placementAsync: placementAsync,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _HeroStudentCard(
                      profileAsync: profileAsync,
                      placementAsync: placementAsync,
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(child: AnnouncementBanner()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(child: _AttendanceActionCard()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  sliver: SliverToBoxAdapter(child: _TodayStatusSection()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                  sliver: SliverToBoxAdapter(child: _QuickAccessSection()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                  sliver: SliverToBoxAdapter(child: _MotivationCard()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -110,
          left: -90,
          child: _BlurBlob(
            size: 340,
            color: HomeColors.cyanAccent.withOpacity(0.18),
            blur: 90,
          ),
        ),
        Positioned(
          top: 140,
          right: -120,
          child: _BlurBlob(
            size: 330,
            color: HomeColors.primaryBlue.withOpacity(0.12),
            blur: 85,
          ),
        ),
        Positioned(
          bottom: 80,
          left: -80,
          child: _BlurBlob(
            size: 280,
            color: HomeColors.lightBlue.withOpacity(0.12),
            blur: 75,
          ),
        ),
      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final double size;
  final double blur;
  final Color color;

  const _BlurBlob({
    required this.size,
    required this.blur,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _PremiumHeader extends ConsumerWidget {
  final dynamic user;
  final AsyncValue<Map<String, dynamic>?> profileAsync;
  final AsyncValue<Map<String, dynamic>?> placementAsync;

  const _PremiumHeader({
    required this.user,
    required this.profileAsync,
    required this.placementAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 24,
      color: Colors.white.withOpacity(0.58),
      child: Row(
        children: [
          profileAsync.when(
            data: (profile) => _Avatar(
              text: _initial(profile?['full_name'] ?? user?.email ?? 'S'),
            ),
            loading: () => const SkeletonWidget.circular(width: 52, height: 52),
            error: (_, __) => const _Avatar(text: 'S'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SISWA PKL',
                  style: HomeFonts.label(color: HomeColors.primaryBlue),
                ),
                const SizedBox(height: 3),
                profileAsync.when(
                  data: (profile) => Text(
                    profile?['full_name'] ?? 'Siswa Magang',
                    style: HomeFonts.title(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  loading: () => const SkeletonWidget(
                    width: 130,
                    height: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                  ),
                  error: (_, __) => Text('Siswa Magang', style: HomeFonts.title()),
                ),
                const SizedBox(height: 4),
                placementAsync.when(
                  data: (placement) => Row(
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        size: 13,
                        color: HomeColors.cyanAccent,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          placement?['companies']?['name'] ?? 'Belum Penempatan',
                          style: HomeFonts.caption(color: HomeColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(height: 14),
                  error: (_, __) => const SizedBox(height: 14),
                ),
              ],
            ),
          ),
          const SyncStatusIndicator(),
          const SizedBox(width: 8),
          _HeaderIcon(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String text;
  const _Avatar({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [HomeColors.lightBlue, HomeColors.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: HomeColors.background,
          child: Text(
            text,
            style: HomeFonts.h2(color: HomeColors.primaryBlue).copyWith(
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HomeColors.glassBorder.withOpacity(0.7)),
          ),
          child: Icon(icon, size: 20, color: HomeColors.primaryBlue),
        ),
      ),
    );
  }
}

class _HeroStudentCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> profileAsync;
  final AsyncValue<Map<String, dynamic>?> placementAsync;

  const _HeroStudentCard({
    required this.profileAsync,
    required this.placementAsync,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String get _dateText {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final now = DateTime.now();
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), HomeColors.primaryBlue, HomeColors.cyanAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: HomeColors.primaryBlue.withOpacity(0.28),
            blurRadius: 34,
            offset: const Offset(0, 18),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -48,
            right: -40,
            child: _DecorCircle(size: 150, opacity: 0.08),
          ),
          Positioned(
            bottom: -58,
            right: 58,
            child: _DecorCircle(size: 110, opacity: 0.06),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroChip(icon: Icons.calendar_today_rounded, text: _dateText),
              const SizedBox(height: 18),
              Text(
                '$_greeting! 👋',
                style: HomeFonts.display(color: Colors.white),
              ),
              const SizedBox(height: 8),
              profileAsync.when(
                data: (profile) => Text(
                  'Kelas ${profile?['class_name'] ?? '-'}  •  ${profile?['nisn'] ?? '-'}',
                  style: HomeFonts.body(color: Colors.white.withOpacity(0.78)),
                ),
                loading: () => Text(
                  'Memuat profil siswa...',
                  style: HomeFonts.body(color: Colors.white70),
                ),
                error: (_, __) => Text(
                  'Profil belum lengkap',
                  style: HomeFonts.body(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 18),
              placementAsync.when(
                data: (placement) => _PlacementPill(
                  title: placement?['companies']?['name'] ?? 'Belum ada tempat PKL',
                  subtitle: 'Tempat PKL aktif',
                ),
                loading: () => const SizedBox(height: 52),
                error: (_, __) => const _PlacementPill(
                  title: 'Belum ada tempat PKL',
                  subtitle: 'Tempat PKL aktif',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorCircle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withOpacity(0.82)),
          const SizedBox(width: 7),
          Text(text, style: HomeFonts.caption(color: Colors.white.withOpacity(0.82))),
        ],
      ),
    );
  }
}

class _PlacementPill extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PlacementPill({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle.toUpperCase(),
                  style: HomeFonts.label(color: Colors.white.withOpacity(0.62)),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: HomeFonts.title(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceActionCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AttendanceActionCard> createState() => _AttendanceActionCardState();
}

class _AttendanceActionCardState extends ConsumerState<_AttendanceActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1, end: 1.018).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayLogAsync = ref.watch(todaysAttendanceLogProvider);
    final journalAsync = ref.watch(todaysJournalStatusProvider);

    return todayLogAsync.when(
      data: (log) {
        final isDone = log?['check_out_time'] != null;
        final isCheckedIn = log != null && !isDone;

        if (isDone) {
          _controller.stop();
          return journalAsync.when(
            data: (filled) => filled ? _FinishedCard() : _JournalReminderCard(),
            loading: () => const _ActionLoadingCard(),
            error: (_, __) => _FinishedCard(),
          );
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: _CheckButtonCard(
            isCheckedIn: isCheckedIn,
            onTap: () => _handleAttendanceTap(context, isCheckedIn),
          ),
        );
      },
      loading: () => const _ActionLoadingCard(),
      error: (error, _) => GlassCard(
        child: Text('Gagal memuat absensi: $error', style: HomeFonts.body()),
      ),
    );
  }

  void _handleAttendanceTap(BuildContext context, bool isCheckedIn) {
    if (isCheckedIn && DateTime.now().hour < 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Belum waktunya pulang (jadwal: 14:00)',
            style: HomeFonts.body(color: Colors.white),
          ),
          backgroundColor: HomeColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceScreen(
          mode: isCheckedIn ? AttendanceMode.checkOut : AttendanceMode.checkIn,
        ),
      ),
    );
  }
}

class _CheckButtonCard extends StatelessWidget {
  final bool isCheckedIn;
  final VoidCallback onTap;

  const _CheckButtonCard({
    required this.isCheckedIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = isCheckedIn
        ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
        : [HomeColors.cyanAccent, HomeColors.primaryBlue];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isCheckedIn ? HomeColors.danger : HomeColors.primaryBlue)
                  .withOpacity(0.30),
              blurRadius: 32,
              offset: const Offset(0, 16),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Icon(
                isCheckedIn ? Icons.logout_rounded : Icons.login_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCheckedIn ? 'Absen Pulang' : 'Absen Masuk',
                    style: HomeFonts.h1(color: Colors.white).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCheckedIn
                        ? 'Selesaikan aktivitas PKL hari ini'
                        : 'Mulai aktivitas PKL dengan semangat',
                    style: HomeFonts.body(color: Colors.white.withOpacity(0.78)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withOpacity(0.82),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      radius: 30,
      color: Colors.white.withOpacity(0.70),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: HomeColors.emerald.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.check_circle_rounded, color: HomeColors.emerald, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selesai Hari Ini', style: HomeFonts.h2()),
                const SizedBox(height: 4),
                Text(
                  'Absensi sudah lengkap. Jangan lupa isi jurnal jika belum.',
                  style: HomeFonts.body(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalReminderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/journal/create'),
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        radius: 30,
        color: Colors.white.withOpacity(0.72),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: HomeColors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.edit_note_rounded, color: HomeColors.amber, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Isi Jurnal Harian', style: HomeFonts.h2()),
                  const SizedBox(height: 4),
                  Text(
                    'Absensi selesai. Lengkapi laporan kegiatan hari ini.',
                    style: HomeFonts.body(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: HomeColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ActionLoadingCard extends StatelessWidget {
  const _ActionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 30,
      child: const SizedBox(
        height: 76,
        child: Center(
          child: CircularProgressIndicator(
            color: HomeColors.primaryBlue,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _TodayStatusSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayLogAsync = ref.watch(todaysAttendanceLogProvider);
    final timerState = ref.watch(attendanceTimerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Status Hari Ini',
          subtitle: 'Ringkasan absensi dan durasi PKL',
        ),
        const SizedBox(height: 14),
        todayLogAsync.when(
          data: (log) {
            final statusInfo = _statusInfo(log);
            final duration = _durationText(log, timerState, ref);

            return Row(
              children: [
                Expanded(
                  child: _ModernStatCard(
                    label: 'Status',
                    value: statusInfo.title,
                    sub: statusInfo.subtitle,
                    icon: statusInfo.icon,
                    color: statusInfo.color,
                    highlighted: log != null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ModernStatCard(
                    label: 'Durasi',
                    value: duration,
                    sub: 'Target: 8 Jam',
                    icon: Icons.timelapse_rounded,
                    color: HomeColors.primaryBlue,
                  ),
                ),
              ],
            );
          },
          loading: () => Row(
            children: const [
              Expanded(child: _StatSkeleton()),
              SizedBox(width: 14),
              Expanded(child: _StatSkeleton()),
            ],
          ),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  _StatusInfo _statusInfo(Map<String, dynamic>? log) {
    if (log == null) {
      return const _StatusInfo(
        title: 'Belum Absen',
        subtitle: 'Jadwal: 07.30',
        icon: Icons.access_time_rounded,
        color: HomeColors.lightBlue,
      );
    }

    if (log['check_out_time'] != null) {
      return const _StatusInfo(
        title: 'Sudah Pulang',
        subtitle: 'Aktivitas selesai',
        icon: Icons.task_alt_rounded,
        color: HomeColors.emerald,
      );
    }

    if ((log['status'] ?? '') == 'Terlambat') {
      return const _StatusInfo(
        title: 'Terlambat',
        subtitle: 'Harap tepat waktu',
        icon: Icons.warning_amber_rounded,
        color: HomeColors.amber,
      );
    }

    return const _StatusInfo(
      title: 'Hadir',
      subtitle: 'Semangat berkarya',
      icon: Icons.verified_rounded,
      color: HomeColors.cyanAccent,
    );
  }

  String _durationText(
    Map<String, dynamic>? log,
    dynamic timerState,
    WidgetRef ref,
  ) {
    if (log?['check_in_time'] != null && log?['check_out_time'] != null) {
      final start = DateTime.parse(log!['check_in_time']);
      final end = DateTime.parse(log['check_out_time']);
      final duration = end.difference(start);
      return '${duration.inHours}j ${duration.inMinutes.remainder(60)}m';
    }

    if (log?['check_in_time'] != null) {
      if (!timerState.isRunning) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(attendanceTimerProvider.notifier).start(
                DateTime.parse(log!['check_in_time']),
              );
        });
      }

      final elapsed = timerState.elapsed;
      return '${elapsed.inHours}j ${elapsed.inMinutes.remainder(60)}m';
    }

    return '0j 0m';
  }
}

class _StatusInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatusInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _ModernStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final bool highlighted;

  const _ModernStatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      color: highlighted ? color.withOpacity(0.92) : Colors.white.withOpacity(0.68),
      borderColor: highlighted ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.75),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: highlighted ? Colors.white.withOpacity(0.18) : color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: highlighted ? Colors.white : color, size: 21),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: HomeFonts.h2(color: highlighted ? Colors.white : HomeColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: HomeFonts.label(
              color: highlighted ? Colors.white.withOpacity(0.70) : HomeColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: HomeFonts.caption(
              color: highlighted ? Colors.white.withOpacity(0.72) : HomeColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonWidget.circular(width: 42, height: 42),
          SizedBox(height: 14),
          SkeletonWidget(
            width: 90,
            height: 18,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
          SizedBox(height: 8),
          SkeletonWidget(
            width: 70,
            height: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAccessItem(
        icon: Icons.fingerprint_rounded,
        title: 'Absensi',
        subtitle: 'Riwayat absen',
        color: HomeColors.primaryBlue,
        onTap: () => context.go('/attendance'),
      ),
      _QuickAccessItem(
        icon: Icons.book_rounded,
        title: 'Jurnal',
        subtitle: 'Catatan harian',
        color: HomeColors.cyanAccent,
        onTap: () => context.go('/journal'),
      ),
      _QuickAccessItem(
        icon: Icons.edit_note_rounded,
        title: 'Buat Jurnal',
        subtitle: 'Isi laporan',
        color: HomeColors.amber,
        onTap: () => context.push('/journal/create'),
      ),
      _QuickAccessItem(
        icon: Icons.person_rounded,
        title: 'Profil',
        subtitle: 'Data siswa',
        color: HomeColors.lightBlue,
        onTap: () => context.go('/profile'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Akses Cepat',
          subtitle: 'Menu utama untuk aktivitas PKL',
        ),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.16,
          ),
          itemBuilder: (context, index) => items[index],
        ),
      ],
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        radius: 24,
        child: Stack(
          children: [
            Positioned(
              bottom: -34,
              right: -28,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: HomeFonts.title(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: HomeColors.textMuted.withOpacity(0.65),
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: HomeFonts.caption(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      radius: 26,
      color: Colors.white.withOpacity(0.68),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [HomeColors.cyanAccent, HomeColors.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tetap Produktif', style: HomeFonts.title()),
                const SizedBox(height: 3),
                Text(
                  'Lengkapi absensi dan jurnal setiap hari agar laporan PKL selalu rapi.',
                  style: HomeFonts.body(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [HomeColors.cyanAccent, HomeColors.primaryBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HomeFonts.h2()),
              const SizedBox(height: 2),
              Text(subtitle, style: HomeFonts.caption()),
            ],
          ),
        ),
      ],
    );
  }
}

String _initial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'S';
  return trimmed.substring(0, 1).toUpperCase();
}
