// lib/features/profile/data/profile_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';
import '../../authentication/data/auth_repository.dart';

class ProfileRepository {
  /// Ambil profil user berdasarkan ID
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Update profil user
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await supabase
        .from('profiles')
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Provider profil user yang sedang login
/// Dipakai di TeacherDashboardScreen sebagai: ref.watch(userProfileProvider)
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).getProfile(user.id);
});