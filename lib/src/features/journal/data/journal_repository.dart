import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_config.dart';
import '../../../core/exceptions/app_exceptions.dart';

import '../../authentication/data/auth_repository.dart';

class JournalRepository {
  final SupabaseClient _supabase = supabase;

  // 1. Upload Evidence Photo
  Future<String> uploadEvidence(File imageFile, String userId) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '${userId}_evidence_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'evidence/$fileName';

      await _supabase.storage
          .from('journal_evidence')
          .upload(filePath, imageFile);
      return _supabase.storage.from('journal_evidence').getPublicUrl(filePath);
    } catch (e) {
      throw ServerException('Upload Foto Gagal: ${e.toString()}');
    }
  }

  // 2. Submit Journal
  Future<void> submitJournal({
    required String studentId,
    required String title,
    required String description,
    required String evidenceUrl,
    int? placementId,
  }) async {
    try {
      await _supabase.from('daily_journals').insert({
        'student_id': studentId,
        'placement_id': placementId,
        'activity_title': title,
        'description': description,
        'evidence_photo': evidenceUrl,
        'is_approved': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerException('Simpan Jurnal Gagal: ${e.toString()}');
    }
  }

  // 3. Get Student Journals (Paginated)
  Future<List<Map<String, dynamic>>> getMyJournals({
    required String studentId,
    int page = 0,
    int pageSize = 10,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final response = await _supabase
        .from('daily_journals')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(response);
  }

  // 4. Check if filled today
  Future<bool> hasFilledJournalToday(String studentId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await _supabase
        .from('daily_journals')
        .select()
        .eq('student_id', studentId)
        .gte('created_at', '$today 00:00:00')
        .lte('created_at', '$today 23:59:59')
        .limit(1);
    return (response as List).isNotEmpty;
  }
}

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

final todaysJournalStatusProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return false;
  return ref.watch(journalRepositoryProvider).hasFilledJournalToday(user.id);
});
