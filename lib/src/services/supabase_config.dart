import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey =
      'YOUR_SUPABASE_ANON_KEY';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}

final supabase = Supabase.instance.client;
