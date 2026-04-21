import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/attendance_repository.dart';
import '../../../common_widgets/skeleton_widget.dart';

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

  // Warna sesuai gambar Absen Masuk yang kamu kirim
  final Color primaryBlue = const Color(0xFF1976D2);
  final Color lightBlueBg = const Color(0xFFF0F4F8);

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
          if (newItems.length < _pageSize) {
            _hasMore = false;
          }
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
      backgroundColor: lightBlueBg,
      appBar: AppBar(
        title: Text(
          'Riwayat Kehadiran',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Body tanpa FloatingActionButton (+) membuat tampilan bersih di kanan bawah
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: primaryBlue,
        child: _history.isEmpty && _isLoading
            ? _buildSkeleton()
            : _history.isEmpty
            ? _buildEmptyState()
            : _buildList(),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonWidget(
          width: double.infinity,
          height: 100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.calendarX,
            size: 64,
            color: primaryBlue.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada riwayat kehadiran",
            style: GoogleFonts.poppins(
              color: primaryBlue.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _history.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _history.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(color: primaryBlue),
            ),
          );
        }

        final item = _history[index];
        final date = DateTime.parse(item['created_at']).toLocal();
        final dateStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
        final timeStr = DateFormat('HH:mm').format(date);
        final status = item['status'] ?? 'Hadir';

        Color statusColor = primaryBlue;
        if (status == 'Telat')
          statusColor = Colors.orange.shade600;
        else if (status == 'Alpa')
          statusColor = Colors.red.shade600;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.blue.shade50, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ikon Bulat di Kiri
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.calendarCheck,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // Info Text di Tengah
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Masuk: $timeStr",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Spacer memastikan badge status menempel ke kanan
                const Spacer(),
                // Badge Status di Kanan (Tanpa tanda panah)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
