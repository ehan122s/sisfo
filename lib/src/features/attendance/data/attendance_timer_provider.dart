import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// TIMER STATE
// ============================================================

class AttendanceTimerState {
  final DateTime? checkInTime;
  final Duration elapsed;
  final bool isRunning;

  const AttendanceTimerState({
    this.checkInTime,
    this.elapsed = Duration.zero,
    this.isRunning = false,
  });

  AttendanceTimerState copyWith({
    DateTime? checkInTime,
    Duration? elapsed,
    bool? isRunning,
  }) {
    return AttendanceTimerState(
      checkInTime: checkInTime ?? this.checkInTime,
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  String get elapsedFormatted {
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get elapsedReadable {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    if (h > 0) return '$h jam $m menit';
    return '$m menit';
  }
}

// ============================================================
// TIMER NOTIFIER — Menggunakan Notifier (Riverpod terbaru)
// ============================================================

class AttendanceTimerNotifier extends Notifier<AttendanceTimerState> {
  Timer? _timer;

  @override
  AttendanceTimerState build() {
    // Cleanup timer saat provider di-dispose
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const AttendanceTimerState();
  }

  /// Mulai timer dari waktu check-in
  void start(DateTime checkInTime) {
    _timer?.cancel();

    // Hitung elapsed awal
    final initialElapsed = DateTime.now().difference(checkInTime);

    state = AttendanceTimerState(
      checkInTime: checkInTime,
      elapsed: initialElapsed.isNegative ? Duration.zero : initialElapsed,
      isRunning: true,
    );

    // ✅ Timer.periodic update setiap 1 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isRunning && state.checkInTime != null) {
        final newElapsed = DateTime.now().difference(state.checkInTime!);
        state = state.copyWith(
          elapsed: newElapsed.isNegative ? Duration.zero : newElapsed,
        );
      }
    });
  }

  /// Stop timer (saat check-out)
  void stop() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
  }

  /// Reset timer
  void reset() {
    _timer?.cancel();
    _timer = null;
    state = const AttendanceTimerState();
  }
}

// ============================================================
// PROVIDER — Menggunakan NotifierProvider (bukan StateNotifierProvider)
// ============================================================

final attendanceTimerProvider =
    NotifierProvider<AttendanceTimerNotifier, AttendanceTimerState>(
  AttendanceTimerNotifier.new,
);