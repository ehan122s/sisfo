import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../authentication/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';

// =========================================================================
// ── PREMIUM GLASSMORPHIC BLUE COLOR PALETTE ──
// =========================================================================
class AppColors {
  static const Color primaryBlue = Color(0xFF1D4ED8);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color iceBlue = Color(0xFF93C5FD);
  static const Color cyanAccent = Color(0xFF06B6D4);

  static const Color successEmerald = Color(0xFF10B981);
  static const Color alertAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  static const Color background = Color(0xFFF0F5FA);
  static const Color surface = Colors.white;
  static const Color glassBorder = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
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
      );

  static TextStyle labelSmall({Color? color}) => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textMuted,
        letterSpacing: 0.5,
      );
}

// =========================================================================
// ── TRUE GLASSMORPHISM CARD
// =========================================================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final List<BoxShadow>? customShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.borderColor,
    this.backgroundColor,
    this.customShadow,
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
// ── PROFILE TEACHER SCREEN
// =========================================================================
class ProfileTeacherScreen extends ConsumerWidget {
  const ProfileTeacherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          _ambientCircle(
            top: -100,
            left: -80,
            size: 380,
            color: AppColors.cyanAccent.withValues(alpha: 0.18),
            blur: 90,
          ),
          _ambientCircle(
            top: 150,
            right: -100,
            size: 320,
            color: AppColors.primaryBlue.withValues(alpha: 0.12),
            blur: 80,
          ),
          _ambientCircle(
            bottom: 80,
            left: -60,
            size: 300,
            color: AppColors.lightBlue.withValues(alpha: 0.1),
            blur: 70,
          ),
          SafeArea(
            bottom: false,
            child: profileAsync.when(
              data: (profile) => SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildTopBar(context),
                    const SizedBox(height: 24),
                    _buildProfileHero(profile),
                    const SizedBox(height: 20),
                    _buildStatusRow(profile),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Informasi Akun'),
                    const SizedBox(height: 12),
                    _buildInfoCard(profile),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Pengaturan Cepat'),
                    const SizedBox(height: 12),
                    _buildSettingCard(context, ref),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue,
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GlassCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.dangerRed,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat profil',
                          style: AppFonts.headlineMedium(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$error',
                          style: AppFonts.bodyLarge(),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPremiumFloatingDock(context),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          _circleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil',
                  style: AppFonts.headlineMedium(),
                ),
                const SizedBox(height: 2),
                Text(
                  'Informasi akun guru',
                  style: AppFonts.bodyMedium(),
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => context.go('/teacher/dashboard/profile/edit'),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(
              'Edit',
              style: AppFonts.titleLarge(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero(Map<String, dynamic>? profile) {
    final fullName = _text(profile, 'full_name', 'Guru Pembimbing');
    final email = _text(profile, 'email', 'email belum tersedia');
    final major = _text(profile, 'major', 'Guru Pembimbing PKL');
    final initial = fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'G';

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      borderColor: Colors.white.withValues(alpha: 0.70),
      backgroundColor: Colors.white.withValues(alpha: 0.58),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.14),
                width: 1.4,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: AppFonts.headlineLarge(
                  color: AppColors.primaryBlue,
                ).copyWith(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: AppFonts.headlineMedium().copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  major,
                  style: AppFonts.bodyLarge(
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        email,
                        style: AppFonts.bodyMedium(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(Map<String, dynamic>? profile) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatusCard(
            icon: Icons.badge_outlined,
            title: 'NIP/NIK',
            value: _text(profile, 'nip', '-'),
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatusCard(
            icon: Icons.school_outlined,
            title: 'Jurusan',
            value: _text(profile, 'major', '-'),
            color: AppColors.cyanAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Map<String, dynamic>? profile) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.person_outline_rounded,
            title: 'Nama Lengkap',
            value: _text(profile, 'full_name', 'Guru Pembimbing'),
            color: AppColors.primaryBlue,
          ),
          _divider(),
          _InfoTile(
            icon: Icons.email_outlined,
            title: 'Email',
            value: _text(profile, 'email', '-'),
            color: AppColors.cyanAccent,
          ),
          _divider(),
          _InfoTile(
            icon: Icons.phone_outlined,
            title: 'Nomor Telepon',
            value: _text(profile, 'phone', '-'),
            color: AppColors.successEmerald,
          ),
          _divider(),
          _InfoTile(
            icon: Icons.location_on_outlined,
            title: 'Alamat',
            value: _text(profile, 'address', '-'),
            color: AppColors.alertAmber,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      borderRadius: 24,
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.edit_note_rounded,
            title: 'Edit Profil',
            subtitle: 'Perbarui informasi akun guru',
            color: AppColors.primaryBlue,
            onTap: () => context.go('/teacher/dashboard/profile/edit'),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Keamanan Akun',
            subtitle: 'Kelola password dan akses akun',
            color: AppColors.cyanAccent,
            onTap: () => context.go('/teacher/dashboard/profile/security'),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.logout_rounded,
            title: 'Keluar Akun',
            subtitle: 'Logout dari aplikasi PKL',
            color: AppColors.dangerRed,
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppFonts.headlineMedium(),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
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
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.glassBorder.withValues(alpha: 0.6),
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  static Widget _ambientCircle({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
    required double blur,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: AppColors.glassBorder.withValues(alpha: 0.7),
      ),
    );
  }

  static String _text(
    Map<String, dynamic>? data,
    String key,
    String fallback,
  ) {
    final value = data?[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Keluar Akun?',
          style: AppFonts.headlineMedium(),
        ),
        content: Text(
          'Kamu akan keluar dari dashboard guru.',
          style: AppFonts.bodyLarge(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: AppFonts.bodyLarge(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: AppFonts.titleLarge(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  Widget _buildPremiumFloatingDock(BuildContext context) {
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
                _DockItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Home',
                  selected: false,
                  onTap: () => context.go('/teacher/dashboard'),
                ),
                _DockItem(
                  icon: Icons.fingerprint_outlined,
                  activeIcon: Icons.fingerprint_rounded,
                  label: 'Absen',
                  selected: false,
                  onTap: () => context.go('/teacher/dashboard/attendance'),
                ),
                Container(
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
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                _DockItem(
                  icon: Icons.book_outlined,
                  activeIcon: Icons.book_rounded,
                  label: 'Jurnal',
                  selected: false,
                  onTap: () => context.go('/teacher/dashboard/journals'),
                ),
                _DockItem(
                  icon: Icons.star_border_rounded,
                  activeIcon: Icons.star_rounded,
                  label: 'Nilai',
                  selected: false,
                  onTap: () => context.go('/teacher/dashboard/assessment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// ── SMALL COMPONENTS
// =========================================================================
class _MiniStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MiniStatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppFonts.bodyMedium()),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppFonts.titleLarge(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppFonts.bodyMedium()),
              const SizedBox(height: 3),
              Text(
                value,
                style: AppFonts.titleLarge(color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = color == AppColors.dangerRed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDanger
                ? AppColors.dangerRed.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDanger
                  ? AppColors.dangerRed.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.35),
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
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppFonts.titleLarge()),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppFonts.bodyMedium()),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                color: selected
                    ? AppColors.primaryBlue.withValues(alpha: 0.08)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? activeIcon : icon,
                color: selected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppFonts.labelSmall(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.6),
              ).copyWith(
                fontSize: 8,
                letterSpacing: 0,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
