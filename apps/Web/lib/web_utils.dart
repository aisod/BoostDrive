// lib/web_utils.dart
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: camel_case_types
import 'dart:ui_web' as ui_web;

class WebUtils {
  static void registerViewFactory(String viewType, String elementId) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => html.DivElement()
        ..id = elementId
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  static void injectGoogleMapsKey(String key) {
    js.context['GOOGLE_MAPS_API_KEY'] = key;
  }

  static String getEnv(String key, {String defaultValue = ''}) {
    // Priority: 1. JS Context (injected), 2. dart-define, 3. Default
    final jsValue = js.context[key];
    if (jsValue != null && jsValue is String && jsValue.isNotEmpty) {
      return jsValue;
    }
    
    // This is for dart-define (passed via --dart-define=KEY=VALUE)
    if (key == 'SUPABASE_URL') return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (key == 'SUPABASE_ANON_KEY') return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    
    return defaultValue;
  }
}
