import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/admin_repository.dart';
import '../../../constants/app_constants.dart';
import 'student_journal_history_screen.dart';

class StudentJournalReportScreen extends ConsumerStatefulWidget {
  const StudentJournalReportScreen({super.key});

  @override
  ConsumerState<StudentJournalReportScreen> createState() =>
      _StudentJournalReportScreenState();
}

class _StudentJournalReportScreenState
    extends ConsumerState<StudentJournalReportScreen> {
  DateTime? _selectedDate;
  String? _selectedClass;
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final journalsAsync = ref.watch(
      dailyJournalsProvider((
        date: _selectedDate,
        className: _selectedClass,
        studentId: null, // fetching for all students
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
                "Laporan Jurnal Siswa",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  // Class Filter
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
                          setState(() {
                            _selectedClass = val;
                            _currentPage = 0; // Reset page
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Date Filter
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _selectedDate = null;
                        _currentPage = 0;
                      }),
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
                        setState(() {
                          _selectedDate = picked;
                          _currentPage = 0;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? "Semua Tanggal"
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: journalsAsync.when(
              data: (journals) {
                if (journals.isEmpty) {
                  return const Center(child: Text("Belum ada data jurnal."));
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: journals.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final journal = journals[index];
                          final profile = journal['profiles'] ?? {};
                          final studentId = journal['student_id'];
                          final created = DateTime.parse(
                            journal['created_at'],
                          ).toLocal();
                          final time = DateFormat('HH:mm').format(created);
                          final date = DateFormat(
                            'dd MMM yyyy',
                          ).format(created);
                          final studentName = profile['full_name'] ?? 'Siswa';

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Photo Thumbnail (if any)
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      image: journal['evidence_photo'] != null
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                journal['evidence_photo'],
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: journal['evidence_photo'] == null
                                        ? const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (studentId != null) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            StudentJournalHistoryScreen(
                                                              studentId:
                                                                  studentId,
                                                              studentName:
                                                                  studentName,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      studentName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.blue,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "${profile['class_name'] ?? ''} • ${profile['nisn'] ?? ''}",
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "$date $time",
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          journal['activity_title'] ?? '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          journal['description'] ?? '-',
                                          style: const TextStyle(height: 1.4),
                                        ),
                                        const SizedBox(height: 8),
                                        // Status Approval
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (journal['is_approved'] == true)
                                                ? Colors.green[100]
                                                : Colors.orange[100],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            (journal['is_approved'] == true)
                                                ? "Disetujui"
                                                : "Menunggu",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  (journal['is_approved'] ==
                                                      true)
                                                  ? Colors.green[800]
                                                  : Colors.orange[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Pagination Controls
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text('Halaman ${_currentPage + 1}'),
                          ),
                          IconButton(
                            onPressed: journals.length == _pageSize
                                ? () => setState(() => _currentPage++)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }
}
