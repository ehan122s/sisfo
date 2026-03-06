import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/teacher_repository.dart';

class TeacherJournalApprovalScreen extends ConsumerWidget {
  const TeacherJournalApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingJournalsAsync = ref.watch(pendingJournalsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Persetujuan Jurnal'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Perlu Review'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Pending
            pendingJournalsAsync.when(
              data: (journals) {
                if (journals.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(pendingJournalsProvider),
                    child: ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Tidak ada jurnal pending.')),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(pendingJournalsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemCount: journals.length,
                    itemBuilder: (context, index) {
                      final journal = journals[index];
                      final student = journal['profiles'] ?? {};
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        student['avatar_url'] != null
                                        ? NetworkImage(student['avatar_url'])
                                        : null,
                                    child: student['avatar_url'] == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['full_name'] ?? 'Siswa',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          journal['created_at']
                                              .toString()
                                              .split('T')[0],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    journal['activity_title'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    journal['description'] ?? '-',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  if (journal['evidence_photo'] != null) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        journal['evidence_photo'],
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const SizedBox(height: 0),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Actions
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () {
                                        _processJournal(
                                          context,
                                          ref,
                                          journal['id'],
                                          false,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Tolak',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                  const VerticalDivider(width: 1),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () {
                                        _processJournal(
                                          context,
                                          ref,
                                          journal['id'],
                                          true,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      ),
                                      label: const Text(
                                        'Setujui',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),

            // Tab 2: History (Placeholder)
            const Center(child: Text('Riwayat Jurnal (Coming Soon)')),
          ],
        ),
      ),
    );
  }

  Future<void> _processJournal(
    BuildContext context,
    WidgetRef ref,
    int journalId,
    bool approve,
  ) async {
    try {
      await ref
          .read(teacherRepositoryProvider)
          .updateJournalStatus(journalId, approve);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Jurnal disetujui' : 'Jurnal ditolak'),
        ),
      );
      ref.invalidate(pendingJournalsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memproses: $e')));
    }
  }
}
