import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../data/teacher_repository.dart';
import '../data/notification_repository.dart';
import '../../../services/excel_service.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context, ref, profileAsync),
                  const SizedBox(height: 32),
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
        Expanded(
          child: profileAsync.when(
            data: (profile) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      profile?['full_name']?.substring(0, 1).toUpperCase() ??
                          'G',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF3B82F6),
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
            const SnackBar(content: Text('Menyiapkan laporan...')),
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
                const SnackBar(content: Text('Laporan berhasil diunduh!')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
            }
          }
        },
      ),
    );
  }
}

// ── _StatCard ─────────────────────────────────────────────────────────────────

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

// ── _DashboardMenuCard ────────────────────────────────────────────────────────

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

// ── _ExportDialog ─────────────────────────────────────────────────────────────

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.download_outlined,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Export Laporan',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Periode',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: _inputDecoration('Bulan'),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          _months[i],
                          style: GoogleFonts.poppins(fontSize: 13),
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
                    value: _selectedYear,
                    decoration: _inputDecoration('Tahun'),
                    items: years
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text(
                              '$y',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedYear = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Siswa',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _selectedStudentId,
              decoration: _inputDecoration('Pilih Siswa'),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    'Semua Siswa',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
                ...widget.studentList.map(
                  (s) => DropdownMenuItem(
                    value: s['student_id'] as String?,
                    child: Text(
                      s['full_name'] ?? '-',
                      style: GoogleFonts.poppins(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedStudentId = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Format',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _FormatChip(
                  label: 'Excel (.xlsx)',
                  icon: Icons.table_chart_outlined,
                  color: const Color(0xFF10B981),
                  selected: _format == 'excel',
                  onTap: () => setState(() => _format = 'excel'),
                ),
                const SizedBox(width: 10),
                _FormatChip(
                  label: 'PDF',
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
          child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text('Download', style: GoogleFonts.poppins()),
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
    labelStyle: GoogleFonts.poppins(fontSize: 12),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}

// ── _FormatChip ───────────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
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
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
