import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'web_utils.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Register reCAPTCHA container for Web
  WebUtils.registerViewFactory('recaptcha-container', 'recaptcha-container');
  

  // Load .env (optional: if missing, Supabase URL/key will be empty and auth may not work until you add assets/.env)
  bool isDotEnvInitialized = false;
  try {
    await dotenv.load(fileName: "assets/.env");
    isDotEnvInitialized = true;
  } catch (e) {
    // Fallback for projects that keep .env at app root (e.g. some IDEs)
    try {
      await dotenv.load(fileName: ".env");
      isDotEnvInitialized = true;
    } catch (_) {
      debugPrint("DEBUG: .env not loaded (404 or missing). Add assets/.env with SUPABASE_URL and SUPABASE_ANON_KEY for auth.");
    }
  }

  final supabaseUrl = isDotEnvInitialized ? (dotenv.maybeGet('SUPABASE_URL') ?? '') : '';
  final anonKey = isDotEnvInitialized ? (dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '') : '';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: anonKey,
  );

  runApp(
    const ProviderScope(
      child: BoostDriveMobileApp(),
    ),
  );
}

class BoostDriveMobileApp extends StatelessWidget {
  const BoostDriveMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BoostDrive',
      debugShowCheckedModeBanner: false,
      theme: BoostDriveTheme.darkTheme(context).copyWith(
        scaffoldBackgroundColor: const Color(0xCC0D0D0D), // Semi-transparent black to show background
      ),
      builder: (context, child) {
        return Stack(
          children: [
            // Global Background Image
            Positioned.fill(
              child: Image.asset(
                BoostDriveTheme.globalBackgroundImage,
                // package: 'boostdrive_ui', // Removed: Loading from local assets now
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("DEBUG: Error loading background: $error");
                  return Container(color: const Color(0xFF0D0D0D));
                },
              ),
            ),
            // App Content
            child ?? const SizedBox.shrink(),
          ],
        );
      },
      home: const AuthGate(),
    );
  }
}
