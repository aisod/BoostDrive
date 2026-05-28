import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _supabaseReady = false;

/// Initializes a local Supabase instance for widget tests that construct [SosService].
Future<void> ensureTestSupabase() async {
  if (_supabaseReady) return;
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await Supabase.initialize(
    url: 'http://127.0.0.1:54321',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
  );
  _supabaseReady = true;
}
