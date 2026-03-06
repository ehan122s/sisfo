import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/announcement_model.dart';
import '../../authentication/data/auth_repository.dart';

final announcementRepositoryProvider = Provider((ref) {
  return AnnouncementRepository(Supabase.instance.client);
});

final activeAnnouncementsProvider =
    StreamProvider.autoDispose<List<AnnouncementModel>>((ref) {
      final user = ref.watch(authRepositoryProvider).currentUser;
      return ref
          .watch(announcementRepositoryProvider)
          .watchActiveAnnouncements(user?.id);
    });

class AnnouncementRepository {
  final SupabaseClient _supabase;

  AnnouncementRepository(this._supabase);

  Stream<List<AnnouncementModel>> watchActiveAnnouncements(String? userId) {
    // Currently RLS handles the filtering by role, so we just select active ones.
    // However, to be safe and efficient, we can rely on the connection being authenticated.
    return _supabase
        .from('announcements')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at')
        .map(
          (data) =>
              data.map((json) => AnnouncementModel.fromJson(json)).toList(),
        );
  }
}
