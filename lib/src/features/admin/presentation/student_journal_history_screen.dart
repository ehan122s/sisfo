import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';
import 'package:intl/intl.dart';

class StudentJournalHistoryScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;

  const StudentJournalHistoryScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<StudentJournalHistoryScreen> createState() =>
      _StudentJournalHistoryScreenState();
}

class _StudentJournalHistoryScreenState
    extends ConsumerState<StudentJournalHistoryScreen> {
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    // We reuse dailyJournalsProvider, filtering by this studentId
    // We pass null for date and className since we want ALL history for this student
    final historyAsync = ref.watch(
      dailyJournalsProvider((
        date: null,
        className: null,
        studentId: widget.studentId,
        page: _currentPage,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Jurnal Siswa: ${widget.studentName}'),
        centerTitle: false,
      ),
      body: historyAsync.when(
        data: (journals) {
          if (journals.isEmpty && _currentPage == 0) {
            return const Center(child: Text("Belum ada jurnal laporan."));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: journals.length,
                  separatorBuilder: (ctx, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final journal = journals[index];
                    final date = DateTime.parse(
                      journal['created_at'],
                    ).toLocal();
                    final formattedDate = DateFormat(
                      'd MMMM yyyy, HH:mm',
                      'id_ID',
                    ).format(date);
                    final activityTitle =
                        journal['activity_name'] ?? 'Kegiatan';
                    final description = journal['description'] ?? '-';
                    final photoUrl = journal['photo_url'];

                    // Status
                    final status = journal['status'] ?? 'pending';
                    Color statusColor = Colors.orange;
                    if (status == 'approved') statusColor = Colors.green;
                    if (status == 'rejected') statusColor = Colors.red;

                    return Card(
                      elevation: 1,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activityTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (photoUrl != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  photoUrl,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Pagination Controls
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Halaman ${_currentPage + 1}'),
                    ),
                    IconButton(
                      onPressed: journals.length == _pageSize
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                            }
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
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
