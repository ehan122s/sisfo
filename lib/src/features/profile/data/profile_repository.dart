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
  // Tunggu auth state dari stream dulu
  final authState = await ref
      .watch(authRepositoryProvider)
      .authStateChanges
      .first;

  print('=== AUTH SESSION: ${authState.session}');

  if (authState.session == null) {
    print('=== SESSION NULL');
    return null;
  }

  final userId = authState.session!.user.id;
  print('=== USER ID: $userId');

  final response = await supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();

  print('=== PROFILE RESPONSE: $response');

  return response;
});