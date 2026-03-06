import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/teacher_repository.dart';

// Providers for this screen
final studentAttendanceByMonthProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, (String, int, int)>((
      ref,
      args,
    ) async {
      final repo = ref.read(teacherRepositoryProvider);
      debugPrint(
        '[TeacherStudentDetail] Fetching attendance for student: ${args.$1}, month: ${args.$2}, year: ${args.$3}',
      );
      try {
        final result = await repo.getStudentAttendanceByMonth(
          args.$1, // studentId
          args.$2, // month
          args.$3, // year
        );
        debugPrint(
          '[TeacherStudentDetail] Attendance result: ${result.length} records',
        );
        return result;
      } catch (e, s) {
        debugPrint('[TeacherStudentDetail] Attendance error: $e');
        debugPrint('[TeacherStudentDetail] Stack: $s');
        rethrow;
      }
    });

final studentJournalsByMonthProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, (String, int, int)>((
      ref,
      args,
    ) async {
      final repo = ref.read(teacherRepositoryProvider);
      debugPrint(
        '[TeacherStudentDetail] Fetching journals for student: ${args.$1}, month: ${args.$2}, year: ${args.$3}',
      );
      try {
        final result = await repo.getStudentJournalsByMonth(
          args.$1, // studentId
          args.$2, // month
          args.$3, // year
        );
        debugPrint(
          '[TeacherStudentDetail] Journals result: ${result.length} records',
        );
        return result;
      } catch (e, s) {
        debugPrint('[TeacherStudentDetail] Journals error: $e');
        debugPrint('[TeacherStudentDetail] Stack: $s');
        rethrow;
      }
    });

class TeacherStudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData; // Pass basic data (name, avatar, etc)

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

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MMMM yyyy', 'id_ID');
    final monthStr = monthFormat.format(_selectedDate);

    // Use Records for equality check
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Detail Siswa'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Profil'),
              Tab(text: 'Kehadiran'),
              Tab(text: 'Jurnal'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Month Picker (Only relevant for Attendance & Journal, but kept top for simplicity)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    monthStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right),
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

  Widget _buildProfileTab() {
    final s = widget.studentData;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: s['avatar_url'] != null
                ? CachedNetworkImageProvider(s['avatar_url'])
                : null,
            child: s['avatar_url'] == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            s['full_name'] ?? '-',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            s['class_name'] ?? '-',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _buildInfoTile('NISN', s['nisn'] ?? '-'),
          _buildInfoTile('Perusahaan', s['company_name'] ?? '-'),
          // Add more fields if available
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(
    AsyncValue<List<Map<String, dynamic>>> attendanceAsync,
  ) {
    return attendanceAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data absensi',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final log = logs[index];
            final date = DateTime.tryParse(log['created_at']);
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

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      // Use different color based on status if needed
                    ),
                    child: const Icon(Icons.access_time, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Masuk: $timeIn • Pulang: $timeOut',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(log['status'] ?? 'Hadir'),
                ],
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
      case 'Terlambat': // Handle both variations
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
            final date = DateTime.tryParse(journal['created_at']);
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
                            image: CachedNetworkImageProvider(
                              journal['evidence_photo'],
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: journal['evidence_photo'] == null
                      ? const Icon(Icons.image, color: Colors.grey)
                      : null,
                ),
                title: Text(
                  journal['activity_title'] ?? 'No Title',
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
    final date = DateTime.tryParse(journal['created_at'] ?? '');
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
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
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 250,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        journal['activity_title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Date & Status Row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
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
                                  isApproved
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  size: 16,
                                  color: isApproved
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isApproved ? 'Disetujui' : 'Menunggu',
                                  style: TextStyle(
                                    color: isApproved
                                        ? Colors.green
                                        : Colors.orange,
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

                      // Description
                      const Text(
                        'Deskripsi Kegiatan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          journal['description'] ?? 'Tidak ada deskripsi.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
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
