// lib/features/authentication/data/auth_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// User yang sedang login (null jika belum login)
  User? get currentUser => _client.auth.currentUser;

  /// Stream perubahan state autentikasi
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Login dengan email & password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Alias untuk kompatibilitas dengan login_screen.dart
  Future<AuthResponse> loginWithEmail(String email, String password) async {
    return signIn(email: email, password: password);
  }

  /// Daftar akun baru
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Logout
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Reset password via email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}

/// Provider global AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(supabase);
});

/// Provider untuk memantau state auth (dipakai di GoRouter redirect)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});