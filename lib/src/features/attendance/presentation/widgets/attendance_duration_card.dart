import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/attendance_timer_provider.dart';
import '../../data/attendance_repository.dart';
import '../../../../authentication/data/auth_repository.dart';

class AttendanceDurationCard extends ConsumerStatefulWidget {
  const AttendanceDurationCard({super.key});

  @override
  ConsumerState<AttendanceDurationCard> createState() => _AttendanceDurationCardState();
}

class _AttendanceDurationCardState extends ConsumerState<AttendanceDurationCard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => _loadTodayAttendance());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    // Saat app kembali ke foreground, recalculate elapsed
    if (appState == AppLifecycleState.resumed) {
      final timerState = ref.read(attendanceTimerProvider);
      if (timerState.isRunning && timerState.checkInTime != null) {
        ref.read(attendanceTimerProvider.notifier).start(timerState.checkInTime!);
      }
    }
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      final log = await ref.read(attendanceRepositoryProvider).getTodaysLog(user.id);

      if (log != null && log['check_in_time'] != null && log['check_out_time'] == null) {
        final checkInTime = DateTime.parse(log['check_in_time'].toString());
        ref.read(attendanceTimerProvider.notifier).start(checkInTime);
      } else {
        ref.read(attendanceTimerProvider.notifier).reset();
      }
    } catch (e) {
      debugPrint('❌ Error loading today attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(attendanceTimerProvider);
    final logAsync = ref.watch(todaysAttendanceLogProvider);

    return logAsync.when(
      data: (log) {
        final hasCheckedIn = log != null && log['check_in_time'] != null;
        final hasCheckedOut = log != null && log['check_out_time'] != null;

        if (!hasCheckedIn) return _buildNotCheckedIn();
        if (hasCheckedOut) return _buildCheckedOut(log);
        return _buildWorking(timerState, log);
      },
      loading: () => _buildLoading(),
      error: (_, __) => _buildNotCheckedIn(),
    );
  }

  Widget _buildNotCheckedIn() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.timer_off, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Durasi Kerja', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey)),
                Text('Belum absen masuk', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorking(AttendanceTimerState timerState, dynamic log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.timer, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Durasi Kerja', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white70)),
                    Text(timerState.elapsedReadable, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60)),
                  ],
                ),
              ),
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 6)]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(
              timerState.elapsedFormatted,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4),
            ),
          ),
          const SizedBox(height: 8),
          if (timerState.checkInTime != null)
            Text('Masuk: ${_formatTime(timerState.checkInTime!)}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildCheckedOut(dynamic log) {
    String totalDuration = '-';
    if (log['check_in_time'] != null && log['check_out_time'] != null) {
      try {
        final checkIn = DateTime.parse(log['check_in_time'].toString());
        final checkOut = DateTime.parse(log['check_out_time'].toString());
        final dur = checkOut.difference(checkIn);
        final h = dur.inHours.toString().padLeft(2, '0');
        final m = (dur.inMinutes % 60).toString().padLeft(2, '0');
        totalDuration = '$h:$m';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Durasi Kerja', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.green.shade800)), Text('Total: $totalDuration', style: GoogleFonts.poppins(fontSize: 12, color: Colors.green.shade600))])),
          Text('✅ Selesai', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}