import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/teacher_repository.dart';

// Providers
final studentAttendanceByMonthProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, (String, int, int)>((
      ref,
      args,
    ) async {
      final repo = ref.read(teacherRepositoryProvider);
      return repo.getStudentAttendanceByMonth(args.$1, args.$2, args.$3);
    });

final studentJournalsByMonthProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, (String, int, int)>((
      ref,
      args,
    ) async {
      final repo = ref.read(teacherRepositoryProvider);
      return repo.getStudentJournalsByMonth(args.$1, args.$2, args.$3);
    });

class TeacherStudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const TeacherStudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentData,
  });

  @override
  ConsumerState<TeacherStudentDetailScreen> createState() =>
      _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState
    extends ConsumerState<TeacherStudentDetailScreen> {
  DateTime _selectedDate = DateTime.now();

  void _previousMonth() => setState(() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
  });

  void _nextMonth() => setState(() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
  });

  @override
  Widget build(BuildContext context) {
    final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate);

    final attendanceAsync = ref.watch(
      studentAttendanceByMonthProvider((
        widget.studentId,
        _selectedDate.month,
        _selectedDate.year,
      )),
    );

    final journalsAsync = ref.watch(
      studentJournalsByMonthProvider((
        widget.studentId,
        _selectedDate.month,
        _selectedDate.year,
      )),
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.studentData['full_name'] ?? 'Detail Siswa',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Profil'),
              Tab(text: 'Kehadiran'),
              Tab(text: 'Jurnal'),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  Text(
                    monthStr,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _buildProfileTab(),
                  _buildAttendanceTab(attendanceAsync),
                  _buildJournalTab(journalsAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Profil ────────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    final s = widget.studentData;
    final name = s['full_name'] ?? '-';
    final initial = name.substring(0, 1).toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar + nama
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFEFF6FF),
                  backgroundImage: s['avatar_url'] != null
                      ? NetworkImage(s['avatar_url'])
                      : null,
                  child: s['avatar_url'] == null
                      ? Text(
                          initial,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    s['class_name'] ?? '-',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info tiles
          _buildInfoTile(
            icon: Icons.badge_outlined,
            label: 'NISN',
            value: s['nisn'] ?? '-',
          ),
          _buildInfoTile(
            icon: Icons.business_outlined,
            label: 'Perusahaan PKL',
            value: s['company_name'] ?? '-',
          ),
          _buildInfoTile(
            icon: Icons.location_on_outlined,
            label: 'Alamat Perusahaan',
            value: s['company_address'] ?? '-',
          ),
          const SizedBox(height: 24),
          _buildInfoTile('NISN', s['nisn'] ?? '-'),
          _buildInfoTile('Perusahaan', s['company_name'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Kehadiran ─────────────────────────────────────────────────────────

  Widget _buildAttendanceTab(
    AsyncValue<List<Map<String, dynamic>>> attendanceAsync,
  ) {
    return attendanceAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_busy_rounded,
            title: 'Belum ada data absensi',
            subtitle: 'Bulan ini belum ada catatan kehadiran',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final log = logs[index];
            // PERBAIKAN: gunakan log['date'] bukan log['created_at']
            final date = DateTime.tryParse(log['date'] ?? '');
            final dateStr = date != null
                ? DateFormat('EEE, dd MMM yyyy', 'id_ID').format(date)
                : '-';
            final timeIn = log['check_in_time'] != null
                ? DateFormat('HH:mm').format(DateTime.parse(log['check_in_time']))
                : '-';
            final timeOut = log['check_out_time'] != null
                ? DateFormat('HH:mm').format(DateTime.parse(log['check_out_time']))
                : '-';

        // Summary counts
        final hadir = logs.where((l) => l['status'] == 'Hadir').length;
        final telat = logs
            .where((l) => l['status'] == 'Telat' || l['status'] == 'Terlambat')
            .length;
        final alpha = logs.where((l) => l['status'] == 'Alpa').length;

        return Column(
          children: [
            // Summary row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.access_time, color: Colors.blue),
                  ),
                  _SummaryChip(
                    label: 'Telat',
                    count: telat,
                    color: const Color(0xFFF59E0B),
                  ),
                  _SummaryChip(label: 'Alpa', count: alpha, color: Colors.red),
                  _SummaryChip(
                    label: 'Total',
                    count: logs.length,
                    color: const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final date = DateTime.tryParse(log['created_at'] ?? '');
                  final dateStr = date != null
                      ? DateFormat('EEE, dd MMM yyyy', 'id_ID').format(date)
                      : '-';
                  final timeIn = log['check_in_time'] != null
                      ? DateFormat(
                          'HH:mm',
                        ).format(DateTime.parse(log['check_in_time']))
                      : '-';
                  final timeOut = log['check_out_time'] != null
                      ? DateFormat(
                          'HH:mm',
                        ).format(DateTime.parse(log['check_out_time']))
                      : '-';
                  final status = log['status'] ?? 'Hadir';

                  Color statusColor;
                  switch (status) {
                    case 'Hadir':
                      statusColor = const Color(0xFF10B981);
                      break;
                    case 'Telat':
                    case 'Terlambat':
                      statusColor = const Color(0xFFF59E0B);
                      break;
                    case 'Izin':
                      statusColor = const Color(0xFF3B82F6);
                      break;
                    case 'Sakit':
                      statusColor = const Color(0xFF8B5CF6);
                      break;
                    case 'Alpa':
                      statusColor = Colors.red;
                      break;
                    default:
                      statusColor = Colors.grey;
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Masuk: $timeIn  •  Pulang: $timeOut',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.poppins(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  // ── Tab Jurnal ────────────────────────────────────────────────────────────

  Widget _buildJournalTab(
    AsyncValue<List<Map<String, dynamic>>> journalsAsync,
  ) {
    return journalsAsync.when(
      data: (journals) {
        if (journals.isEmpty) {
          return _buildEmptyState(
            icon: Icons.edit_note_rounded,
            title: 'Belum ada jurnal',
            subtitle: 'Bulan ini belum ada jurnal yang dibuat',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: journals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final journal = journals[index];
            // ── Pakai kolom yang benar ──
            final activities = journal['activities'] ?? '-';
            final evidenceUrl = journal['evidence_url'];
            final date =
                journal['date']?.toString() ??
                journal['created_at']?.toString().split('T')[0] ??
                '-';
            final isApproved = journal['is_approved'] == true;

            return GestureDetector(
              onTap: () => _showJournalDetail(context, journal),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto preview
                    if (evidenceUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            Image.network(
                              evidenceUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isApproved
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isApproved ? 'Disetujui' : 'Menunggu',
                                  style: GoogleFonts.poppins(
                                    color: isApproved
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFD97706),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      date,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    if (evidenceUrl == null) ...[
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isApproved
                                              ? const Color(0xFFD1FAE5)
                                              : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          isApproved ? 'Disetujui' : 'Menunggu',
                                          style: GoogleFonts.poppins(
                                            color: isApproved
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFD97706),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  activities,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E3A8A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF3B82F6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Hadir':
        color = Colors.green;
        break;
      case 'Telat':
      case 'Terlambat':
        color = Colors.orange;
        break;
      case 'Izin':
        color = Colors.blue;
        break;
      case 'Sakit':
        color = Colors.purple;
        break;
      case 'Alpa':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildJournalTab(
    AsyncValue<List<Map<String, dynamic>>> journalsAsync,
  ) {
    return journalsAsync.when(
      data: (journals) {
        if (journals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada jurnal bulan ini',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: journals.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final journal = journals[index];
            final date = DateTime.tryParse(journal['date'] ?? journal['created_at'] ?? '');
            final dateStr = date != null
                ? DateFormat('EEE, dd MMM', 'id_ID').format(date)
                : '-';
            final isApproved = journal['is_approved'] == true;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                onTap: () => _showJournalDetailDialog(context, journal),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: journal['evidence_photo'] != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(journal['evidence_photo']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: journal['evidence_photo'] == null
                      ? const Icon(Icons.image, color: Colors.grey)
                      : null,
                ),
                title: Text(
                  journal['activity_title'] ?? 'Kegiatan Prakerin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr),
                    if (journal['description'] != null)
                      Text(
                        journal['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
                trailing: isApproved
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.pending, color: Colors.orange),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) {
        debugPrint('Error loading journals: $e');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Terjadi kesalahan: $e', textAlign: TextAlign.center),
          ),
        );
      },
    );
  }

  void _showJournalDetailDialog(
    BuildContext context,
    Map<String, dynamic> journal,
  ) {
    final date = DateTime.tryParse(journal['date'] ?? journal['created_at'] ?? '');
    final dateStr = date != null
        ? DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID').format(date)
        : '-';
    final isApproved = journal['is_approved'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (journal['evidence_photo'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: journal['evidence_photo'],
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 250,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 250,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        journal['activity_title'] ?? 'Kegiatan Prakerin',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(dateStr, style: TextStyle(color: Colors.grey[600])),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isApproved
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isApproved ? Icons.check_circle : Icons.pending,
                                  size: 16,
                                  color: isApproved ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isApproved ? 'Disetujui' : 'Menunggu',
                                  style: TextStyle(
                                    color: isApproved ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Deskripsi Kegiatan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      if (challenges.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DetailSection(
                          label: 'Kendala',
                          value: challenges,
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        child: Text(
                          journal['description'] ?? 'Tidak ada deskripsi.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
