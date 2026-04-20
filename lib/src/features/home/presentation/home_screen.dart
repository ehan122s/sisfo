import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../../../common_widgets/skeleton_widget.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../offline/presentation/sync_status_indicator.dart';
import '../../journal/data/journal_repository.dart';
import 'announcement_banner.dart';

const _kBlue900 = Color(0xFF0D47A1);
const _kBlue700 = Color(0xFF1565C0);
const _kBlue500 = Color(0xFF1E88E5);
const _kBlue300 = Color(0xFF64B5F6);
const _kBlueBg = Color(0xFFF0F5FF);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: _kBlueBg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(size: 280, color: _kBlue500.withOpacity(0.08)),
          ),
          Positioned(
            top: 160,
            left: -80,
            child: _Blob(size: 220, color: _kBlue300.withOpacity(0.07)),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: _Blob(size: 160, color: _kBlue700.withOpacity(0.05)),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(user: user, profileAsync: profileAsync),
                ),
                SliverToBoxAdapter(
                  child: _GreetingSection(profileAsync: profileAsync),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: AnnouncementBanner(),
                  ),
                ),
                SliverToBoxAdapter(child: _MainSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _Header extends ConsumerWidget {
  final dynamic user;
  final AsyncValue<Map<String, dynamic>?> profileAsync;
  const _Header({required this.user, required this.profileAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync = ref.watch(studentPlacementProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          profileAsync.when(
            data: (p) => Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_kBlue300, _kBlue900]),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDEEAFB),
                child: Text(
                  (p?['full_name'] ?? user?.email ?? 'S')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: _kBlue700,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            loading: () => const SkeletonWidget.circular(width: 52, height: 52),
            error: (_, __) => const CircleAvatar(radius: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                profileAsync.when(
                  data: (p) => Text(
                    p?['full_name'] ?? 'Siswa Magang',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D1B3E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  loading: () => const SkeletonWidget(
                    width: 120,
                    height: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 3),
                placementAsync.when(
                  data: (pl) => Row(
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        size: 12,
                        color: _kBlue500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pl?['companies']?['name'] ?? 'Belum Penempatan',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _kBlue700,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
          const SyncStatusIndicator(),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue700.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _kBlue700,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> profileAsync;
  const _GreetingSection({required this.profileAsync});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String get _dateStr {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kBlue700, _kBlue900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _kBlue700.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: 40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$_greeting! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                profileAsync.when(
                  data: (p) => Text(
                    'Kelas ${p?['class_name'] ?? '-'}  •  ${p?['nisn'] ?? ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MainSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayLogAsync = ref.watch(todaysAttendanceLogProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PulseCheckInButton(),
          const SizedBox(height: 20),
          Text(
            'STATUS HARI INI',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kBlue700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: todayLogAsync.when(
                    data: (log) {
                      String status = 'Belum Absen', sub = 'Jadwal: 07.30';
                      IconData icon = Icons.access_time_rounded;
                      Color card = Colors.white,
                          iconBg = _kBlue500.withOpacity(0.1);
                      Color iconClr = _kBlue500,
                          textClr = const Color(0xFF1A1A2E);
                      Color subClr = const Color(0xFF9E9E9E);
                      if (log != null) {
                        if (log['check_out_time'] != null) {
                          status = 'Sudah Pulang';
                          sub = 'Selamat beristirahat';
                          icon = Icons.check_circle_rounded;
                          card = const Color(0xFF1A237E);
                          iconBg = Colors.white.withOpacity(0.15);
                          iconClr = Colors.white;
                          textClr = Colors.white;
                          subClr = Colors.white70;
                        } else if ((log['status'] ?? '') == 'Terlambat') {
                          status = 'Terlambat';
                          sub = 'Harap tepat waktu';
                          icon = Icons.warning_amber_rounded;
                          card = const Color(0xFFF57C00);
                          iconBg = Colors.white.withOpacity(0.2);
                          iconClr = Colors.white;
                          textClr = Colors.white;
                          subClr = Colors.white70;
                        } else {
                          status = 'Hadir';
                          sub = 'Semangat berkarya!';
                          icon = Icons.verified_rounded;
                          card = _kBlue700;
                          iconBg = Colors.white.withOpacity(0.2);
                          iconClr = Colors.white;
                          textClr = Colors.white;
                          subClr = Colors.white70;
                        }
                      }
                      return _StatCard(
                        label: 'Status',
                        value: status,
                        sub: sub,
                        icon: icon,
                        cardColor: card,
                        iconBg: iconBg,
                        iconColor: iconClr,
                        textColor: textClr,
                        subColor: subClr,
                      );
                    },
                    loading: () => _StatCardSkeleton(),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: todayLogAsync.when(
                    data: (log) {
                      String dur = '0j 0m';
                      if (log?['check_in_time'] != null &&
                          log?['check_out_time'] != null) {
                        final s = DateTime.parse(log!['check_in_time']);
                        final e = DateTime.parse(log['check_out_time']);
                        final d = e.difference(s);
                        dur = '${d.inHours}j ${d.inMinutes.remainder(60)}m';
                      }
                      return _StatCard(
                        label: 'Durasi',
                        value: dur,
                        sub: 'Target: 8 Jam',
                        icon: Icons.timelapse_rounded,
                        cardColor: Colors.white,
                        iconBg: _kBlue500.withOpacity(0.1),
                        iconColor: _kBlue500,
                        textColor: const Color(0xFF1A1A2E),
                        subColor: const Color(0xFF9E9E9E),
                      );
                    },
                    loading: () => _StatCardSkeleton(),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color cardColor, iconBg, iconColor, textColor, subColor;
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.cardColor,
    required this.iconBg,
    required this.iconColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: cardColor.withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: subColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        Text(sub, style: GoogleFonts.poppins(fontSize: 10, color: subColor)),
      ],
    ),
  );
}

class _StatCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonWidget.circular(width: 40, height: 40),
        SizedBox(height: 14),
        SkeletonWidget(
          width: 80,
          height: 20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        SizedBox(height: 6),
        SkeletonWidget(
          width: 60,
          height: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ],
    ),
  );
}

class _PulseCheckInButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PulseCheckInButton> createState() =>
      _PulseCheckInButtonState();
}

class _PulseCheckInButtonState extends ConsumerState<_PulseCheckInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scale = Tween(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
          _ctrl.stop();
          return journalAsync.when(
            data: (filled) => filled ? _doneCard() : _journalCard(context),
            loading: () => const SizedBox(height: 140),
            error: (_, __) => const SizedBox(),
          );
        }
        return _activeCard(context, isCheckedIn);
      },
      loading: () => Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(child: CircularProgressIndicator(color: _kBlue500)),
      ),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _activeCard(BuildContext context, bool isCheckedIn) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: GestureDetector(
          onTap: () {
            if (isCheckedIn && DateTime.now().hour < 14) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Belum waktunya pulang (jadwal: 14:00)',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              return;
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
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: isCheckedIn
                    ? [const Color(0xFFEF5350), const Color(0xFFB71C1C)]
                    : [_kBlue500, _kBlue900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCheckedIn ? Colors.red : _kBlue700).withOpacity(
                    0.45,
                  ),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 8,
                  blurStyle: BlurStyle.inner,
                  offset: const Offset(-4, -4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 10,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCheckedIn
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 22),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCheckedIn ? 'Absen Pulang' : 'Absen Masuk',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCheckedIn
                              ? 'Waktunya istirahat 🏠'
                              : 'Semangat berkarya! 💪',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _doneCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: _kBlue300.withOpacity(0.4), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: _kBlue500.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _kBlue500.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 36,
            color: _kBlue700,
          ),
        ),
        const SizedBox(width: 22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selesai Hari Ini!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _kBlue900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sampai jumpa besok 👋',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _journalCard(BuildContext context) => GestureDetector(
    onTap: () async {
      final result = await context.push('/journal/create');
      if (result == true && mounted) {
        ref.invalidate(todaysJournalStatusProvider);
        ref.invalidate(todaysAttendanceLogProvider);
      }
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Isi Jurnal Dulu!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lengkapi jurnal hari ini 📝',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
