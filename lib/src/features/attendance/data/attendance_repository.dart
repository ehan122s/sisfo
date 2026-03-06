import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../../services/supabase_config.dart';
import '../../authentication/data/auth_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/exceptions/app_exceptions.dart';

import '../../offline/data/offline_queue_repository.dart';
import '../../../services/device_info_service.dart';

class AttendanceRepository {
  final SupabaseClient _supabase = supabase;
  final OfflineQueueRepository _queueRepository;
  final DeviceInfoService _deviceInfoService;

  AttendanceRepository(this._queueRepository, this._deviceInfoService);

  // 1. Get Current Location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // Check for Mock Location (Basic Check)
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (position.isMocked) {
      throw Exception('Fake GPS Detected! Attendance requires real location.');
    }

    return position;
  }

  // 2. Calculate Distance (in Meters)
  double calculateDistance(
    double startLat,
    double startLong,
    double endLat,
    double endLong,
  ) {
    return Geolocator.distanceBetween(startLat, startLong, endLat, endLong);
  }

  // 2b. Velocity Check (Anti-Fake GPS)
  Future<void> _validateVelocity({
    required String studentId,
    required double currentLat,
    required double currentLong,
    required DateTime currentTime,
  }) async {
    try {
      // Get the last known location from the LATEST log
      final response = await _supabase
          .from('attendance_logs')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return; // First time, no history

      double prevLat;
      double prevLong;
      DateTime prevTime;

      // Check if the last log has a checkout time (most recent activity)
      if (response['check_out_time'] != null &&
          response['check_out_lat'] != null &&
          response['check_out_long'] != null) {
        prevLat = (response['check_out_lat'] as num).toDouble();
        prevLong = (response['check_out_long'] as num).toDouble();
        prevTime = DateTime.parse(response['check_out_time']).toLocal();
      } else if (response['check_in_lat'] != null &&
          response['check_in_long'] != null) {
        // Otherwise use the check-in time
        prevLat = (response['check_in_lat'] as num).toDouble();
        prevLong = (response['check_in_long'] as num).toDouble();
        prevTime = DateTime.parse(response['check_in_time']).toLocal();
      } else {
        // No valid previous coordinates, skip validation
        return;
      }

      final distanceMeters = calculateDistance(
        prevLat,
        prevLong,
        currentLat,
        currentLong,
      );

      final timeDiffSeconds = currentTime.difference(prevTime).inSeconds.abs();

      // Avoid division by zero
      if (timeDiffSeconds == 0) return;

      final speedMps = distanceMeters / timeDiffSeconds;

      // Threshold: 500 m/s (~1,800 km/h) - Allow GPS drift but catch teleportation
      // Relaxed from 250 m/s to reduce false positives from GPS jumps/drift
      // ADDED: Ignore validation if distance is small (< 1000m).
      // GPS jitter in the same building can be 50-100m in < 1 sec (high calculated speed).
      // We only care about "Teleportation" between Home and School (usually km away).
      if (speedMps > 500 && distanceMeters > 1000) {
        print(
          'Suspicious Speed Detected: ${speedMps.toStringAsFixed(2)} m/s over ${distanceMeters.toStringAsFixed(2)} m',
        );
        // Optional: Don't throw, just log. Or throw only for extreme cases.
        // For "Best Practice" requested by user:
        // We will throw ONLY if it's blatantly obvious teleportation (>1km in seconds).
        throw ValidationException(
          'Terdeteksi perpindahan lokasi tidak wajar! (${speedMps.toStringAsFixed(0)} m/s). Silakan coba lagi.',
        );
      }
    } catch (e) {
      if (e is ValidationException) rethrow;
      // If query fails or other error, log it but don't block
      // For security, we could block, but for user experience we'll allow it
      // and just log the error
      print('Velocity validation error: $e');
      // Don't throw - allow attendance to proceed if validation fails due to technical issues
      return;
    }
  }

  // 3. Upload Photo
  Future<String> uploadSelfie(File imageFile, String userId) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'selfies/$fileName';

    await _supabase.storage.from('attendances').upload(filePath, imageFile);

    // Get Public URL
    final imageUrl = _supabase.storage
        .from('attendances')
        .getPublicUrl(filePath);
    return imageUrl;
  }

  // 4. Check In (RPC)
  Future<String> checkIn({
    required String studentId,
    required double lat,
    required double long,
    required String photoUrl,
  }) async {
    // Check Connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      await _queueRepository.addToQueue({
        'type': 'check_in',
        'student_id': studentId,
        'lat': lat,
        'long': long,
        'photo_path': photoUrl,
      });
      throw OfflineException();
    }

    try {
      // Security Check: Velocity
      await _validateVelocity(
        studentId: studentId,
        currentLat: lat,
        currentLong: long,
        currentTime: DateTime.now(),
      );

      final deviceId = await _deviceInfoService.getDeviceId();

      final response = await _supabase.rpc(
        'submit_check_in',
        params: {
          'p_student_id': studentId,
          'p_lat': lat,
          'p_long': long,
          'p_photo_url': photoUrl,
          'p_device_id': deviceId,
        },
      );

      if (response['success'] == false) {
        throw Exception(response['message']);
      }
      return response['message'] as String;
    } on SocketException {
      throw OfflineException();
    } catch (e) {
      if (e is OfflineException) rethrow; // Already typed
      throw ServerException('Check In Gagal: ${e.toString()}');
    }
  }

  // 4b. Check Out
  Future<void> checkOut({
    required String studentId,
    required double lat,
    required double long,
    String? photoUrl, // Optional for checkout
  }) async {
    // Check Connectivity
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await _queueRepository.addToQueue({
          'type': 'check_out',
          'student_id': studentId,
          'lat': lat,
          'long': long,
          'photo_path': photoUrl,
          'timestamp': DateTime.now().toIso8601String(),
        });
        throw OfflineException();
      }
    } catch (e) {
      if (e is OfflineException) rethrow;
    }

    try {
      final deviceId = await _deviceInfoService.getDeviceId();

      final response = await _supabase.rpc(
        'submit_check_out',
        params: {
          'p_student_id': studentId,
          'p_lat': lat,
          'p_long': long,
          'p_photo_url': photoUrl,
          'p_device_id': deviceId,
        },
      );

      if (response['success'] == false) {
        // If server says "Belum waktunya", we can throw ValidationException
        // so UI shows it nicely.
        throw ValidationException(response['message']);
      }
    } on SocketException {
      throw OfflineException();
    } catch (e) {
      if (e is OfflineException) rethrow;
      if (e is ValidationException) rethrow;
      throw ServerException('Check Out Gagal: ${e.toString()}');
    }
  }

  // 5. Check if already checked in today
  Future<bool> hasCheckedInToday(String studentId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await _supabase
        .from('attendance_logs')
        .select()
        .eq('student_id', studentId)
        .gte('created_at', '$today 00:00:00')
        .lte('created_at', '$today 23:59:59')
        .limit(1);

    return (response as List).isNotEmpty;
  }

  // 6. Get Student Placement & Company Location
  Future<Map<String, dynamic>?> getStudentPlacement(String studentId) async {
    final response = await _supabase
        .from('placements')
        .select(
          'id, companies(name, latitude, longitude, radius_meter, address)',
        )
        .eq('student_id', studentId)
        .maybeSingle(); // Returns null if no placement found

    return response;
  }

  // 7. Get My Attendance History (Paginated)
  Future<List<Map<String, dynamic>>> getMyAttendanceHistory({
    required String studentId,
    int page = 0,
    int pageSize = 10,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final response = await _supabase
        .from('attendance_logs')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(response);
  }

  // 8. Get Real-time Attendance Stream
  Stream<List<Map<String, dynamic>>> getAttendanceStream(String studentId) {
    return _supabase
        .from('attendance_logs')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(10); // Limit to recent logs to save bandwidth
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(
    ref.watch(offlineQueueRepositoryProvider),
    ref.watch(deviceInfoServiceProvider),
  );
});

// Returns null if no log, otherwise returns the log (including check_out_time)
final todaysAttendanceLogProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) return Stream.value(null);

      final repository = ref.watch(attendanceRepositoryProvider);

      return repository.getAttendanceStream(user.id).map((logs) {
        if (logs.isEmpty) return null;

        final today = DateTime.now().toIso8601String().split('T')[0];

        // Find the log that matches today
        try {
          final todayLog = logs.firstWhere((log) {
            final logDate = (log['created_at'] as String).split('T')[0];
            return logDate == today;
          });
          return todayLog;
        } catch (e) {
          // No log for today found in the recent list
          return null;
        }
      });
    });

final studentPlacementProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) return null;

      return ref
          .read(attendanceRepositoryProvider)
          .getStudentPlacement(user.id);
    });
