import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/excel_service.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../data/notification_repository.dart';
import '../data/teacher_repository.dart';

// =========================================================================
// ── PREMIUM GLASSMORPHIC BLUE COLOR PALETTE ──
// =========================================================================
class AppColors {
  // Pure Premium Blue & Cyan Tones
  static const Color primaryBlue = Color(0xFF1D4ED8); // Royal Blue
  static const Color accentBlue = Color(0xFF2563EB); // Electric Blue
  static const Color lightBlue = Color(0xFF60A5FA); // Sky Blue
  static const Color iceBlue = Color(0xFF93C5FD); // Ice Blue/Glass
  static const Color cyanAccent = Color(0xFF06B6D4); // Vivid Cyan

  // System States (Adjusted for blue harmony)
  static const Color successEmerald = Color(0xFF10B981); // Mint Green
  static const Color alertAmber = Color(0xFFF59E0B); // Amber Orange

  // Backdrop & Glass Specifications
  static const Color background = Color(0xFFF0F5FA); // Soft Ice-Blue Tint
  static const Color surface = Colors.white;
  static const Color glassBorder = Color(0xFFE2E8F0);

  // Premium Dark Slate for Typography
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF334155); // Slate 700
  static const Color textMuted = Color(0xFF64748B); // Slate 500
}

// =========================================================================
// ── TYPOGRAPHY CONFIGURATIONS ──
// =========================================================================
class AppFonts {
  static TextStyle get _base => GoogleFonts.plusJakartaSans();

  static TextStyle displayLarge({Color? color}) => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.textPrimary,
        letterSpacing: -1.0,
      );

  static TextStyle headlineLarge({Color? color}) => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        letterSpacing: -0.6,
      );

  static TextStyle headlineMedium({Color? color}) => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        letterSpacing: -0.4,
      );

  static TextStyle titleLarge({Color? color}) => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle bodyLarge({Color? color}) => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textSecondary,
        letterSpacing: -0.1,
      );

  static TextStyle bodyMedium({Color? color}) => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textMuted,
        letterSpacing: 0,
      );

  static TextStyle labelSmall({Color? color}) => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textMuted,
        letterSpacing: 0.5,
      );
}

// =========================================================================
// ── TRUE GLASSMORPHISM CARD (with real BackdropFilter) ──
// =========================================================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final List<BoxShadow>? customShadow;
  final Color? borderColor;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.customShadow,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: customShadow ??
            [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.cyanAccent.withValues(alpha: 0.02),
                blurRadius: 32,
                offset: const Offset(0, 16),
                spreadRadius: -4,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// ── MAIN SCREEN (ConsumerStatefulWidget) ──
// =========================================================================
class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  int _currentIndex = 0;

  static const List<String> _tabRoutes = [
    '/teacher/dashboard',
    '/teacher/dashboard/attendance',
    '/teacher/dashboard/journals',
    '/teacher/dashboard/assessment',
    '/teacher/dashboard/reports',
  ];

  // List of all modules (8 modules) with premium blue palettes
  List<_MenuItem> _getMenuItems() {
    return [
      _MenuItem(
        icon: Icons.analytics_outlined,
        label: 'Dashboard',
        description: 'Statistik real-time',
        color: AppColors.primaryBlue,
        route: '/teacher/dashboard',
      ),
      _MenuItem(
        icon: Icons.groups_outlined,
        label: 'Siswa',
        description: 'Manajemen data & profil',
        color: AppColors.lightBlue,
        route: '/teacher/dashboard/students',
      ),
      _MenuItem(
        icon: Icons.business_outlined,
        label: 'Tempat PKL',
        description: 'Daftar mitra industri',
        color: AppColors.cyanAccent,
        route: '/teacher/dashboard/placements',
      ),
      _MenuItem(
        icon: Icons.fingerprint_outlined,
        label: 'Absensi',
        description: 'Rekap harian absensi',
        color: AppColors.successEmerald,
        route: '/teacher/dashboard/attendance',
      ),
      _MenuItem(
        icon: Icons.book_outlined,
        label: 'Jurnal Harian',
        description: 'Validasi laporan kegiatan',
        color: AppColors.accentBlue,
        route: '/teacher/dashboard/journals',
      ),
      _MenuItem(
        icon: Icons.supervised_user_circle_outlined,
        label: 'Monitoring',
        description: 'Agenda kunjungan lapangan',
        color: AppColors.lightBlue,
        route: '/teacher/dashboard/monitoring',
      ),
      _MenuItem(
        icon: Icons.star_border_rounded,
        label: 'Penilaian',
        description: 'Evaluasi & sertifikasi',
        color: AppColors.alertAmber,
        route: '/teacher/dashboard/assessment',
      ),
      _MenuItem(
        icon: Icons.description_outlined,
        label: 'Laporan',
        description: 'Ekspor dokumen resmi',
        color: AppColors.textMuted,
        route: '/teacher/dashboard/reports',
      ),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    context.go(_tabRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          // ── Ambient Background Blur Lights (Cyan & Ice Blue) ──
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyanAccent.withValues(alpha: 0.18),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lightBlue.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // ── Scrollable Body Content ──
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildLuxuryAppBar(context, ref, profileAsync),
                  const SizedBox(height: 32),
                  _buildGreetingHeader(),
                  const SizedBox(height: 24),
                  _buildLuxuryStatsRow(statsAsync),
                  const SizedBox(height: 36),
                  _buildMenuSectionHeader(context),
                  const SizedBox(height: 16),
                  _buildLuxuryMenuGrid(context),
                  const SizedBox(height: 120), // Padding space for dock
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPremiumFloatingDock(),
    );
  }

  // ═══════════════════════════════════════════
  // ── PREMIUM GLASS APP BAR
  // ═══════════════════════════════════════════
  Widget _buildLuxuryAppBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>?> profileAsync,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      borderColor: Colors.white.withValues(alpha: 0.7),
      backgroundColor: Colors.white.withValues(alpha: 0.5),
      child: Row(
        children: [
          profileAsync.when(
            data: (profile) => Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.lightBlue, AppColors.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.background,
                  child: Text(
                    profile?['full_name']?.substring(0, 1).toUpperCase() ?? 'G',
                    style: AppFonts.headlineLarge(color: AppColors.primaryBlue)
                        .copyWith(fontSize: 18),
                  ),
                ),
              ),
            ),
            loading: () => const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.glassBorder,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            error: (error, stackTrace) => const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.background,
              child: Icon(Icons.person, color: AppColors.primaryBlue),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: profileAsync.when(
              data: (profile) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Selamat Datang,'.toUpperCase(),
                        style: AppFonts.labelSmall(color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_user,
                        color: AppColors.primaryBlue,
                        size: 10,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile?['full_name'] ?? 'Guru Pembimbing',
                    style: AppFonts.titleLarge(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              loading: () => _buildAppSkeleton(),
              error: (error, stackTrace) => _buildAppSkeleton(),
            ),
          ),
          _buildAppBarActionIcon(
            icon: Icons.notifications_none_rounded,
            badge: true,
            color: Colors.white.withValues(alpha: 0.5),
            onTap: () => context.go('/teacher/dashboard/notifications'),
          ),
          const SizedBox(width: 8),
          _buildAppBarActionIcon(
            icon: Icons.download_outlined,
            color: Colors.white.withValues(alpha: 0.5),
            iconColor: AppColors.primaryBlue,
            onTap: () => _handleExport(context, ref),
          ),
          const SizedBox(width: 8),
          // ── LOGOUT BUTTON (GAMBAR PINTU TERBUKA) ──
          _buildAppBarActionIcon(
            icon: Icons.logout_rounded, // Pintu terbuka
            color: const Color(0xFFFEF2F2), // Merah transparan halus
            iconColor: const Color(0xFFEF4444), // Ikon merah tegas
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
    Color? color,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.glassBorder.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.textPrimary,
              ),
              if (badge)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final asyncValue =
                          ref.watch(teacherNotificationsProvider);
                      final count = asyncValue.value
                              ?.where((n) => !n.isRead)
                              .length ??
                          0;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: AppFonts.labelSmall(color: Colors.white)
                              .copyWith(fontSize: 8, letterSpacing: 0),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.glassBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 140,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.glassBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Hari Ini',
          style: AppFonts.displayLarge(),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.successEmerald,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Memantau aktivitas siswa PKL aktif Anda',
              style: AppFonts.bodyLarge(),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // ── LUXURY INTERACTIVE STATS ROW
  // ═══════════════════════════════════════════
  Widget _buildLuxuryStatsRow(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: _PremiumKPIStatCard(
              title: 'Total Siswa',
              value: stats['total_students'].toString(),
              subtitle: 'Terdaftar PKL',
              accentColor: AppColors.primaryBlue,
              icon: Icons.people_outline_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PremiumKPIStatCard(
              title: 'Hadir',
              value: stats['present_today'].toString(),
              subtitle: 'Siswa Hari Ini',
              accentColor: AppColors.cyanAccent,
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PremiumKPIStatCard(
              title: 'Review',
              value: stats['pending_journals'].toString(),
              subtitle: 'Menunggu Jurnal',
              accentColor: AppColors.alertAmber,
              icon: Icons.hourglass_empty_rounded,
            ),
          ),
        ],
      ),
      loading: () => Container(
        height: 110,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryBlue,
        ),
      ),
      error: (error, stackTrace) => Container(
        height: 110,
        alignment: Alignment.center,
        child: Text(
          'Gagal sinkronisasi data.',
          style: AppFonts.bodyLarge(),
        ),
      ),
    );
  }

  Widget _buildMenuSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Menu Utama',
          style: AppFonts.headlineMedium(),
        ),
        TextButton.icon(
          onPressed: () => _showAllModulesSheet(context),
          icon: const Icon(
            Icons.grid_view_rounded,
            size: 14,
            color: AppColors.primaryBlue,
          ),
          label: Text(
            'Lihat Semua',
            style: AppFonts.bodyLarge(color: AppColors.primaryBlue).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // ── LUXURY MENU GRID
  // ═══════════════════════════════════════════
  Widget _buildLuxuryMenuGrid(BuildContext context) {
    final Map<int, List<dynamic>> homeModules = {
      0: [
        Icons.location_on_outlined,
        'Monitoring Absensi',
        'Pantau lokasi & waktu',
        AppColors.primaryBlue,
        '/teacher/dashboard/attendance'
      ],
      1: [
        Icons.book_outlined,
        'Laporan Jurnal',
        'Validasi kegiatan siswa',
        AppColors.cyanAccent,
        '/teacher/dashboard/journals'
      ],
      2: [
        Icons.groups_outlined,
        'Data Siswa',
        'Profil & status PKL',
        AppColors.lightBlue,
        '/teacher/dashboard/students'
      ],
      3: [
        Icons.history_edu_outlined,
        'Riwayat Aktivitas',
        'Log notifikasi & kejadian',
        AppColors.accentBlue,
        '/teacher/dashboard/notifications'
      ],
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.12,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final item = homeModules[index]!;
        final Color itemColor = item[3] as Color;
        return GestureDetector(
          onTap: () => context.go(item[4] as String),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 24,
            child: Stack(
              children: [
                Positioned(
                  bottom: -20,
                  right: -20,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: itemColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: itemColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item[0] as IconData,
                        size: 22,
                        color: itemColor,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item[1] as String,
                                style: AppFonts.titleLarge(
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.arrow_outward_rounded,
                              size: 14,
                              color: AppColors.textMuted.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item[2] as String,
                          style: AppFonts.bodyMedium(),
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
      },
    );
  }

  // ═══════════════════════════════════════════
  // ── EXPORT REPORT PRODUCER (COMPRESSED DIALOG)
  // ═══════════════════════════════════════════
  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    List<Map<String, dynamic>> studentList = [];
    try {
      studentList = await ref
          .read(teacherRepositoryProvider)
          .getStudentList(user.id);
    } catch (_) {}

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => _ExportDialog(
        studentList: studentList,
        teacherName:
            ref.read(userProfileProvider).value?['full_name'] ?? 'Guru',
        onExport: (month, year, studentId, format) async {
          Navigator.of(ctx).pop();
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mengompilasi berkas laporan...',
                style: AppFonts.bodyLarge(color: Colors.white),
              ),
              backgroundColor: AppColors.primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );

          try {
            final repo = ref.read(teacherRepositoryProvider);
            final teacherName =
                ref.read(userProfileProvider).value?['full_name'] ?? 'Guru';

            final attendanceData = await repo.getAttendanceReportForExport(
              user.id,
              month: month,
              year: year,
              studentId: studentId,
            );
            final journalData = await repo.getJournalReportForExport(
              user.id,
              month: month,
              year: year,
              studentId: studentId,
            );

            if (format == 'excel') {
              await ExcelService().generateFullReport(
                attendanceData: attendanceData,
                journalData: journalData,
                teacherName: teacherName,
                month: month,
                year: year,
              );
            } else {
              await ExcelService().generatePdfReport(
                attendanceData: attendanceData,
                journalData: journalData,
                teacherName: teacherName,
                month: month,
                year: year,
              );
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Laporan berhasil diunduh!',
                    style: AppFonts.bodyLarge(color: Colors.white),
                  ),
                  backgroundColor: AppColors.successEmerald,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Gagal ekspor: $e',
                    style: AppFonts.bodyLarge(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ── FROSTED GLASS FLOATING NAVIGATION DOCK
  // ═══════════════════════════════════════════
  Widget _buildPremiumFloatingDock() {
    return Container(
      margin: const EdgeInsets.only(left: 18, right: 18, bottom: 24),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 36,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.cyanAccent.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDockItem(
                  0,
                  Icons.dashboard_outlined,
                  Icons.dashboard_rounded,
                  'Home',
                ),
                _buildDockItem(
                  1,
                  Icons.fingerprint_outlined,
                  Icons.fingerprint_rounded,
                  'Absen',
                ),
                _buildLuxuryDockActionButton(),
                _buildDockItem(
                  2,
                  Icons.book_outlined,
                  Icons.book_rounded,
                  'Jurnal',
                ),
                _buildDockItem(
                  3,
                  Icons.star_border_rounded,
                  Icons.star_rounded,
                  'Nilai',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(
    int index,
    IconData outline,
    IconData filled,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue.withValues(alpha: 0.08)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? filled : outline,
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppFonts.labelSmall(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.6),
              ).copyWith(
                fontSize: 8,
                letterSpacing: 0,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryDockActionButton() {
    return GestureDetector(
      onTap: () => _showQuickActionSheet(context),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.cyanAccent, AppColors.primaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ── MODAL BOTTOM SHEET: ALL 8 ACTIVE MODULES
  // ═══════════════════════════════════════════
  void _showAllModulesSheet(BuildContext context) {
    final allItems = _getMenuItems();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seluruh Modul PKL',
                        style: AppFonts.headlineLarge(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih aplikasi untuk mengelola administrasi siswa',
                        style: AppFonts.bodyLarge(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: allItems.length,
                    itemBuilder: (context, index) {
                      final item = allItems[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.go(item.route);
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          borderRadius: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 22,
                                  color: item.color,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: AppFonts.titleLarge(
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_outward_rounded,
                                        size: 14,
                                        color: AppColors.textMuted
                                            .withValues(alpha: 0.7),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: AppFonts.bodyMedium(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ── QUICK ACTION MODAL SHEET
  // ═══════════════════════════════════════════
  void _showQuickActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Premium slate gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Aksi Cepat Eksekutif',
                  style: AppFonts.headlineLarge(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola administrasi PKL secara instan',
                  style: AppFonts.bodyLarge(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                _QuickActionTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Tambah Data Siswa',
                  subtitle: 'Pendaftaran peserta PKL baru',
                  color: AppColors.lightBlue,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/teacher/dashboard/students/add');
                  },
                ),
                const SizedBox(height: 12),
                _QuickActionTile(
                  icon: Icons.add_business_outlined,
                  title: 'Tambah Tempat PKL',
                  subtitle: 'Registrasi kemitraan industri',
                  color: AppColors.cyanAccent,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/teacher/dashboard/placements/add');
                  },
                ),
                const SizedBox(height: 12),
                _QuickActionTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Buat Penilaian',
                  subtitle: 'Input standar sertifikasi kompetensi',
                  color: AppColors.successEmerald,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/teacher/dashboard/assessment/add');
                  },
                ),
                const SizedBox(height: 12),
                _QuickActionTile(
                  icon: Icons.cloud_download_outlined,
                  title: 'Ekspor Dokumen Laporan',
                  subtitle: 'Unduh rekapitulasi data lengkap (.xlsx / .pdf)',
                  color: AppColors.iceBlue,
                  onTap: () {
                    Navigator.pop(context);
                    _handleExport(context, ref);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// ── HELPER SUB-COMPONENTS ──
// =========================================================================

class _PremiumKPIStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  const _PremiumKPIStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      borderRadius: 24,
      borderColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppFonts.headlineLarge(color: AppColors.textPrimary).copyWith(
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppFonts.titleLarge().copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppFonts.bodyMedium(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final String route;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.route,
  });
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.titleLarge(color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppFonts.bodyMedium(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// ── EXPORT FLOW - DIALOG COMPONENTS ──
// =========================================================================

class _ExportDialog extends StatefulWidget {
  final List<Map<String, dynamic>> studentList;
  final String teacherName;
  final void Function(int month, int year, String? studentId, String format)
      onExport;

  const _ExportDialog({
    required this.studentList,
    required this.teacherName,
    required this.onExport,
  });

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedStudentId;
  String _format = 'excel';

  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final years = List.generate(3, (i) => DateTime.now().year - i);

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.download_outlined,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Export Laporan',
            style: AppFonts.headlineMedium(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Periode Laporan',
              style: AppFonts.titleLarge(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    dropdownColor: Colors.white,
                    decoration: _inputDecoration('Bulan'),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          _months[i],
                          style: AppFonts.bodyLarge(),
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(() => _selectedMonth = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    dropdownColor: Colors.white,
                    decoration: _inputDecoration('Tahun'),
                    items: years
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text(
                              '$y',
                              style: AppFonts.bodyLarge(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedYear = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Siswa Terdaftar',
              style: AppFonts.titleLarge(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: _selectedStudentId,
              dropdownColor: Colors.white,
              decoration: _inputDecoration('Pilih Siswa'),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    'Semua Siswa',
                    style: AppFonts.bodyLarge(),
                  ),
                ),
                ...widget.studentList.map(
                  (s) => DropdownMenuItem(
                    value: s['student_id'] as String?,
                    child: Text(
                      s['full_name'] ?? '-',
                      style: AppFonts.bodyLarge(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedStudentId = v),
            ),
            const SizedBox(height: 18),
            Text(
              'Format Berkas',
              style: AppFonts.titleLarge(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _FormatChip(
                  label: 'Excel (.xlsx)',
                  icon: Icons.table_chart_outlined,
                  color: AppColors.successEmerald,
                  selected: _format == 'excel',
                  onTap: () => setState(() => _format = 'excel'),
                ),
                const SizedBox(width: 10),
                _FormatChip(
                  label: 'Dokumen PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  color: const Color(0xFFEF4444),
                  selected: _format == 'pdf',
                  onTap: () => setState(() => _format = 'pdf'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Batal',
            style: AppFonts.bodyLarge(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(
            'Unduh',
            style: AppFonts.titleLarge(color: Colors.white),
          ),
          onPressed: () => widget.onExport(
            _selectedMonth,
            _selectedYear,
            _selectedStudentId,
            _format,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppFonts.bodyLarge(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.textMuted.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      );
}

class _FormatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : AppColors.glassBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.bodyLarge(
                  color: selected ? color : AppColors.textSecondary,
                ).copyWith(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}