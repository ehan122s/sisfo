import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/data/auth_repository.dart';

final journalRepositoryProvider = Provider((ref) {
  return JournalRepository();
});

// --- PROVIDER PINDAH KE SINI (HANYA SATU) ---
final todaysJournalStatusProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return false;

  final repository = ref.watch(journalRepositoryProvider);
  return repository.hasSubmittedJournalToday(user.id);
});

class JournalRepository {
  final supabase = Supabase.instance.client;

  /// upload file android
  Future<String> uploadEvidenceFile(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = "journals/$fileName.jpg";

    await supabase.storage.from("journal").upload(path, file);
    return supabase.storage.from("journal").getPublicUrl(path);
  }

  /// upload file web
  Future<String> uploadEvidenceBytes(Uint8List bytes) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = "journals/$fileName.jpg";

    await supabase.storage.from("journal").uploadBinary(path, bytes);
    return supabase.storage.from("journal").getPublicUrl(path);
  }

  /// simpan jurnal
  Future submitJournal({
    required String title,
    required String description,
    required String imageUrl,
  }) async {
    final user = supabase.auth.currentUser; // Ambil ID user yang login
    if (user == null) throw Exception("User tidak ditemukan");

    await supabase.from("daily_journals").insert({
      "student_id": user.id, // WAJIB ADA agar tidak error di Supabase
      "activities": title,
      "challenges": description,
      "evidence_url": imageUrl,
      "date": DateTime.now().toIso8601String().split('T')[0],
    });
  }

  /// ambil data jurnal
  Future<List> getJournals() async {
    final res = await supabase
        .from("daily_journals")
        .select()
        .order("created_at", ascending: false);
    return res;
  }

  Future<List<Map<String, dynamic>>> getMyJournals({
    required String studentId,
    int page = 0,
    int pageSize = 10,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final res = await supabase
        .from(
          "daily_journals",
        ) // Pastikan nama tabel konsisten 'daily_journals'
        .select()
        .eq('student_id', studentId)
        .order("created_at", ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(res);
  }

  /// cek apakah user sudah submit journal hari ini
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
