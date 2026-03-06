import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/admin_repository.dart';

class StudentAttendanceHistoryScreen extends ConsumerWidget {
  final String studentId;
  final String studentName;

  const StudentAttendanceHistoryScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(studentAttendanceHistoryProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: Text("Histori Kehadiran: $studentName"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: historyAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text("Belum ada data kehadiran."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              final date = DateTime.parse(log['created_at']).toLocal();
              final status = log['status'] ?? '-';
              final checkIn = log['check_in_time'] != null
                  ? DateFormat(
                      'HH:mm',
                    ).format(DateTime.parse(log['check_in_time']).toLocal())
                  : '-';
              final checkOut = log['check_out_time'] != null
                  ? DateFormat(
                      'HH:mm',
                    ).format(DateTime.parse(log['check_out_time']).toLocal())
                  : '-';

              Color statusColor = Colors.grey;
              if (status == 'Hadir') statusColor = Colors.green;
              if (status == 'Terlambat') statusColor = Colors.orange;
              if (status == 'Izin') statusColor = Colors.blue;
              if (status == 'Sakit') statusColor = Colors.purple;
              if (status == 'Belum Hadir') statusColor = Colors.red;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 60,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, d MMMM yyyy',
                                'id_ID',
                              ).format(date),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _TimeItem(label: "Masuk", time: checkIn),
                          const SizedBox(height: 4),
                          _TimeItem(label: "Pulang", time: checkOut),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text("Error: $e")),
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  final String label;
  final String time;

  const _TimeItem({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
