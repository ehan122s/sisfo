import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/attendance_repository.dart';
import '../../../common_widgets/skeleton_widget.dart';

// ─── Theme Colors (matching Journal screen) ───────────────────────────────────
const _kPrimary = Color(0xFF1565C0); // biru tua
const _kPrimaryBg = Color(0xFF1E88E5); // biru medium (header gradient)
const _kAccent = Color(0xFF42A5F5); // biru muda
const _kBg = Color(0xFFF0F5FF); // background
const _kCardBg = Colors.white;

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  final List<Map<String, dynamic>> _history = [];
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
    _fetchHistory();
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
      _fetchHistory();
    }
  }

  Future<void> _fetchHistory() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      final newItems = await ref
          .read(attendanceRepositoryProvider)
          .getMyAttendanceHistory(
            studentId: user.id,
            page: _currentPage,
            pageSize: _pageSize,
          );

      if (mounted) {
        setState(() {
          _history.addAll(newItems);
          _currentPage++;
          if (newItems.length < _pageSize) _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat histori: $e')));
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _history.clear();
      _currentPage = 0;
      _hasMore = true;
      _isLoading = false;
    });
    await _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          'Riwayat Kehadiran',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Header summary card (ala jurnal) ──────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimary, _kPrimaryBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.calendarCheck,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Kehadiran',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${_history.length}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // badge hadir
                _SummaryBadge(
                  label:
                      '${_history.where((e) => e['status'] == 'Hadir').length} Hadir',
                  color: Colors.green.shade300,
                ),
                const SizedBox(width: 8),
                _SummaryBadge(
                  label:
                      '${_history.where((e) => e['status'] == 'Telat').length} Telat',
                  color: Colors.orange.shade300,
                ),
              ],
            ),
          ),

          // ── Label ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Text(
                  'RIWAYAT ABSENSI',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: _kPrimary,
              child: _history.isEmpty && _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: SkeletonWidget(
                          width: double.infinity,
                          height: 90,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                      ),
                    )
                  : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.calendarX,
                            size: 64,
                            color: _kAccent.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat kehadiran',
                            style: GoogleFonts.poppins(
                              color: _kPrimary.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: _history.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _history.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: _kPrimary,
                              ),
                            ),
                          );
                        }

                        final item = _history[index];
                        final date = DateTime.parse(
                          item['created_at'],
                        ).toLocal();
                        final dateStr = DateFormat(
                          'EEEE, d MMM yyyy',
                          'id_ID',
                        ).format(date);
                        final checkInTime = item['check_in_time'] != null
                            ? DateFormat('HH:mm').format(
                                DateTime.parse(item['check_in_time']).toLocal(),
                              )
                            : DateFormat('HH:mm').format(date);
                        final status = item['status'] ?? 'Hadir';

                        Color statusColor;
                        IconData statusIcon;
                        if (status == 'Telat') {
                          statusColor = Colors.orange.shade600;
                          statusIcon = LucideIcons.clock;
                        } else if (status == 'Alpa') {
                          statusColor = Colors.red.shade600;
                          statusIcon = LucideIcons.xCircle;
                        } else if (status == 'Izin' || status == 'Sakit') {
                          statusColor = Colors.purple.shade400;
                          statusIcon = LucideIcons.fileText;
                        } else {
                          statusColor = _kPrimary;
                          statusIcon = LucideIcons.calendarCheck;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: _kCardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _kPrimary.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: _kAccent.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.logIn,
                                            size: 13,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Masuk: $checkInTime',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (item['check_out_time'] !=
                                              null) ...[
                                            const SizedBox(width: 10),
                                            Icon(
                                              LucideIcons.logOut,
                                              size: 13,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Pulang: ${DateFormat('HH:mm').format(DateTime.parse(item['check_out_time']).toLocal())}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
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
          ),
        ],
      ),
    );
  }
}

// ─── Summary Badge ────────────────────────────────────────────────────────────
class _SummaryBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
