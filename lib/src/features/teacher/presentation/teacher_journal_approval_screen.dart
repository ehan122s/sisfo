import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/teacher_repository.dart';
import '../../authentication/data/auth_repository.dart';
import '../../../core/supabase_client.dart';

// Provider untuk jurnal yang sudah disetujui
final approvedJournalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) return [];

      final repo = ref.watch(teacherRepositoryProvider);
      final students = await repo.getManagedStudents(user.id);
      if (students.isEmpty) return [];

      final studentIds = students.map((s) => s['student_id']).toList();

      final response = await supabase
          .from('daily_journals')
          .select('*, profiles!inner(full_name, avatar_url)')
          .inFilter('student_id', studentIds)
          .eq('is_approved', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    });

class TeacherJournalApprovalScreen extends ConsumerWidget {
  const TeacherJournalApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingJournalsAsync = ref.watch(pendingJournalsProvider);
    final approvedJournalsAsync = ref.watch(approvedJournalsProvider);

    return DefaultTabController(
      length: 2,
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
            'Laporan Jurnal',
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
              Tab(text: 'Perlu Review'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── Tab 1: Pending ──────────────────────────────────────────────
            pendingJournalsAsync.when(
              data: (journals) {
                if (journals.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Semua jurnal sudah direview!',
                    color: const Color(0xFF10B981),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(pendingJournalsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: journals.length,
                    itemBuilder: (context, index) {
                      final journal = journals[index];
                      return _JournalCard(
                        journal: journal,
                        isPending: true,
                        onTap: () =>
                            _showJournalDetail(context, ref, journal, true),
                        onApprove: () =>
                            _processJournal(context, ref, journal['id'], true),
                        onReject: () =>
                            _processJournal(context, ref, journal['id'], false),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),

            // ── Tab 2: Riwayat ──────────────────────────────────────────────
            approvedJournalsAsync.when(
              data: (journals) {
                if (journals.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.history_edu_outlined,
                    title: 'Belum ada jurnal disetujui',
                    color: const Color(0xFF3B82F6),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(approvedJournalsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: journals.length,
                    itemBuilder: (context, index) {
                      final journal = journals[index];
                      return _JournalCard(
                        journal: journal,
                        isPending: false,
                        onTap: () =>
                            _showJournalDetail(context, ref, journal, false),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Foto Bukti',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showJournalDetail(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> journal,
    bool isPending,
  ) {
    final student = journal['profiles'] ?? {};
    final activities = journal['activities'] ?? '-';
    final notes = journal['notes'] ?? '';
    final challenges = journal['challenges'] ?? '';
    final evidenceUrl = journal['evidence_url'];
    final date =
        journal['date']?.toString() ??
        journal['created_at']?.toString().split('T')[0] ??
        '-';

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFEFF6FF),
                      backgroundImage: student['avatar_url'] != null
                          ? NetworkImage(student['avatar_url'])
                          : null,
                      child: student['avatar_url'] == null
                          ? Text(
                              (student['full_name'] ?? 'S')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['full_name'] ?? 'Siswa',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            date,
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
                        color: isPending
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPending ? 'Menunggu' : 'Disetujui',
                        style: GoogleFonts.poppins(
                          color: isPending
                              ? const Color(0xFFD97706)
                              : const Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto bukti — tap untuk fullscreen
                      if (evidenceUrl != null) ...[
                        GestureDetector(
                          onTap: () => _showFullImage(context, evidenceUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Image.network(
                                  evidenceUrl,
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                                // Zoom hint
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Perbesar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Aktivitas
                      _DetailSection(
                        label: 'Aktivitas',
                        value: activities,
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF3B82F6),
                      ),
                      if (challenges.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _DetailSection(
                          label: 'Deskripsi Kegiatan',
                          value: challenges,
                          icon: Icons.description_rounded,
                          color: const Color(0xFF3B82F6),
                        ),
                      ],
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _DetailSection(
                          label: 'Catatan',
                          value: notes,
                          icon: Icons.notes_rounded,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Tombol aksi
                      if (isPending)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
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
                                label: Text(
                                  'Tolak',
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _processJournal(
                                    context,
                                    ref,
                                    journal['id'],
                                    true,
                                  );
                                },
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Setujui',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
          content: Text(approve ? 'Jurnal disetujui ✓' : 'Jurnal ditolak'),
          backgroundColor: approve ? Colors.green : Colors.red,
        ),
      );
      ref.invalidate(pendingJournalsProvider);
      ref.invalidate(approvedJournalsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memproses: $e')));
    }
  }
}

// ── Journal Card ──────────────────────────────────────────────────────────────

class _JournalCard extends StatelessWidget {
  final Map<String, dynamic> journal;
  final bool isPending;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _JournalCard({
    required this.journal,
    required this.isPending,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final student = journal['profiles'] ?? {};
    final activities = journal['activities'] ?? '-';
    final evidenceUrl = journal['evidence_url'];
    final date =
        journal['date']?.toString() ??
        journal['created_at']?.toString().split('T')[0] ??
        '-';

    return GestureDetector(
      onTap: onTap,
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
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Status badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPending
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPending ? 'Menunggu' : 'Disetujui',
                          style: GoogleFonts.poppins(
                            color: isPending
                                ? const Color(0xFFD97706)
                                : const Color(0xFF10B981),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFEFF6FF),
                        backgroundImage: student['avatar_url'] != null
                            ? NetworkImage(student['avatar_url'])
                            : null,
                        child: student['avatar_url'] == null
                            ? Text(
                                (student['full_name'] ?? 'S')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['full_name'] ?? 'Siswa',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              date,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Aktivitas preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activities,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons — hanya di tab pending
            if (isPending) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onReject,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 18,
                        ),
                        label: Text(
                          'Tolak',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                      child: VerticalDivider(width: 1),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(
                          Icons.check,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                        label: Text(
                          'Setujui',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── Detail Section Widget ─────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailSection({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1F2937),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
