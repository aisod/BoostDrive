import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shop_home_page.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'web_utils.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable runtime fetching so the app can download Outfit font from Google servers
  GoogleFonts.config.allowRuntimeFetching = true; 

  // Register the reCAPTCHA container once
  WebUtils.registerViewFactory('recaptcha-container', 'recaptcha-container');
  

  // Load .env
  bool isDotEnvInitialized = false;
  try {
    // Check if we are in a web environment and if the .env asset exists
    // In production/CI (like Netlify), we might not bundle .env and rely on platform env vars
    await dotenv.load(fileName: ".env");
    isDotEnvInitialized = true;
  } catch (e) {
    print("DEBUG: Error loading .env file: $e");
    // If .env fails to load, we continue as Supabase.initialize will use empty strings 
    // which might be overridden by platform environment variables if supported by the build
  }

  final mapsKey = isDotEnvInitialized ? dotenv.maybeGet('GOOGLE_MAPS_API_KEY') : null;
  if (mapsKey != null) {
    WebUtils.injectGoogleMapsKey(mapsKey);
  }

  // Initialize Supabase
  final supabaseUrl = isDotEnvInitialized 
      ? (dotenv.maybeGet('SUPABASE_URL') ?? WebUtils.getEnv('SUPABASE_URL')) 
      : WebUtils.getEnv('SUPABASE_URL');
  final supabaseAnonKey = isDotEnvInitialized 
      ? (dotenv.maybeGet('SUPABASE_ANON_KEY') ?? WebUtils.getEnv('SUPABASE_ANON_KEY')) 
      : WebUtils.getEnv('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseUrl.contains('YOUR_SUPABASE_URL_HERE')) {
    print("CRITICAL ERROR: Supabase URL is missing! Check your .env file or environment variables.");
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    print("CRITICAL ERROR: Failed to initialize Supabase: $e");
  }

  runApp(
    const ProviderScope(
      child: BoostDriveWebApp(),
    ),
  );
}

class BoostDriveWebApp extends ConsumerWidget {
  const BoostDriveWebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    // Check if Supabase is initialized correctly
    bool isSupabaseReady = false;
    try {
      Supabase.instance.client;
      isSupabaseReady = true;
    } catch (_) {}

    if (!isSupabaseReady) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Configuration Error',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The application could not connect to the backend services. This is usually caused by missing environment variables (SUPABASE_URL and SUPABASE_ANON_KEY).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => html.window.location.reload(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BoostDriveTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Retry Connection'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'BoostDrive Shop',
      debugShowCheckedModeBanner: false,
      theme: BoostDriveTheme.lightTheme(context),
      darkTheme: BoostDriveTheme.darkTheme(context),
      themeMode: themeMode,
      home: const ShopHomePage(),
    );
  }
}
