import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/teacher_repository.dart';

class TeacherAttendanceMonitorScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceMonitorScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceMonitorScreen> createState() =>
      _TeacherAttendanceMonitorScreenState();
}

class _TeacherAttendanceMonitorScreenState
    extends ConsumerState<TeacherAttendanceMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Fullscreen Image Viewer ───────────────────────────────────────────────

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Foto Absen',
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

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(managedAttendanceProvider);

    return Scaffold(
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
          'Monitoring Absensi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.refresh(managedAttendanceProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
            Tab(text: 'Daftar'),
            Tab(text: 'Peta'),
          ],
        ),
      ),
      body: attendanceAsync.when(
        data: (students) {
          final present = students
              .where((s) => s['attendance_status'] == 'Hadir')
              .length;
          final late = students
              .where((s) => s['attendance_status'] == 'Telat')
              .length;
          final absent = students
              .where(
                (s) =>
                    s['attendance_status'] == 'Alpha' ||
                    s['attendance_status'] == 'Belum Hadir',
              )
              .length;

          return Column(
            children: [
              // ── Summary ────────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryChip(
                      label: 'Hadir',
                      count: present,
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle_rounded,
                    ),
                    _SummaryChip(
                      label: 'Telat',
                      count: late,
                      color: const Color(0xFFF59E0B),
                      icon: Icons.access_time_rounded,
                    ),
                    _SummaryChip(
                      label: 'Belum',
                      count: absent,
                      color: Colors.red,
                      icon: Icons.cancel_rounded,
                    ),
                    _SummaryChip(
                      label: 'Total',
                      count: students.length,
                      color: const Color(0xFF3B82F6),
                      icon: Icons.people_alt_rounded,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildStudentList(students), _buildMap(students)],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ── Daftar Siswa ──────────────────────────────────────────────────────────

  Widget _buildStudentList(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada siswa binaan',
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

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(managedAttendanceProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: students.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final student = students[index];
          final status = student['attendance_status'] ?? 'Belum Hadir';
          final log = student['attendance_log'];
          final name = student['full_name'] ?? '-';
          final initial = name.substring(0, 1).toUpperCase();

          Color statusColor;
          IconData statusIcon;
          switch (status) {
            case 'Hadir':
              statusColor = const Color(0xFF10B981);
              statusIcon = Icons.check_circle_rounded;
              break;
            case 'Telat':
              statusColor = const Color(0xFFF59E0B);
              statusIcon = Icons.access_time_rounded;
              break;
            case 'Alpha':
              statusColor = Colors.red;
              statusIcon = Icons.cancel_rounded;
              break;
            default:
              statusColor = Colors.grey;
              statusIcon = Icons.radio_button_unchecked_rounded;
          }

          return GestureDetector(
            onTap: () => _showStudentDetail(context, student),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFEFF6FF),
                      backgroundImage: student['avatar_url'] != null
                          ? NetworkImage(student['avatar_url'])
                          : null,
                      child: student['avatar_url'] == null
                          ? Text(
                              initial,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.business_outlined,
                                size: 12,
                                color: Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  student['company_name'] ?? '-',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (log != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.login_rounded,
                                  size: 12,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Masuk: ${log['check_in_time']?.toString().substring(11, 16) ?? '-'}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                if (log['check_out_time'] != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.logout_rounded,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pulang: ${log['check_out_time'].toString().substring(11, 16)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: GoogleFonts.poppins(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Peta ──────────────────────────────────────────────────────────────────

  Widget _buildMap(List<Map<String, dynamic>> students) {
    final studentsWithLocation = students.where((s) {
      final log = s['attendance_log'];
      return log != null &&
          log['check_in_latitude'] != null &&
          log['check_in_longitude'] != null;
    }).toList();

    LatLng center = const LatLng(-7.2167, 107.9167);
    if (studentsWithLocation.isNotEmpty) {
      final log = studentsWithLocation.first['attendance_log'];
      center = LatLng(
        (log['check_in_latitude'] as num).toDouble(),
        (log['check_in_longitude'] as num).toDouble(),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15.0,
            minZoom: 10.0,
            maxZoom: 19.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.sip_smea',
            ),
            MarkerLayer(
              markers: studentsWithLocation.map((student) {
                final log = student['attendance_log'];
                final lat = (log['check_in_latitude'] as num).toDouble();
                final lng = (log['check_in_longitude'] as num).toDouble();
                final name = student['full_name'] ?? '-';
                final initial = name.substring(0, 1).toUpperCase();
                final status = student['attendance_status'] ?? 'Belum Hadir';

                Color statusColor;
                switch (status) {
                  case 'Hadir':
                    statusColor = const Color(0xFF10B981);
                    break;
                  case 'Telat':
                    statusColor = const Color(0xFFF59E0B);
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                return Marker(
                  point: LatLng(lat, lng),
                  width: 100,
                  height: 80,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => _showStudentDetail(context, student),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            name.split(' ').first,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Keterangan',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                _LegendItem(color: const Color(0xFF10B981), label: 'Hadir'),
                _LegendItem(color: const Color(0xFFF59E0B), label: 'Telat'),
                _LegendItem(color: Colors.grey, label: 'Belum/Alpha'),
              ],
            ),
          ),
        ),
        if (studentsWithLocation.isEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_off_rounded,
                    size: 48,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada siswa\nyang absen hari ini',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Detail Siswa Bottom Sheet ─────────────────────────────────────────────

  void _showStudentDetail(BuildContext context, Map<String, dynamic> student) {
    final log = student['attendance_log'];
    final name = student['full_name'] ?? '-';
    final initial = name.substring(0, 1).toUpperCase();
    final status = student['attendance_status'] ?? 'Belum Hadir';
    final photoUrl = log?['check_in_photo'] ?? log?['photo_url'];

    Color statusColor;
    switch (status) {
      case 'Hadir':
        statusColor = const Color(0xFF10B981);
        break;
      case 'Telat':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'Alpha':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // fix overflow
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
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
                      radius: 28,
                      backgroundColor: const Color(0xFFEFF6FF),
                      backgroundImage: student['avatar_url'] != null
                          ? NetworkImage(student['avatar_url'])
                          : null,
                      child: student['avatar_url'] == null
                          ? Text(
                              initial,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            student['class_name'] ?? '-',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        icon: Icons.business_outlined,
                        label: 'Perusahaan',
                        value: student['company_name'] ?? '-',
                      ),
                      if (log != null) ...[
                        _DetailRow(
                          icon: Icons.login_rounded,
                          label: 'Jam Masuk',
                          value: log['check_in_time'] != null
                              ? log['check_in_time'].toString().substring(
                                  11,
                                  16,
                                )
                              : '-',
                          valueColor: const Color(0xFF10B981),
                        ),
                        _DetailRow(
                          icon: Icons.logout_rounded,
                          label: 'Jam Pulang',
                          value: log['check_out_time'] != null
                              ? log['check_out_time'].toString().substring(
                                  11,
                                  16,
                                )
                              : 'Belum pulang',
                          valueColor: log['check_out_time'] != null
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        if (log['check_in_latitude'] != null)
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Koordinat Masuk',
                            value:
                                '${(log['check_in_latitude'] as num).toStringAsFixed(6)}, ${(log['check_in_longitude'] as num).toStringAsFixed(6)}',
                          ),
                        // Foto absen — tap untuk fullscreen
                        if (photoUrl != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Foto Absen',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showFullImage(context, photoUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image.network(
                                    photoUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                  // Zoom hint
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
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
                                            size: 14,
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
                        ],
                      ] else
                        _DetailRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Keterangan',
                          value: 'Belum melakukan absen hari ini',
                          valueColor: Colors.grey,
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
}

// ── Widget Pendukung ──────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
