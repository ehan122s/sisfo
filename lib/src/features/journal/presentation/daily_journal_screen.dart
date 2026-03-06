import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../authentication/data/auth_repository.dart';
import '../data/journal_repository.dart';
import '../../../common_widgets/skeleton_widget.dart';
import '../../../common_widgets/custom_network_image.dart';

class DailyJournalScreen extends ConsumerStatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  ConsumerState<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends ConsumerState<DailyJournalScreen> {
  final List<Map<String, dynamic>> _journals = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchJournals();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchJournals();
    }
  }

  Future<void> _fetchJournals() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      final newItems = await ref
          .read(journalRepositoryProvider)
          .getMyJournals(
            studentId: user.id,
            page: _currentPage,
            pageSize: _pageSize,
          );

      if (mounted) {
        setState(() {
          _journals.addAll(newItems);
          _currentPage++;
          if (newItems.length < _pageSize) {
            _hasMore = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // SnackBar might be hidden by FAB, careful
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _journals.clear();
      _currentPage = 0;
      _hasMore = true;
      _isLoading = false;
    });
    await _fetchJournals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Jurnal Harian',
                  style: TextStyle(color: Colors.black87),
                ),
                background: Container(color: Colors.white),
              ),
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            if (_journals.isEmpty && !_isLoading)
              const SliverFillRemaining(
                child: Center(child: Text("Belum ada jurnal.")),
              )
            else if (_journals.isEmpty && _isLoading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SkeletonWidget(
                      width: double.infinity,
                      height: 80,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  childCount: 5,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _journals.length) {
                      return _hasMore
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : const SizedBox(
                              height: 80,
                            ); // Bottom padding for FAB
                    }

                    final item = _journals[index];
                    final date = DateTime.parse(item['created_at']).toLocal();
                    final dateStr = DateFormat(
                      'EEEE, d MMM yyyy',
                      'id_ID',
                    ).format(date);
                    final isApproved = item['is_approved'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 1, // Subtle
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.book,
                            color: isApproved ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          item['activity_title'] ?? 'Tanpa Judul',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isApproved ? "Disetujui" : "Menunggu",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isApproved
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(LucideIcons.chevronRight),
                        onTap: () {
                          _showJournalDetail(context, item);
                        },
                      ),
                    );
                  },
                  childCount:
                      _journals.length + (_isLoading ? 1 : (_hasMore ? 1 : 0)),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/journal/create');
          if (result == true) {
            _refresh();
          }
        },
        backgroundColor: const Color(0xFF006400),
        foregroundColor: Colors.white,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showJournalDetail(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final date = DateTime.parse(item['created_at']).toLocal();
        final isApproved = item['is_approved'] == true;
        final evidenceUrl = item['evidence_url'] ?? item['evidence_photo'];

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    item['activity_title'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isApproved
                            ? LucideIcons.checkCircle
                            : LucideIcons.clock,
                        size: 16,
                        color: isApproved ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isApproved ? 'Sudah Disetujui' : 'Menunggu Persetujuan',
                        style: TextStyle(
                          color: isApproved ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Description
                  const Text(
                    "Deskripsi Kegiatan",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['description'] ?? 'Tidak ada deskripsi',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  // Evidence Image
                  if (evidenceUrl != null &&
                      (evidenceUrl as String).isNotEmpty) ...[
                    const Text(
                      "Bukti Kegiatan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomNetworkImage(
                      imageUrl: evidenceUrl,
                      width: double.infinity,
                      height: 200,
                      borderRadius: 12,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
