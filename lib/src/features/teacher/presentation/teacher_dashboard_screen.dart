import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../data/teacher_repository.dart';
import '../data/notification_repository.dart';
import '../../../services/excel_service.dart';
import 'package:open_file/open_file.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Lighter grey for cleaner look
      body: Stack(
        children: [
          // Background decoration bubbles
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF006400).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Bar with Profile & Actions
                  _buildTopBar(context, ref, profileAsync),

                  const SizedBox(height: 32),

                  // 2. Stats Section
                  Text(
                    'Ringkasan Hari Ini',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsRow(statsAsync),

                  const SizedBox(height: 32),

                  // 3. Menu Grid
                  Text(
                    'Menu Utama',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuGrid(context),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>?> profileAsync,
  ) {
    return Row(
      children: [
        // Profile Info
        Expanded(
          child: profileAsync.when(
            data: (profile) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF006400),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      profile?['full_name']?.substring(0, 1).toUpperCase() ??
                          "G",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF006400),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang,',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        profile?['full_name'] ?? 'Guru Pembimbing',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => _buildProfileSkeleton(),
            error: (err, stack) => _buildProfileSkeleton(),
          ),
        ),

        // Actions
        Row(
          children: [
            // Notification Button with Badge
            Stack(
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.notifications_outlined,
                  onTap: () => context.go('/teacher/dashboard/notifications'),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final asyncValue = ref.watch(
                        teacherNotificationsProvider,
                      );
                      final count =
                          asyncValue.value?.where((n) => !n.isRead).length ?? 0;

                      if (count == 0) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              context,
              icon: Icons.download_outlined,
              tooltip: 'Export Laporan',
              onTap: () => _handleExport(context, ref),
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              context,
              icon: Icons.logout,
              color: Colors.red[50],
              iconColor: Colors.red,
              onTap: () {
                ref.read(authRepositoryProvider).signOut();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileSkeleton() {
    return Row(
      children: [
        const CircleAvatar(radius: 24, backgroundColor: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 80, height: 10, color: Colors.grey[300]),
            const SizedBox(height: 4),
            Container(width: 120, height: 14, color: Colors.grey[300]),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
    String? tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, size: 20, color: iconColor ?? Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildStatsRow(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Total Siswa',
              count: stats['total_students'].toString(),
              icon: Icons.people_alt_outlined,
              color: const Color(0xFF3B82F6), // Blue
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Hadir Hari Ini',
              count: stats['present_today'].toString(),
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF10B981), // Green
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Perlu Review',
              count: stats['pending_journals'].toString(),
              icon: Icons.pending_actions_outlined,
              color: const Color(0xFFF59E0B), // Amber
            ),
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(
        height: 120,
        child: Center(child: Text('Gagal memuat data')),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1, // Slightly wider for better text fit
      children: [
        _DashboardMenuCard(
          icon: Icons.location_on_outlined,
          label: 'Monitoring Absensi',
          description: 'Pantau lokasi & waktu',
          color: const Color(0xFF3B82F6),
          onTap: () => context.go('/teacher/dashboard/attendance'),
        ),
        _DashboardMenuCard(
          icon: Icons.book_outlined,
          label: 'Laporan Jurnal',
          description: 'Validasi kegiatan siswa',
          color: const Color(0xFF10B981),
          onTap: () => context.go('/teacher/dashboard/journals'),
        ),
        _DashboardMenuCard(
          icon: Icons.groups_outlined,
          label: 'Data Siswa',
          description: 'Profil & status PKL',
          color: const Color(0xFFF59E0B),
          onTap: () => context.go('/teacher/dashboard/students'),
        ),
        // New 4th Card
        _DashboardMenuCard(
          icon: Icons.history_edu_outlined,
          label: 'Riwayat Aktivitas',
          description: 'Log notifikasi & kejadian',
          color: const Color(0xFF8B5CF6), // Purple
          onTap: () => context.go('/teacher/dashboard/notifications'),
        ),
      ],
    );
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menyiapkan laporan...')));

      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      final data = await ref
          .read(teacherRepositoryProvider)
          .getAttendanceReportForExport(user.id);

      if (data.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada data absensi bulan ini.')),
          );
        }
        return;
      }

      final profile = ref.read(userProfileProvider).value;
      final teacherName = profile?['full_name'] ?? 'Guru';

      final file = await ExcelService().generateAttendanceReport(
        data,
        teacherName,
      );

      if (file.existsSync()) {
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal membuka file: ${result.message}')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File disimpan & dibuka.')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DashboardMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _DashboardMenuCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative background circle
              Positioned(
                bottom: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 24, color: color),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
}
