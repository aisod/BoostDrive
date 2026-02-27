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
