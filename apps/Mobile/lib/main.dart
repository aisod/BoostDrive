import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
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
  

  // Load .env: primary path must be a bundled asset (required for web). Optional merge from `.env` if also listed in pubspec.
  bool isDotEnvInitialized = false;
  try {
    await dotenv.load(fileName: 'assets/.env');
    isDotEnvInitialized = true;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('main: assets/.env not loaded ($e). Trying .env …');
    }
    try {
      await dotenv.load(fileName: '.env');
      isDotEnvInitialized = true;
    } catch (_) {
      debugPrint(
        'main: No .env loaded. Add apps/Mobile/assets/.env and list it under flutter: assets: in pubspec.yaml '
        '(web cannot read a random disk path). Include SUPABASE_* and a Maps key: GOOGLE_MAPS_WEB_API_KEY or GOOGLE_MAPS_API_KEY.',
      );
    }
  }
  if (isDotEnvInitialized) {
    try {
      await dotenv.load(fileName: '.env', mergeWith: dotenv.env);
    } catch (_) {
      // Optional second file (only works if `.env` is also in flutter assets).
    }
    if (kDebugMode && kIsWeb) {
      final hasMaps = dotenv.maybeGet('GOOGLE_MAPS_WEB_API_KEY')?.trim().isNotEmpty == true ||
          dotenv.maybeGet('GOOGLE_MAPS_API_KEY')?.trim().isNotEmpty == true ||
          dotenv.maybeGet('GOOGLE_MAPS_KEY')?.trim().isNotEmpty == true ||
          dotenv.maybeGet('MAPS_API_KEY')?.trim().isNotEmpty == true;
      if (!hasMaps) {
        debugPrint(
          'main: Web maps — set GOOGLE_MAPS_WEB_API_KEY (or GOOGLE_MAPS_API_KEY) in the loaded .env asset.',
        );
      }
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
      builder: (context, child) => child ?? const SizedBox.shrink(),
      home: const AuthGate(),
    );
  }
}
