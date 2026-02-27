import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'auth_gate.dart';
import 'package:boostdrive_services/src/seed_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'web_utils.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Register reCAPTCHA container for Web
  WebUtils.registerViewFactory('recaptcha-container', 'recaptcha-container');
  

  // Load .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("DEBUG: Error loading .env file: $e");
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.maybeGet('SUPABASE_URL') ?? '',
    anonKey: dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '',
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
                  print("DEBUG: Error loading background: $error");
                  return Container(color: const Color(0xFF0D0D0D));
                },
              ),
            ),
            // App Content
            ?child,
          ],
        );
      },
      home: const AuthGate(),
    );
  }
}
