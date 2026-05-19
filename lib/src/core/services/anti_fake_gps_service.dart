import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// RISK LEVEL
// ============================================================

enum FakeGpsRisk { none, low, medium, high, critical }

// ============================================================
// DETECTION RESULT
// ============================================================

class FakeGpsDetectionResult {
  final FakeGpsRisk risk;
  final List<String> warnings;
  final bool isBlocked;
  final DateTime checkedAt;

  const FakeGpsDetectionResult({
    required this.risk,
    required this.warnings,
    required this.isBlocked,
    required this.checkedAt,
  });

  String get riskLabel {
    switch (risk) {
      case FakeGpsRisk.none:
        return 'Aman';
      case FakeGpsRisk.low:
        return 'Waspada';
      case FakeGpsRisk.medium:
        return 'Mencurigakan';
      case FakeGpsRisk.high:
        return 'Berbahaya';
      case FakeGpsRisk.critical:
        return 'Fake GPS!';
    }
  }

  bool get isClean => risk == FakeGpsRisk.none || risk == FakeGpsRisk.low;

  factory FakeGpsDetectionResult.safe() => FakeGpsDetectionResult(
        risk: FakeGpsRisk.none,
        warnings: const [],
        isBlocked: false,
        checkedAt: DateTime.now(),
      );
}

// ============================================================
// HELPER
// ============================================================

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

// ============================================================
// SERVICE
// ============================================================

class AntiFakeGpsService {
  static const MethodChannel _channel = MethodChannel('anti_fake_gps');

  static const double _maxReasonableSpeed = 50.0;       // m/s ~ 180 km/h
  static const double _suspiciousAccuracy = 1.5;        // metres — too perfect
  static const double _maxSampleJumpMeters = 80.0;
  static const double _maxSampleVarianceMeters = 50.0;
  static const double _minSampleVarianceMeters = 0.0001;

  StreamSubscription<Position>? _monitorStream;

  // Internal state for inter-call speed tracking
  Position? _lastPosition;
  DateTime? _lastPositionTime;

  // ============================================================
  // QUICK CHECK  (sync — called on every stream update)
  // ============================================================

  FakeGpsDetectionResult performQuickCheck(Position position) {
    final warnings = <String>[];
    var risk = FakeGpsRisk.none;

    // 1. isMocked flag (Android only — always false on web/iOS)
    if (!kIsWeb && position.isMocked) {
      warnings.add('📍 Lokasi ditandai MOCK oleh sistem');
      risk = _max(risk, FakeGpsRisk.critical);
    }

    // 2. Accuracy sanity
    final accCheck = _checkAccuracy(position);
    if (accCheck != null) {
      warnings.add(accCheck);
      risk = _max(risk, FakeGpsRisk.medium);
    }

    // 3. Speed field sanity
    final speedCheck = _checkSpeed(position);
    if (speedCheck != null) {
      warnings.add(speedCheck);
      risk = _max(risk, FakeGpsRisk.high);
    }

    // 4. Teleportation vs last observed position
    if (_lastPosition != null && _lastPositionTime != null) {
      final dist = _haversineDistance(
        _lastPosition!.latitude, _lastPosition!.longitude,
        position.latitude, position.longitude,
      );
      final secs = DateTime.now().difference(_lastPositionTime!).inSeconds;
      if (secs > 0 && secs < 300) {
        final speed = dist / secs;
        if (speed > _maxReasonableSpeed && dist > 50) {
          warnings.add(
            '🚀 Perpindahan tidak wajar: ${(speed * 3.6).toStringAsFixed(0)} km/h',
          );
          risk = _max(risk, FakeGpsRisk.high);
        }
      }
    }

    // 5. Altitude (skip on web — browser always returns 0)
    if (!kIsWeb) {
      final altCheck = _checkAltitude(position);
      if (altCheck != null) {
        warnings.add(altCheck);
        risk = _max(risk, FakeGpsRisk.low);
      }
    }

    // 6. Stale timestamp
    final timeCheck = _checkTimestamp(position);
    if (timeCheck != null) {
      warnings.add(timeCheck);
      risk = _max(risk, FakeGpsRisk.medium);
    }

    _lastPosition = position;
    _lastPositionTime = DateTime.now();

    return FakeGpsDetectionResult(
      risk: risk,
      warnings: warnings,
      isBlocked: risk.index >= FakeGpsRisk.high.index,
      checkedAt: DateTime.now(),
    );
  }

  // ============================================================
  // DEEP CHECK  (async — called once when screen opens)
  // ============================================================

  Future<FakeGpsDetectionResult> performDeepCheck(Position position) async {
    final quickResult = performQuickCheck(position);
    final warnings = List<String>.from(quickResult.warnings);
    var risk = quickResult.risk;

    // Platform-level checks (Android only via MethodChannel)
    if (_isAndroid) {
      final platformWarnings = await _performPlatformChecks();
      for (final w in platformWarnings) {
        warnings.add(w.warning);
        risk = _max(risk, w.isCritical ? FakeGpsRisk.high : FakeGpsRisk.low);
      }
    }

    // Inter-session location jump (vs last saved position in SharedPreferences)
    final lastPos = await _getLastPosition();
    final jumpCheck = _checkLocationJump(position, lastPos);
    if (jumpCheck != null) {
      warnings.add(jumpCheck);
      risk = _max(risk, FakeGpsRisk.high);
    }

    // Native-only heading / speedAccuracy sanity
    if (!kIsWeb) {
      if (position.speedAccuracy < 0) {
        warnings.add('📡 Data kecepatan GPS tidak valid');
        risk = _max(risk, FakeGpsRisk.low);
      }
      if (position.heading != 0.0 && position.speed < 0.5) {
        warnings.add('🧭 Heading aktif padahal perangkat diam — nilai simulasi?');
        risk = _max(risk, FakeGpsRisk.low);
      }
    }

    final isBlocked = risk.index >= FakeGpsRisk.high.index;
    if (!isBlocked) await _savePosition(position);

    return FakeGpsDetectionResult(
      risk: risk,
      warnings: warnings,
      isBlocked: isBlocked,
      checkedAt: DateTime.now(),
    );
  }

  // ============================================================
  // MULTI-SAMPLE VERIFICATION  (called just before submit)
  //
  // KEY FIX: Uses a single getPositionStream() instead of N sequential
  // getCurrentPosition() calls.
  //
  // Old (slow) pattern — your original code:
  //   for i in 0..2:
  //     await getCurrentPosition(timeLimit: 10s)   ← up to 10s per call
  //     await Future.delayed(2s)                   ← extra 2s gap
  //   Worst case = 3×10s + 2×2s = 34 seconds
  //
  // New (fast) pattern:
  //   Open one stream → collect N events → cancel
  //   Browser resolves location once; subsequent events arrive quickly.
  //   Typical time on web = 2–4 seconds for 3 samples.
  // ============================================================

  Future<FakeGpsDetectionResult> performMultiSampleVerification({
    int sampleCount = 3,
    Duration interval = const Duration(seconds: 2),
  }) async {
    final warnings = <String>[];
    var risk = FakeGpsRisk.none;
    List<Position> samples = [];

    try {
      samples = await _collectSamplesViaStream(
        sampleCount: sampleCount,
        timeout: interval * sampleCount + const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('⚠️ Multi-sample error: $e');
      if (_lastPosition != null) return performDeepCheck(_lastPosition!);
      return FakeGpsDetectionResult.safe();
    }

    if (samples.isEmpty) {
      return FakeGpsDetectionResult(
        risk: FakeGpsRisk.medium,
        warnings: ['⚠️ Tidak ada data GPS yang berhasil diambil'],
        isBlocked: false,
        checkedAt: DateTime.now(),
      );
    }

    // ── 1. isMocked in ANY sample ──────────────────────────────────────────
    if (!kIsWeb && samples.any((p) => p.isMocked)) {
      return FakeGpsDetectionResult(
        risk: FakeGpsRisk.critical,
        warnings: ['📍 Mock location terdeteksi pada salah satu sample GPS'],
        isBlocked: true,
        checkedAt: DateTime.now(),
      );
    }

    // ── 2. Inter-sample jump & speed ──────────────────────────────────────
    for (int i = 1; i < samples.length; i++) {
      final prev = samples[i - 1];
      final curr = samples[i];

      final distance = Geolocator.distanceBetween(
        prev.latitude, prev.longitude,
        curr.latitude, curr.longitude,
      );
      final secs = curr.timestamp.difference(prev.timestamp).inSeconds.abs();

      if (distance > _maxSampleJumpMeters &&
          prev.speed < 1.0 &&
          curr.speed < 1.0) {
        warnings.add('🚀 Lonjakan lokasi tidak wajar antar sample');
        risk = _max(risk, FakeGpsRisk.critical);
      }

      if (secs > 0) {
        final speed = distance / secs;
        if (speed > _maxReasonableSpeed && distance > 50) {
          warnings.add(
            '🏎️ Kecepatan antar-sample: ${(speed * 3.6).toStringAsFixed(0)} km/h',
          );
          risk = _max(risk, FakeGpsRisk.high);
        }
      }
    }

    // ── 3. Variance check (real GPS always drifts a little) ───────────────
    if (samples.length >= 2 && !kIsWeb) {
      final latVar = _variance(samples.map((p) => p.latitude).toList());
      final lngVar = _variance(samples.map((p) => p.longitude).toList());
      final varianceMeters = sqrt(latVar + lngVar) * 111000;

      if (varianceMeters < _minSampleVarianceMeters) {
        warnings.add('📍 Posisi sama persis di semua sample — mencurigakan');
        risk = _max(risk, FakeGpsRisk.medium);
      } else if (varianceMeters > _maxSampleVarianceMeters) {
        warnings.add(
          '📡 GPS tidak stabil (jitter ${varianceMeters.toStringAsFixed(1)}m)',
        );
        risk = _max(risk, FakeGpsRisk.medium);
      }
    }

    // ── 4. Deep check on final sample ─────────────────────────────────────
    final deep = await performDeepCheck(samples.last);
    for (final w in deep.warnings) {
      if (!warnings.contains(w)) warnings.add(w);
    }
    risk = _max(risk, deep.risk);

    return FakeGpsDetectionResult(
      risk: risk,
      warnings: warnings.toSet().toList(),
      isBlocked: risk.index >= FakeGpsRisk.high.index,
      checkedAt: DateTime.now(),
    );
  }

  // ============================================================
  // REAL-TIME MONITORING
  // ============================================================

  void startRealTimeMonitoring({
    required void Function(FakeGpsDetectionResult result) onFakeDetected,
    required void Function(Position position) onPositionUpdate,
  }) {
    stopMonitoring();
    _monitorStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(
      (position) {
        final result = performQuickCheck(position);
        if (result.isBlocked) {
          onFakeDetected(result);
          stopMonitoring();
          return;
        }
        onPositionUpdate(position);
      },
      onError: (e) => debugPrint('🔴 Monitor error: $e'),
    );
  }

  void stopMonitoring() {
    _monitorStream?.cancel();
    _monitorStream = null;
  }

  // ============================================================
  // PRIVATE: STREAM-BASED SAMPLE COLLECTION
  // ============================================================

  Future<List<Position>> _collectSamplesViaStream({
    required int sampleCount,
    required Duration timeout,
  }) async {
    final collected = <Position>[];
    final completer = Completer<List<Position>>();

    final sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(
      (pos) {
        collected.add(pos);
        if (collected.length >= sampleCount && !completer.isCompleted) {
          completer.complete(List.from(collected));
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(List.from(collected));
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await sub.cancel();
    }
  }

  // ============================================================
  // PRIVATE: CHECK METHODS
  // ============================================================

  String? _checkAccuracy(Position position) {
    if (position.accuracy <= 0) return '📡 Akurasi GPS tidak valid';
    if (!kIsWeb &&
        position.accuracy < _suspiciousAccuracy &&
        position.speed <= 0.5) {
      return '📡 Akurasi terlalu sempurna (${position.accuracy.toStringAsFixed(1)}m)';
    }
    return null;
  }

  String? _checkSpeed(Position position) {
    if (position.speed > _maxReasonableSpeed) {
      return '🏎️ Kecepatan GPS tidak wajar: ${(position.speed * 3.6).toStringAsFixed(0)} km/h';
    }
    return null;
  }

  String? _checkAltitude(Position position) {
    if (position.altitude < -50 || position.altitude > 5500) {
      return '⛰️ Altitude tidak wajar: ${position.altitude.toStringAsFixed(0)}m';
    }
    return null;
  }

  String? _checkTimestamp(Position position) {
    final diff = DateTime.now().difference(position.timestamp).inSeconds;
    if (diff > 30) return '⏰ Data lokasi sudah basi (${diff}s yang lalu)';
    return null;
  }

  String? _checkLocationJump(Position current, Position? last) {
    if (last == null) return null;
    final timeDiff =
        current.timestamp.difference(last.timestamp).inSeconds.abs();
    if (timeDiff < 5) return null;

    final distance = Geolocator.distanceBetween(
      last.latitude, last.longitude,
      current.latitude, current.longitude,
    );
    if (timeDiff > 0) {
      final speed = distance / timeDiff;
      if (speed > _maxReasonableSpeed && distance > 50) {
        return '🚀 Perpindahan antar-sesi tidak wajar';
      }
    }
    return null;
  }

  // ============================================================
  // PRIVATE: PLATFORM CHECKS
  // ============================================================

  Future<List<_PlatformWarning>> _performPlatformChecks() async {
    final results = <_PlatformWarning>[];
    try {
      final devEnabled =
          await _channel.invokeMethod<bool>('isDeveloperOptionsEnabled');
      if (devEnabled == true) {
        results.add(const _PlatformWarning(
          warning: '🔧 Developer mode aktif — fake GPS lebih mudah digunakan',
          isCritical: false,
        ));
      }
    } catch (_) {
      // MethodChannel not set up (iOS / web) — ignore
    }
    return results;
  }

  // ============================================================
  // PRIVATE: SHARED PREFERENCES STORAGE
  // ============================================================

  Future<Position?> _getLastPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('_afg_last_lat');
      final lng = prefs.getDouble('_afg_last_lng');
      final ts = prefs.getInt('_afg_last_ts');
      if (lat == null || lng == null) return null;
      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.fromMillisecondsSinceEpoch(ts ?? 0),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePosition(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('_afg_last_lat', position.latitude);
      await prefs.setDouble('_afg_last_lng', position.longitude);
      await prefs.setInt(
          '_afg_last_ts', position.timestamp.millisecondsSinceEpoch);
    } catch (_) {}
  }

  // ============================================================
  // PRIVATE: MATH HELPERS
  // ============================================================

  FakeGpsRisk _max(FakeGpsRisk a, FakeGpsRisk b) =>
      a.index >= b.index ? a : b;

  double _haversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const r = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLambda = (lon2 - lon1) * pi / 180;
    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _variance(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values
            .map((v) => pow(v - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    stopMonitoring();
  }
}

// ============================================================
// INTERNAL MODEL
// ============================================================

class _PlatformWarning {
  final String warning;
  final bool isCritical;
  const _PlatformWarning({required this.warning, required this.isCritical});
}