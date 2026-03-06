import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_config.dart';
import '../../authentication/data/auth_repository.dart';

class ProfileRepository {
  final SupabaseClient _supabase = supabase;

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async {
  final authState = ref.watch(authStateProvider);

  // If not logged in, return null
  if (authState.asData?.value.session == null) {
    return null;
  }

  return ref.read(profileRepositoryProvider).getCurrentUserProfile();
});
