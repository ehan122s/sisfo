import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final offlineQueueRepositoryProvider = Provider(
  (ref) => OfflineQueueRepository(),
);

class OfflineQueueRepository {
  static const String _queueKey = 'offline_attendance_queue';

  final _queueCountController = StreamController<int>.broadcast();
  Stream<int> get queueCountStream => _queueCountController.stream;

  OfflineQueueRepository() {
    // emit initial value
    getQueue().then((q) => _queueCountController.add(q.length));
  }

  Future<void> addToQueue(Map<String, dynamic> request) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_queueKey) ?? [];

    // Add timestamp to request if not present
    if (!request.containsKey('timestamp')) {
      request['timestamp'] = DateTime.now().toIso8601String();
    }

    queue.add(jsonEncode(request));
    await prefs.setStringList(_queueKey, queue);
    _queueCountController.add(queue.length);
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_queueKey) ?? [];

    return queue.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> removeFromQueue(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_queueKey) ?? [];

    if (index >= 0 && index < queue.length) {
      queue.removeAt(index);
      await prefs.setStringList(_queueKey, queue);
      _queueCountController.add(queue.length);
    }
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    _queueCountController.add(0);
  }
}

final offlineQueueCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(offlineQueueRepositoryProvider);
  return repo.queueCountStream;
});
