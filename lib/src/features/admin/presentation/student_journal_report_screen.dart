import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    extends ConsumerState<StudentJournalReportScreen>
    with TickerProviderStateMixin {
  DateTime? _selectedDate;
  String? _selectedClass;
  int _currentPage = 0;
  final int _pageSize = 10;

  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  static const _primaryBlue = Color(0xFF1976D2);
  static const _darkBlue = Color(0xFF0D47A1);
  static const _bgColor = Color(0xFFE3F2FD);
  static const _lightBlue = Color(0xFFBBDEFB);
  static const _accentBlue = Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;

    final journalsAsync = ref.watch(
      dailyJournalsProvider((
        date: _selectedDate,
        className: _selectedClass,
        studentId: null,
        page: _currentPage,
      )),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3F2FD), Color(0xFFF8FBFF), Color(0xFFE8F4FD)],
        ),
      ),
      child: Column(
        children: [
          // Header dengan gradient biru
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: _buildTopHeader(isSmall),
            ),
          ),
          // Filter bar
          FadeTransition(
            opacity: _headerFade,
            child: _buildFilterBar(isSmall),
          ),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: journalsAsync.when(
              data: (journals) => _buildJournalList(journals, isSmall),
              loading: () => _buildLoadingState(),
              error: (e, _) => _buildErrorWidget(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(bool isSmall) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id').format(now);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          isSmall ? 16 : 24, 20, isSmall ? 16 : 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkBlue, _primaryBlue, _accentBlue],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331976D2),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan Jurnal',
                      style: GoogleFonts.poppins(
                        fontSize: isSmall ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Rekap aktivitas harian siswa PKL',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info tanggal
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.today_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isSmall) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isSmall ? 12 : 16, 16, isSmall ? 12 : 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isSmall
            ? Column(
                children: [
                  _buildClassDropdown(),
                  const SizedBox(height: 8),
                  _buildDateButton(),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildClassDropdown()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDateButton()),
                ],
              ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _selectedClass != null ? _bgColor : const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _selectedClass != null
              ? _primaryBlue.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClass,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.people_outline_rounded, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                'Semua Kelas',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
          selectedItemBuilder: (context) => [
            _dropdownSelectedItem('Semua Kelas'),
            ...AppConstants.schoolClasses
                .map((c) => _dropdownSelectedItem(c)),
          ],
          icon: Icon(Icons.expand_more_rounded,
              color: _selectedClass != null ? _primaryBlue : Colors.grey[400]),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('Semua Kelas',
                  style: GoogleFonts.poppins(fontSize: 13)),
            ),
            ...AppConstants.schoolClasses.map(
              (c) => DropdownMenuItem(
                value: c,
                child:
                    Text(c, style: GoogleFonts.poppins(fontSize: 13)),
              ),
            ),
          ],
          onChanged: (val) => setState(() {
            _selectedClass = val;
            _currentPage = 0;
          }),
        ),
      ),
    );
  }

  Widget _dropdownSelectedItem(String text) {
    return Row(
      children: [
        Icon(Icons.people_outline_rounded, size: 16, color: _primaryBlue),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.poppins(fontSize: 13, color: _primaryBlue)),
      ],
    );
  }

  Widget _buildDateButton() {
    final hasDate = _selectedDate != null;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2025),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: _primaryBlue,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _currentPage = 0;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: hasDate ? _primaryBlue : const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate
                ? _primaryBlue
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: hasDate ? Colors.white : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasDate
                    ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                    : 'Semua Tanggal',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: hasDate ? Colors.white : Colors.grey[500],
                ),
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = null;
                  _currentPage = 0;
                }),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildSkeletonCard(index),
    );
  }

  Widget _buildSkeletonCard(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _shimmer(40, 40, radius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmer(120, 14),
                          const SizedBox(height: 6),
                          _shimmer(80, 10),
                        ],
                      ),
                    ),
                    _shimmer(70, 24, radius: 12),
                  ],
                ),
                const SizedBox(height: 12),
                _shimmer(double.infinity, 12),
                const SizedBox(height: 6),
                _shimmer(200, 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shimmer(double width, double height, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildJournalList(
      List<Map<String, dynamic>> journals, bool isSmall) {
    if (journals.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
                isSmall ? 12 : 16, 12, isSmall ? 12 : 16, 8),
            itemCount: journals.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (index * 60)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildJournalCard(journals[index], isSmall),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildPagination(journals.length, isSmall),
      ],
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> journal, bool isSmall) {
    final profile = journal['profiles'] ?? {};
    final studentId = journal['student_id'];
    final created = DateTime.parse(journal['created_at']).toLocal();
    final time = DateFormat('HH:mm').format(created);
    final date = DateFormat('dd MMM yyyy').format(created);
    final studentName = profile['full_name'] ?? 'Siswa';
    final isApproved = journal['is_approved'] == true;
    final className = profile['class_name'] ?? '-';
    final nisn = profile['nisn'] ?? '-';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (studentId != null) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => StudentJournalHistoryScreen(
                  studentId: studentId,
                  studentName: studentName,
                ),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOut)),
                    child: child,
                  );
                },
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isApproved
                        ? [Colors.green, Colors.green.shade300]
                        : [Colors.orange, Colors.orange.shade300],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: avatar + info + badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_accentBlue, _darkBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              studentName.isNotEmpty
                                  ? studentName[0].toUpperCase()
                                  : 'S',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _darkBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  _infoChip(Icons.class_rounded, className),
                                  const SizedBox(width: 6),
                                  _infoChip(Icons.badge_outlined, nisn),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        _statusBadge(isApproved),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Judul aktivitas
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.task_alt_rounded,
                              size: 15, color: _primaryBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              journal['activity_title'] ?? '-',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: _darkBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Deskripsi
                    Text(
                      journal['description'] ?? '-',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Footer
                    Row(
                      children: [
                        // Foto
                        _buildPhotoThumb(journal['evidence_photo']),
                        const Spacer(),
                        // Waktu
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _bgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 11, color: _primaryBlue.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                '$date · $time',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: _primaryBlue.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.grey[400]),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _statusBadge(bool isApproved) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isApproved
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isApproved
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            size: 11,
            color: isApproved ? Colors.green[600] : Colors.orange[600],
          ),
          const SizedBox(width: 4),
          Text(
            isApproved ? 'Disetujui' : 'Menunggu',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isApproved ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumb(String? url) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        image: url != null
            ? DecorationImage(
                image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url == null
          ? Icon(Icons.image_outlined, size: 16, color: Colors.grey[300])
          : null,
    );
  }

  Widget _buildPagination(int journalCount, bool isSmall) {
  return Padding(
    padding: EdgeInsets.fromLTRB(isSmall ? 12 : 16, 4, isSmall ? 12 : 16, 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tombol Sebelumnya
          _paginationButton(
            icon: Icons.arrow_back_ios_new_rounded,
            label: 'Sebelumnya',
            enabled: _currentPage > 0,
            onTap: () => setState(() => _currentPage--),
            isNext: false,
          ),

          const SizedBox(width: 16),

          // Nomor halaman besar di tengah
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryBlue, _darkBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${_currentPage + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Tombol Berikutnya
          _paginationButton(
            icon: Icons.arrow_forward_ios_rounded,
            label: 'Berikutnya',
            enabled: journalCount == _pageSize,
            onTap: () => setState(() => _currentPage++),
            isNext: true,
          ),
        ],
      ),
    ),
  );
}

  Widget _paginationButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool isNext = false,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: enabled ? _bgColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? _primaryBlue.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              if (!isNext) ...[
                Icon(icon, size: 12, color: _primaryBlue),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                ),
              ),
              if (isNext) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 12, color: _primaryBlue),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _bgColor,
                          _lightBlue,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.find_in_page_outlined,
                      size: 44,
                      color: _primaryBlue.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tidak ada jurnal',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _darkBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Coba ubah filter tanggal\natau pilih kelas lain',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[400],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 44, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _darkBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(dailyJournalsProvider((
                date: _selectedDate,
                className: _selectedClass,
                studentId: null,
                page: _currentPage,
              ))),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Coba Lagi',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}