import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// RISK LEVEL
// ============================================================

enum FakeGpsRisk {
  none,     // Tidak ada tanda fake GPS
  low,      // Tanda minor (developer mode)
  medium,   // Beberapa tanda mencurigakan
  high,     // Tanda kuat fake GPS → BLOCK
  critical, // Terbukti fake GPS → BLOCK
}

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
}

// ============================================================
// ANTI FAKE GPS SERVICE
// ============================================================

class AntiFakeGpsService {
  static const MethodChannel _channel = MethodChannel('anti_fake_gps');

  /// Paket aplikasi fake GPS yang umum
  static const _knownFakeGpsPackages = [
    'com.lexa.fakegps',
    'com.incorporateapps.fakegps.fre',
    'com.blogspot.newapphorizons.fakegps',
    'com.theappninjas.fakegpsgo',
    'com.gpsemulator',
    'com.fakegps.mocklocation',
    'com.fakegps.fakegps',
    'com.fake.location',
    'io.appfly.fakegps',
    'com.fakegps.go',
    'com.rosteam.fakegps',
    'com.lkr.fakegps',
    'ru.gavrikov.mockgeofix',
    'com.github.warren_bank.mock_location',
    'com.fakegps.trick',
    'com.change.location.fake.gps',
    'fakegps.fakelocation.gpschanger',
    'com.fake.gps.location.spoofer',
    'com.fakegps.location.change',
    'com.mock.location.fake.gps.go',
  ];

  /// Kecepatan maksimal wajar (m/s) — ~180 km/jam (kereta cepat)
  static const double _maxReasonableSpeed = 50.0;

  /// Akurasi yang terlalu sempurna (fake GPS sering report 0-1m)
  static const double _suspiciousAccuracy = 1.5;

  /// Stream untuk monitoring real-time
  StreamSubscription<Position>? _monitorStream;

  // --------------------------------------------------------
  // QUICK CHECK — Cepat, untuk pengecekan awal
  // --------------------------------------------------------

  FakeGpsDetectionResult performQuickCheck(Position position) {
    final warnings = <String>[];
    var risk = FakeGpsRisk.none;

    // 1. Cek isMocked flag (PALING PENTING)
    if (position.isMocked) {
      warnings.add('📍 Lokasi ditandai sebagai MOCK oleh sistem');
      risk = FakeGpsRisk.critical;
    }

    // 2. Cek akurasi anomali
    final accCheck = _checkAccuracy(position);
    if (accCheck != null) {
      warnings.add(accCheck);
      if (risk.index < FakeGpsRisk.medium.index) {
        risk = FakeGpsRisk.medium;
      }
    }

    // 3. Cek kecepatan anomali
    final speedCheck = _checkSpeed(position);
    if (speedCheck != null) {
      warnings.add(speedCheck);
      if (risk.index < FakeGpsRisk.high.index) {
        risk = FakeGpsRisk.high;
      }
    }

    // 4. Cek altitude anomali
    final altCheck = _checkAltitude(position);
    if (altCheck != null) {
      warnings.add(altCheck);
      if (risk.index < FakeGpsRisk.low.index) {
        risk = FakeGpsRisk.low;
      }
    }

    // 5. Cek timestamp
    final timeCheck = _checkTimestamp(position);
    if (timeCheck != null) {
      warnings.add(timeCheck);
      if (risk.index < FakeGpsRisk.medium.index) {
        risk = FakeGpsRisk.medium;
      }
    }

    // Decision: block untuk high dan critical
    final isBlocked = risk.index >= FakeGpsRisk.high.index;

    return FakeGpsDetectionResult(
      risk: risk,
      warnings: warnings,
      isBlocked: isBlocked,
      checkedAt: DateTime.now(),
    );
  }

  // --------------------------------------------------------
  // DEEP CHECK — Termasuk platform-specific checks
  // --------------------------------------------------------

  Future<FakeGpsDetectionResult> performDeepCheck(Position position) async {
    // Mulai dari quick check
    final quickResult = performQuickCheck(position);
    final warnings = List<String>.from(quickResult.warnings);
    var risk = quickResult.risk;

    // Platform checks (Android only)
    if (Platform.isAndroid) {
      final platformWarnings = await _performPlatformChecks();
      for (final w in platformWarnings) {
        warnings.add(w.warning);
        if (w.isCritical && risk.index < FakeGpsRisk.high.index) {
          risk = FakeGpsRisk.high;
        } else if (!w.isCritical && risk.index < FakeGpsRisk.low.index) {
          risk = FakeGpsRisk.low;
        }
      }
    }

    // Location jump check (dengan posisi terakhir yang tersimpan)
    final lastPos = await _getLastPosition();
    final jumpCheck = _checkLocationJump(position, lastPos);
    if (jumpCheck != null) {
      warnings.add(jumpCheck);
      if (risk.index < FakeGpsRisk.high.index) {
        risk = FakeGpsRisk.high;
      }
    }

    final isBlocked = risk.index >= FakeGpsRisk.high.index;

    // Simpan posisi jika bersih
    if (!isBlocked) {
      await _savePosition(position);
    }

    return FakeGpsDetectionResult(
      risk: risk,
      warnings: warnings,
      isBlocked: isBlocked,
      checkedAt: DateTime.now(),
    );
  }

  // --------------------------------------------------------
  // MULTI-SAMPLE VERIFICATION
  // Mengambil beberapa sample dan membandingkan konsistensi
  // --------------------------------------------------------

  Future<FakeGpsDetectionResult> performMultiSampleVerification({
    int sampleCount = 3,
    Duration interval = const Duration(seconds: 2),
  }) async {
    final warnings = <String>[];
    final positions = <Position>[];
    var risk = FakeGpsRisk.none;

    // Ambil beberapa sample
    for (int i = 0; i < sampleCount; i++) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        positions.add(position);

        // Cek setiap sample untuk mock flag
        if (position.isMocked) {
          return FakeGpsDetectionResult(
            risk: FakeGpsRisk.critical,
            warnings: ['📍 Sample #${i + 1}: Lokasi MOCK terdeteksi!'],
            isBlocked: true,
            checkedAt: DateTime.now(),
          );
        }

        if (i < sampleCount - 1) {
          await Future.delayed(interval);
        }
      } catch (e) {
        warnings.add('⚠️ Gagal mengambil sample #${i + 1}: $e');
      }
    }

    if (positions.length < 2) {
      warnings.add('⚠️ Tidak cukup sample lokasi untuk verifikasi');
      if (risk.index < FakeGpsRisk.medium.index) risk = FakeGpsRisk.medium;
    }

    // Analisis konsistensi antar sample
    if (positions.length >= 2) {
      for (int i = 1; i < positions.length; i++) {
        final prev = positions[i - 1];
        final curr = positions[i];

        final dist = Geolocator.distanceBetween(
          prev.latitude, prev.longitude,
          curr.latitude, curr.longitude,
        );

        final timeDiff = curr.timestamp.difference(prev.timestamp).inSeconds;
        final speed = timeDiff > 0 ? dist / timeDiff : 0.0;

        // Jika kecepatan terlaporan rendah tapi lokasi lompat
        if (dist > 80 && prev.speed < 1.0 && curr.speed < 1.0) {
          warnings.add(
            '🚀 Lonjakan lokasi tidak wajar: ${dist.toStringAsFixed(0)}m '
            '(kecepatan dilaporkan ~${(curr.speed * 3.6).toStringAsFixed(1)} km/j)',
          );
          if (risk.index < FakeGpsRisk.critical.index) {
            risk = FakeGpsRisk.critical;
          }
        }

        // Kecepatan tidak wajar
        if (speed > _maxReasonableSpeed && dist > 50) {
          warnings.add(
            '🏎️ Kecepatan tidak wajar: ${(speed * 3.6).toStringAsFixed(0)} km/j',
          );
          if (risk.index < FakeGpsRisk.high.index) {
            risk = FakeGpsRisk.high;
          }
        }

        // Akurasi terlalu konsisten (fake GPS sering report akurasi sama persis)
        final accDiff = (curr.accuracy - prev.accuracy).abs();
        if (accDiff < 0.01 && curr.accuracy < 5.0 && prev.accuracy < 5.0) {
          warnings.add(
            '📡 Akurasi terlalu konsisten (${curr.accuracy.toStringAsFixed(2)}m) — mencurigakan',
          );
          if (risk.index < FakeGpsRisk.medium.index) {
            risk = FakeGpsRisk.medium;
          }
        }

        // Koordinat terlalu identik (fake GPS kadang return exact same coords)
        final latDiff = (curr.latitude - prev.latitude).abs();
        final lngDiff = (curr.longitude - prev.longitude).abs();
        if (latDiff < 0.0000001 && lngDiff < 0.0000001 && curr.accuracy < 3.0) {
          warnings.add('📍 Koordinat identik sempurna antar sample — mencurigakan');
          if (risk.index < FakeGpsRisk.medium.index) {
            risk = FakeGpsRisk.medium;
          }
        }
      }
    }

    // Juga jalankan deep check pada sample terakhir
    if (positions.isNotEmpty) {
      final deepResult = await performDeepCheck(positions.last);
      warnings.addAll(deepResult.warnings);
      if (deepResult.risk.index > risk.index) {
        risk = deepResult.risk;
      }
    }

    final isBlocked = risk.index >= FakeGpsRisk.high.index;

    return FakeGpsDetectionResult(
      risk: risk,
      warnings: warnings.toSet().toList(), // Hapus duplikat
      isBlocked: isBlocked,
      checkedAt: DateTime.now(),
    );
  }

  // --------------------------------------------------------
  // REAL-TIME MONITORING
  // Monitoring posisi secara live untuk deteksi fake GPS
  // yang diaktifkan saat screen terbuka
  // --------------------------------------------------------

  void startRealTimeMonitoring({
    required void Function(FakeGpsDetectionResult result) onFakeDetected,
    required void Function(Position position) onPositionUpdate,
  }) {
    stopMonitoring(); // Hentikan monitoring sebelumnya jika ada

    _monitorStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(
      (Position position) {
        // Cek setiap update posisi
        final result = performQuickCheck(position);

        if (result.isBlocked) {
          onFakeDetected(result);
          stopMonitoring(); // Berhenti monitoring setelah deteksi
          return;
        }

        onPositionUpdate(position);
      },
      onError: (error) {
        debugPrint('🔴 Monitor error: $error');
      },
    );
  }

  void stopMonitoring() {
    _monitorStream?.cancel();
    _monitorStream = null;
  }

  // --------------------------------------------------------
  // INDIVIDUAL CHECK METHODS
  // --------------------------------------------------------

  /// Cek: isMocked flag dari Geolocator
  String? _checkMockFlag(Position position) {
    if (position.isMocked) {
      return '📍 Lokasi ditandai MOCK oleh sistem';
    }
    return null;
  }

  /// Cek: Akurasi terlalu sempurna (fake GPS report 0-1m)
  String? _checkAccuracy(Position position) {
    if (position.accuracy <= 0) {
      return '📡 Akurasi tidak valid: ${position.accuracy.toStringAsFixed(1)}m';
    }
    if (position.accuracy < _suspiciousAccuracy && position.speed <= 0.5) {
      return '📡 Akurasi mencurigakan terlalu sempurna: '
          '${position.accuracy.toStringAsFixed(2)}m (real GPS biasanya 5-20m)';
    }
    return null;
  }

  /// Cek: Kecepatan tidak wajar
  String? _checkSpeed(Position position) {
    if (position.speed > _maxReasonableSpeed) {
      return '🏎️ Kecepatan dilaporkan ${(position.speed * 3.6).toStringAsFixed(0)} km/j — tidak wajar';
    }
    return null;
  }

  /// Cek: Altitude di luar jangkauan Indonesia
  String? _checkAltitude(Position position) {
    // Indonesia: -10m (laut) sampai 5000m (gunung)
    // Kebanyakan kota: 0-500m
    if (position.altitude < -50 || position.altitude > 5500) {
      return '⛰️ Altitude tidak wajar: ${position.altitude.toStringAsFixed(0)}m';
    }
    return null;
  }

  /// Cek: Timestamp lokasi basi atau di masa depan
  String? _checkTimestamp(Position position) {
    final now = DateTime.now();
    final diff = now.difference(position.timestamp).inSeconds;

    if (position.timestamp.isAfter(now.add(const Duration(seconds: 5)))) {
      return '⏰ Timestamp lokasi di masa depan — tidak valid';
    }

    if (diff > 30) {
      return '⏰ Data lokasi basi: ${diff}s yang lalu';
    }

    return null;
  }

  /// Cek: Lompatan lokasi dari posisi terakhir yang tersimpan
  String? _checkLocationJump(Position current, Position? last) {
    if (last == null) return null;

    final timeDiffSec = current.timestamp.difference(last.timestamp).inSeconds.abs();
    if (timeDiffSec < 5) return null; // Terlalu dekat waktu, skip

    final distance = Geolocator.distanceBetween(
      last.latitude, last.longitude,
      current.latitude, current.longitude,
    );

    final speed = distance / timeDiffSec; // m/s

    // Jika kecepatan > 180 km/jam dan jarak > 50m → tidak wajar
    if (speed > _maxReasonableSpeed && distance > 50) {
      return '🚀 Perpindahan tidak wajar: ${(speed * 3.6).toStringAsFixed(0)} km/j '
          '(${distance.toStringAsFixed(0)}m dalam ${timeDiffSec}s)';
    }

    return null;
  }

  // --------------------------------------------------------
  // PLATFORM-SPECIFIC CHECKS (Android via MethodChannel)
  // --------------------------------------------------------

  Future<List<_PlatformWarning>> _performPlatformChecks() async {
    final results = <_PlatformWarning>[];

    try {
      // 1. Cek Developer Options
      final devEnabled = await _channel.invokeMethod<bool>('isDeveloperOptionsEnabled');
      if (devEnabled == true) {
        results.add(_PlatformWarning(
          warning: '🔧 Developer Options aktif',
          isCritical: false,
        ));
      }

      // 2. Cek aplikasi mock location yang dipilih (Android < 12)
      final mockApp = await _channel.invokeMethod<String>('getMockLocationApp');
      if (mockApp != null && mockApp.isNotEmpty) {
        results.add(_PlatformWarning(
          warning: '📱 Aplikasi mock location terpasang: $mockApp',
          isCritical: true,
        ));
      }

      // 3. Cek aplikasi fake GPS yang terinstal
      final fakeApps = await _channel.invokeMethod<List>('getInstalledFakeGpsApps');
      if (fakeApps != null && fakeApps.isNotEmpty) {
        final appNames = fakeApps.cast<String>().join(', ');
        results.add(_PlatformWarning(
          warning: '⚠️ Aplikasi fake GPS terdeteksi: $appNames',
          isCritical: true,
        ));
      }

      // 4. Cek VPN (beberapa fake GPS menggunakan VPN)
      final isVpn = await _channel.invokeMethod<bool>('isVpnActive');
      if (isVpn == true) {
        results.add(_PlatformWarning(
          warning: '🔐 VPN aktif (beberapa aplikasi fake GPS menggunakan VPN)',
          isCritical: false,
        ));
      }
    } on PlatformException catch (e) {
      debugPrint('🔴 Platform check error: ${e.message}');
    } on MissingPluginException {
      debugPrint('⚠️ Native anti-fake GPS not implemented for this platform');
    }

    return results;
  }

  // --------------------------------------------------------
  // PERSISTENCE — Simpan posisi terakhir untuk deteksi jump
  // --------------------------------------------------------

  Future<Position?> _getLastPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('_afg_last_lat');
      final lng = prefs.getDouble('_afg_last_lng');
      final ts = prefs.getInt('_afg_last_ts');

      if (lat == null || lng == null) return null;

      // Hanya gunakan jika data < 24 jam
      if (ts != null) {
        final lastTime = DateTime.fromMillisecondsSinceEpoch(ts);
        final age = DateTime.now().difference(lastTime);
        if (age.inHours > 24) return null;
      }

      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: ts != null
            ? DateTime.fromMillisecondsSinceEpoch(ts)
            : DateTime.now(),
        accuracy: prefs.getDouble('_afg_last_acc') ?? 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: false,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePosition(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('_afg_last_lat', position.latitude);
      await prefs.setDouble('_afg_last_lng', position.longitude);
      await prefs.setDouble('_afg_last_acc', position.accuracy);
      await prefs.setInt('_afg_last_ts', position.timestamp.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving position: $e');
    }
  }

  // --------------------------------------------------------
  // DISPOSE
  // --------------------------------------------------------

  void dispose() {
    stopMonitoring();
  }
}

// Helper class untuk platform warnings
class _PlatformWarning {
  final String warning;
  final bool isCritical;

  const _PlatformWarning({
    required this.warning,
    required this.isCritical,
  });
}