import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/admin_repository.dart';
import '../../../constants/app_constants.dart';
import 'student_attendance_history_screen.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  DateTime? _selectedDate = DateTime.now(); // Default to Today
  String? _selectedClass; // Filter by Class
  String? _selectedStatus; // Filter by Status
  int _currentPage = 0;
  final int _pageSize = 10;

  final List<String> _statuses = [
    'Hadir',
    'Terlambat',
    'Belum Hadir',
    'Izin',
    'Sakit',
  ];

  @override
  Widget build(BuildContext context) {
    // Fix: Pass record (date, className, status) to provider
    final logsAsync = ref.watch(
      attendanceLogsProvider((
        date: _selectedDate,
        className: _selectedClass,
        status: _selectedStatus,
        page: _currentPage,
      )),
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Laporan Kehadiran",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  // Status Filter Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        hint: const Text("Semua Status"),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("Semua Status"),
                          ),
                          ..._statuses.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedStatus = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Class Filter Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClass,
                        hint: const Text("Semua Kelas"),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("Semua Kelas"),
                          ),
                          ...AppConstants.schoolClasses.map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedClass = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _selectedDate = null),
                    ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _selectedDate == null
                          ? "Pilih Tanggal"
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(
                      child: Text("Tidak ada data kehadiran ditemukan."),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 24,
                              headingRowColor: WidgetStateProperty.all(
                                Colors.grey[100],
                              ),
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              columns: const [
                                DataColumn(label: Text("Tanggal")),
                                DataColumn(label: Text("Nama Siswa")),
                                DataColumn(label: Text("Kelas")),
                                DataColumn(label: Text("Tempat PKL")),
                                DataColumn(label: Text("Masuk")),
                                DataColumn(label: Text("Pulang")),
                                DataColumn(label: Text("Status")),
                              ],
                              rows: logs.map((log) {
                                final profile = log['profiles'] ?? {};
                                final studentId =
                                    log['student_id'] ?? profile['id'];
                                final fullName = profile['full_name'] ?? '-';
                                final className = profile['class_name'] ?? '-';
                                final status = log['status'] ?? '-';

                                // Date Time Parsing
                                final dateStr = log['created_at'] != null
                                    ? DateFormat('dd MMM yyyy').format(
                                        DateTime.parse(
                                          log['created_at'],
                                        ).toLocal(),
                                      )
                                    : '-';

                                String checkIn = '-';
                                if (log['check_in_time'] != null &&
                                    log['check_in_time'] != '-') {
                                  try {
                                    checkIn = DateFormat('HH:mm').format(
                                      DateTime.parse(
                                        log['check_in_time'],
                                      ).toLocal(),
                                    );
                                  } catch (e) {
                                    checkIn = log['check_in_time'];
                                  }
                                }

                                String checkOut = '-';
                                if (log['check_out_time'] != null &&
                                    log['check_out_time'] != '-') {
                                  try {
                                    checkOut = DateFormat('HH:mm').format(
                                      DateTime.parse(
                                        log['check_out_time'],
                                      ).toLocal(),
                                    );
                                  } catch (e) {
                                    checkOut = log['check_out_time'];
                                  }
                                }

                                // DUDI
                                final placements =
                                    (profile['placements'] as List?) ?? [];
                                String dudiName = '-';
                                if (placements.isNotEmpty) {
                                  final company = placements.first['companies'];
                                  if (company != null) {
                                    dudiName = company['name'] ?? '-';
                                  }
                                }

                                // Status Color
                                Color statusColor = Colors.black;
                                if (status == 'Hadir') {
                                  statusColor = Colors.green;
                                } else if (status == 'Terlambat') {
                                  statusColor = Colors.orange;
                                } else if (status == 'Belum Hadir') {
                                  statusColor = Colors.red;
                                }

                                return DataRow(
                                  cells: [
                                    DataCell(Text(dateStr)),
                                    DataCell(
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  StudentAttendanceHistoryScreen(
                                                    studentId: studentId,
                                                    studentName: fullName,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          fullName,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(className)),
                                    DataCell(Text(dudiName)),
                                    DataCell(Text(checkIn)),
                                    DataCell(Text(checkOut)),
                                    DataCell(
                                      Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      // Pagination
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 0
                                  ? () => setState(() => _currentPage--)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text("Halaman ${_currentPage + 1}"),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: logs.length == _pageSize
                                  ? () => setState(() => _currentPage++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Error: $err")),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
