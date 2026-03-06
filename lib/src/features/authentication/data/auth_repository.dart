import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_config.dart';
import '../../../core/exceptions/app_exceptions.dart';

class AuthRepository {
  final GoTrueClient _auth = supabase.auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  Future<void> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      // Catch Supabase specific AuthException (if the library exposes one with same name, handle conflict)
      // Actually Supabase throws `AuthException` from `supabase_flutter`.
      // We should check import.
      throw AppAuthException(e.message, e.statusCode);
    } catch (e) {
      throw AppAuthException('Login Gagal: ${e.toString()}');
    }
  }

  Future<void> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String nisn,
    required String className,
  }) async {
    try {
      // 1. Sign Up Auth User
      final AuthResponse res = await _auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final user = res.user;
      if (user == null) throw ServerException("Gagal membuat user");

      // 2. Insert to Profiles
      await supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'nisn': nisn,
        'class_name': className,
        'status': 'pending',
      });
    } on AuthException catch (e) {
      throw AppAuthException(e.message, e.statusCode);
    } catch (e) {
      throw ServerException('Registrasi Gagal: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String> getUserRole() async {
    final user = currentUser;
    if (user == null) return 'student';

    try {
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'] as String? ?? 'student';
    } catch (e) {
      return 'student';
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userRoleProvider = FutureProvider.autoDispose<String>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) async {
      if (state.session == null) return 'student';
      return ref.watch(authRepositoryProvider).getUserRole();
    },
    loading: () => 'student',
    error: (_, __) => 'student',
  );
});
