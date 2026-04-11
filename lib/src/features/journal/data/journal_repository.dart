import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/data/auth_repository.dart';

final journalRepositoryProvider = Provider((ref) {

  return JournalRepository();

});

class JournalRepository {

  final supabase = Supabase.instance.client;

  /// upload file android
  Future<String> uploadEvidenceFile(File file) async {

    final fileName =
        DateTime.now().millisecondsSinceEpoch.toString();

    final path = "journals/$fileName.jpg";

    await supabase.storage

        .from("journal")

        .upload(path, file);

    return supabase.storage

        .from("journal")

        .getPublicUrl(path);
  }

  /// upload file web
  Future<String> uploadEvidenceBytes(

    Uint8List bytes,

  ) async {

    final fileName =
        DateTime.now().millisecondsSinceEpoch.toString();

    final path = "journals/$fileName.jpg";

    await supabase.storage

        .from("journal")

        .uploadBinary(path, bytes);

    return supabase.storage

        .from("journal")

        .getPublicUrl(path);
  }

  /// simpan jurnal
  Future submitJournal({

    required String title,

    required String description,

    required String imageUrl,

  }) async {

    await supabase.from("journals").insert({

      "title": title,

      "description": description,

      "image_url": imageUrl,

      "created_at":
          DateTime.now().toIso8601String(),
    });
  }

  /// ambil data jurnal
  Future<List> getJournals() async {

    final res = await supabase

        .from("journals")

        .select()

        .order("created_at",
            ascending: false);

    return res;
  }

  /// ambil data jurnal user tertentu dengan pagination
  Future<List<Map<String, dynamic>>> getMyJournals({
    required String studentId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    final res = await supabase
        .from("journals")
        .select()
        .eq('student_id', studentId)
        .order("created_at", ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(res);
  }

  /// cek apakah user sudah submit journal hari ini
  Future<bool> hasSubmittedJournalToday(String studentId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final res = await supabase
        .from("journals")
        .select()
        .eq('student_id', studentId)
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String())
        .limit(1);

    return res.isNotEmpty;
  }
}

final todaysJournalStatusProvider = FutureProvider.autoDispose<bool>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Future.value(false);

  final repository = ref.watch(journalRepositoryProvider);
  return repository.hasSubmittedJournalToday(user.id);
});