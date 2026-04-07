import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://vvvcwxialnbzrcaitkql.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2dmN3eGlhbG5ienJjYWl0a3FsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NzgwNzgsImV4cCI6MjA5MTA1NDA3OH0.SHsEmozD6qNMEC2rq5kBhNvFTZFPwLp7dGuPyotpn10
';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}

final supabase = Supabase.instance.client;
