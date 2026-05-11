import 'package:flutter/material.dart';
import 'teacher_attendance_monitor_screen.dart';
import 'teacher_journal_screen.dart';
import 'teacher_datasiswa_screen.dart';
import 'teacher_riwayat_screen.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background Header Dekoratif
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
          // Background decoration bubbles
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
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
                color: const Color(0xFF3B82F6).withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildTopBar(),
                  const SizedBox(height: 30),
                  _buildHeroStats(),
                  const SizedBox(height: 35),
                  const Text(
                    "Layanan Utama",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                  // 1. Top Bar
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
                  _buildNavigationGrid(context),
                  const SizedBox(height: 30),
                  _buildUpcomingSchedule(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Senin, 12 Mei 2024",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
            const Text(
              "Halo, Pak Budi!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
        Expanded(
          child: profileAsync.when(
            data: (profile) => Row(
              children: [
                // ── Avatar biru ──
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3B82F6), // Biru
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFEFF6FF), // Biru muda
                    child: Text(
                      profile?['full_name']?.substring(0, 1).toUpperCase() ??
                          'G',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF3B82F6), // Biru
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
            onPressed: () {},
          ),
        )
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
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Hadir Hari Ini',
              count: stats['present_today'].toString(),
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Perlu Review',
              count: stats['pending_journals'].toString(),
              icon: Icons.pending_actions_outlined,
              color: const Color(0xFFF59E0B),
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
      childAspectRatio: 1.1,
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
        _DashboardMenuCard(
          icon: Icons.history_edu_outlined,
          label: 'Riwayat Aktivitas',
          description: 'Log notifikasi & kejadian',
          color: const Color(0xFF8B5CF6),
          onTap: () => context.go('/teacher/dashboard/notifications'),
        ),
      ],
    );
  }

  Widget _buildHeroStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _singleHeroStat("98%", "Kehadiran", Icons.trending_up, Colors.green),
              Container(height: 40, width: 1, color: Colors.grey[200]),
              _singleHeroStat("24", "Siswa Aktif", Icons.people, Colors.blue),
              Container(height: 40, width: 1, color: Colors.grey[200]),
              _singleHeroStat("8", "Sesi Hari Ini", Icons.calendar_today, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _singleHeroStat(String val, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  Widget _buildNavigationGrid(BuildContext context) {
    final List<Map<String, dynamic>> menus = [
      {
        'title': 'Monitoring\nAbsensi',
        'icon': Icons.track_changes_rounded,
        'color': Colors.indigo,
        'page': const TeacherAttendanceMonitorScreen(),
      },
      {
        'title': 'Jurnal\nMengajar',
        'icon': Icons.auto_stories_rounded,
        'color': Colors.teal,
        'page': const TeacherJournalScreen(),
      },
      {
        'title': 'Database\nSiswa',
        'icon': Icons.badge_rounded,
        'color': Colors.blueAccent,
        'page': const TeacherDataSiswaScreen(),
      },
      {
        'title': 'Riwayat\nAktivitas',
        'icon': Icons.history_edu_rounded,
        'color': Colors.amber[800],
        'page': const TeacherRiwayatScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => menus[index]['page']),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (menus[index]['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(menus[index]['icon'], color: menus[index]['color']),
                ),
                const SizedBox(height: 12),
                Text(
                  menus[index]['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Jadwal Mendatang",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigoAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text("10:30", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("WIB", style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
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
              const SizedBox(width: 20),
              const Expanded(
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Matematika Peminatan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Kelas XII IPA 1 • Lab Komputer", style: TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            ],
          ),
        )
      ],
    );
  }
}