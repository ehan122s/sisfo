import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../authentication/data/auth_repository.dart';
import '../data/journal_repository.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _kBlue900 = Color(0xFF0D47A1);
const _kBlue700 = Color(0xFF1565C0);
const _kBlue500 = Color(0xFF1E88E5);
const _kBlue300 = Color(0xFF64B5F6);
const _kBlueBg = Color(0xFFF0F5FF);

class DailyJournalScreen extends ConsumerStatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  ConsumerState<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends ConsumerState<DailyJournalScreen> {
  List<Map<String, dynamic>> journals = [];
  bool loading = false;
  bool hasMore = true;
  int page = 0;
  static const int _limit = 10;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200 &&
          !loading &&
          hasMore) {
        _loadMore();
      }
    });
    _fetchData();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (loading) return;
    setState(() => loading = true);

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    final data = await ref
        .read(journalRepositoryProvider)
        .getMyJournals(studentId: user.id, page: page, pageSize: _limit);

    setState(() {
      journals.addAll(data);
      page++;
      if (data.length < _limit) hasMore = false;
      loading = false;
    });
  }

  Future<void> _loadMore() => _fetchData();

  Future<void> _refresh() async {
    setState(() {
      journals.clear();
      page = 0;
      hasMore = true;
    });
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final approved = journals.where((e) => e['is_approved'] == true).length;
    final pending = journals.length - approved;

    return Scaffold(
      backgroundColor: _kBlueBg,
      body: Stack(
        children: [
          // bg blobs
          Positioned(
            top: -60,
            right: -50,
            child: _Blob(size: 240, color: _kBlue500.withOpacity(0.07)),
          ),
          Positioned(
            top: 200,
            left: -70,
            child: _Blob(size: 180, color: _kBlue300.withOpacity(0.06)),
          ),

          RefreshIndicator(
            color: _kBlue700,
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── AppBar ──────────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: _kBlueBg,
                  elevation: 0,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(color: _kBlueBg),
                  ),
                  title: Text(
                    'Jurnal Harian',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: const Color(0xFF0D1B3E),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _kBlue700.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.search,
                            color: _kBlue700,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Stats Header ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kBlue700, _kBlue900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _kBlue700.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -20,
                            right: -10,
                            child: _Blob(
                              size: 110,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          Positioned(
                            bottom: -30,
                            right: 60,
                            child: _Blob(
                              size: 80,
                              color: Colors.white.withOpacity(0.04),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      LucideIcons.bookOpen,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Jurnal',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '${journals.length}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  _StatPill(
                                    label: 'Disetujui',
                                    value: approved,
                                    color: const Color(0xFF4CAF50),
                                  ),
                                  const SizedBox(width: 10),
                                  _StatPill(
                                    label: 'Menunggu',
                                    value: pending,
                                    color: Colors.orange.shade400,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Section Label ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'RIWAYAT JURNAL',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kBlue700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                // ── Empty State ─────────────────────────────────────────────
                if (journals.isEmpty && !loading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: _kBlue500.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.bookOpen,
                              size: 48,
                              color: _kBlue500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Belum Ada Jurnal',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0D1B3E),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tekan tombol + untuk menulis jurnal pertamamu',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Journal List ────────────────────────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i == journals.length) {
                        return loading
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: _kBlue500,
                                  ),
                                ),
                              )
                            : const SizedBox(height: 100);
                      }

                      final item = journals[i];
                      final status = item['is_approved'] == true;
                      final date = DateTime.parse(item['created_at']).toLocal();

                      return _JournalCard(
                        item: item,
                        status: status,
                        date: date,
                        onTap: () =>
                            context.push('/journal/detail', extra: item),
                      );
                    },
                    childCount: journals.length + (hasMore || loading ? 1 : 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [_kBlue500, _kBlue900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _kBlue700.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              final result = await context.push('/journal/create');
              if (result == true) _refresh();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.plus, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tambah Jurnal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Journal Card ─────────────────────────────────────────────────────────────
class _JournalCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool status;
  final DateTime date;
  final VoidCallback onTap;

  const _JournalCard({
    required this.item,
    required this.status,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _kBlue700.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
              child: SizedBox(
                width: 88,
                height: 88,
                child: item['evidence_url'] != null
                    ? Image.network(
                        item['evidence_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                color: _kBlue500.withOpacity(0.08),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _kBlue500,
                                  ),
                                ),
                              ),
                      )
                    : _ImagePlaceholder(),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['activities'] ??
                          item['activity_title'] ??
                          'Tanpa Judul',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF0D1B3E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('d MMM yyyy', 'id_ID').format(date),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _StatusBadge(approved: status),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: _kBlue500.withOpacity(0.08),
    child: const Icon(LucideIcons.image, color: _kBlue300, size: 28),
  );
}

class _StatusBadge extends StatelessWidget {
  final bool approved;
  const _StatusBadge({required this.approved});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: approved ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          approved ? LucideIcons.checkCircle : LucideIcons.clock,
          size: 11,
          color: approved ? const Color(0xFF2E7D32) : Colors.orange.shade700,
        ),
        const SizedBox(width: 4),
        Text(
          approved ? 'Disetujui' : 'Menunggu',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: approved ? const Color(0xFF2E7D32) : Colors.orange.shade700,
          ),
        ),
      ],
    ),
  );
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
