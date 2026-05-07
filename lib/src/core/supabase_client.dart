// lib/core/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Konstanta koneksi Supabase project e-pkl
const String supabaseUrl = 'https://vvvcwxialnbzrcaitkql.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2dmN3eGlhbG5ienJjYWl0a3FsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NzgwNzgsImV4cCI6MjA5MTA1NDA3OH0.SHsEmozD6qNMEC2rq5kBhNvFTZFPwLp7dGuPyotpn10';

/// Shortcut global untuk akses Supabase client
final supabase = Supabase.instance.client;

/// Panggil di main() sebelum runApp()
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await initSupabase();
///   runApp(const ProviderScope(child: MyApp()));
/// }
/// ```
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}