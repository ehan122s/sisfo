import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/data/auth_repository.dart';

// --- PROVIDER SECTION ---

final journalRepositoryProvider = Provider((ref) {
  return JournalRepository();
});

final todaysJournalStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return false;

  final repository = ref.watch(journalRepositoryProvider);
  // Menggunakan await karena hasSubmittedJournalToday adalah Future
  return await repository.hasSubmittedJournalToday(user.id);
});

// --- REPOSITORY CLASS SECTION ---

class JournalRepository {
  final supabase = Supabase.instance.client;

  Future<String> uploadEvidenceFile(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = "journals/$fileName.jpg";
    
    await supabase.storage.from("journal").upload(path, file);
    return supabase.storage.from("journal").getPublicUrl(path);
  }

  Future<String> uploadEvidenceBytes(Uint8List bytes) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = "journals/$fileName.jpg";

    await supabase.storage.from("journal").uploadBinary(path, bytes);
    return supabase.storage.from("journal").getPublicUrl(path);
  }

  Future<void> submitJournal({
    required String title,
    required String description,
    required String imageUrl,
  }) async {
    await supabase.from("daily_journals").insert({
      "title": title,
      "description": description,
      "image_url": imageUrl,
      "created_at": DateTime.now().toIso8601String(),
    });
  }

  /// Ambil semua data jurnal
  Future<List<Map<String, dynamic>>> getJournals() async {
    final res = await supabase
        .from("daily_journals")
        .select()
        .order("created_at", ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Ambil data jurnal user tertentu dengan pagination
  Future<List<Map<String, dynamic>>> getMyJournals({
    required String studentId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final res = await supabase
        .from("daily_journals")
        .select()
        .eq('student_id', studentId)
        .order("created_at", ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Cek apakah user sudah isi jurnal hari ini
  Future<bool> hasSubmittedJournalToday(String studentId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final res = await supabase
        .from("daily_journals")
        .select()
        .eq('student_id', studentId)
        .eq('date', today)
        .limit(1);
    return res.isNotEmpty;
  }
}