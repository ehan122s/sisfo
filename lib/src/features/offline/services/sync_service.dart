import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance/data/attendance_repository.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../data/offline_queue_repository.dart';

final syncServiceProvider = Provider((ref) {
  return SyncService(
    ref.watch(offlineQueueRepositoryProvider),
    ref.watch(attendanceRepositoryProvider),
  );
});

class SyncService {
  final OfflineQueueRepository _queueRepository;
  final AttendanceRepository _attendanceRepository;

  SyncService(this._queueRepository, this._attendanceRepository) {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        _processQueue();
      }
    });
  }

  final _isSyncingController = StreamController<bool>.broadcast();
  Stream<bool> get isSyncingStream => _isSyncingController.stream;

  Future<void> _processQueue() async {
    final queue = await _queueRepository.getQueue();
    if (queue.isEmpty) return;

    _isSyncingController.add(true);

    final List<int> processedIndices = [];

    for (int i = 0; i < queue.length; i++) {
      final item = queue[i];
      try {
        final type = item['type'];
        final studentId = item['student_id'];
        final placementId = item['placement_id'] as int? ?? 0;
        final lat = item['lat'];
        final long = item['long'];
        String photoUrl = item['photo_path'];

        // Upload photo if it's a local path
        if (!photoUrl.startsWith('http')) {
          final file = File(photoUrl);
          if (await file.exists()) {
            photoUrl = await _attendanceRepository.uploadSelfie(
              file,
              studentId,
            );
          } else {
            // File lost? Skip or handle error.
            // For now, if file missing, we can't upload, maybe log error.
            debugPrint("File not found for sync: $photoUrl");
            // If file missing, maybe just skip processing this one forever or remove?
            // Let's remove it to avoid blocking.
            processedIndices.add(i);
            continue;
          }
        }

        if (type == 'check_in') {
          await _attendanceRepository.checkIn(
            studentId: studentId,
            placementId: placementId,
            lat: lat,
            long: long,
            photoUrl: photoUrl,
          );
        } else if (type == 'check_out') {
          await _attendanceRepository.checkOut(
            studentId: studentId,
            placementId: placementId,
            lat: lat,
            long: long,
            photoUrl: photoUrl,
          );
        }

        processedIndices.add(i);
      } catch (e) {
        debugPrint("Sync failed for item $i: $e");
        // Keep in queue to retry later
      }
    }

    // Remove processed items in reverse order to correct indices
    for (int i = processedIndices.length - 1; i >= 0; i--) {
      await _queueRepository.removeFromQueue(processedIndices[i]);
    }

    _isSyncingController.add(false);
  }
}

final isSyncingProvider = StreamProvider<bool>((ref) {
  return ref.watch(syncServiceProvider).isSyncingStream;
});
