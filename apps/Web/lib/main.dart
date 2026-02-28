import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shop_home_page.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'web_utils.dart';

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
  await Supabase.initialize(
    url: isDotEnvInitialized ? (dotenv.maybeGet('SUPABASE_URL') ?? '') : '',
    anonKey: isDotEnvInitialized ? (dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '') : '',
  );

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
