import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/teacher_repository.dart';

class TeacherAttendanceMonitorScreen extends ConsumerWidget {
  const TeacherAttendanceMonitorScreen({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(managedAttendanceProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Monitoring Absensi'), elevation: 0),
      body: attendanceAsync.when(
        data: (students) {
          final present = students
              .where((s) => s['attendance_status'] == 'Hadir')
              .length;
          final late = students
              .where((s) => s['attendance_status'] == 'Telat')
              .length;
          final absent = students
              .where(
                (s) =>
                    s['attendance_status'] == 'Alpha' ||
                    s['attendance_status'] == 'Belum Hadir',
              )
              .length;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(managedAttendanceProvider),
            child: Column(
              children: [
                // Summary Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatusSummary(
                        label: 'Hadir',
                        count: present,
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                      _StatusSummary(
                        label: 'Telat',
                        count: late,
                        color: Colors.orange,
                        icon: Icons.access_time,
                      ),
                      _StatusSummary(
                        label: 'Belum',
                        count: absent,
                        color: Colors.red,
                        icon: Icons.cancel,
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: students.isEmpty
                      ? const Center(child: Text('Belum ada siswa to monitor.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final status =
                                student['attendance_status'] ?? 'Belum Hadir';
                            final log = student['attendance_log'];

                            Color statusColor = Colors.grey;
                            if (status == 'Hadir') statusColor = Colors.green;
                            if (status == 'Telat') statusColor = Colors.orange;
                            if (status == 'Alpha') statusColor = Colors.red;

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.grey.shade100,
                                      backgroundImage:
                                          student['avatar_url'] != null
                                          ? NetworkImage(student['avatar_url'])
                                          : null,
                                      child: student['avatar_url'] == null
                                          ? Icon(
                                              Icons.person,
                                              color: Colors.grey.shade400,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['full_name'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            student['company_name'] ?? '-',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (log != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              "Masuk: ${log['check_in_time']?.toString().substring(11, 16) ?? '-'}",
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: statusColor.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusSummary({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
