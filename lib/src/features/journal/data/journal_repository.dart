import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/data/auth_repository.dart';

final journalRepositoryProvider = Provider((ref) {

  return JournalRepository();

});

final todaysJournalStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return false;

  final today = DateTime.now().toIso8601String().split('T')[0];
  final res = await Supabase.instance.client
      .from('daily_journals')
      .select()
      .eq('student_id', user.id)
      .eq('date', today)
      .limit(1);

  return res.isNotEmpty;
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

    await supabase.from("daily_journals").insert({

      "activities": title,

      "challenges": description,

      "evidence_url": imageUrl,

      "date": DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD
    });
  }

  /// ambil data jurnal
  Future<List> getJournals() async {

    final res = await supabase

        .from("daily_journals")

        .select()

        .order("created_at",
            ascending: false);

    return res;
  }

  /// ambil jurnal saya dengan pagination
  Future<List<Map<String, dynamic>>> getMyJournals({
    required String studentId,
    required int page,
    required int pageSize,
  }) async {
    final offset = (page - 1) * pageSize;
    final res = await supabase
        .from("daily_journals")
        .select()
        .eq("student_id", studentId)
        .order("date", ascending: false)
        .range(offset, offset + pageSize - 1);

    return List<Map<String, dynamic>>.from(res);
  }
}