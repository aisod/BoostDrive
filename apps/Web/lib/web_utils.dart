// lib/web_utils.dart
import 'dart:html' as html;
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
    if (key.isEmpty) {
      return;
    }

    // Expose key to JS context if needed elsewhere.
    js.context['GOOGLE_MAPS_API_KEY'] = key;

    // Avoid injecting the script multiple times.
    final existingScripts = html.document
        .querySelectorAll('script')
        .whereType<html.ScriptElement>()
        .where((s) => s.src.contains('maps.googleapis.com/maps/api/js'))
        .toList();
    if (existingScripts.isNotEmpty) {
      return;
    }

    final script = html.ScriptElement()
      ..src = 'https://maps.googleapis.com/maps/api/js?key=$key&libraries=places&loading=async'
      ..async = true
      ..defer = true;
    script.onError.listen((_) {
      // Optional: add logging via debugPrint from caller if needed.
    });
    html.document.head?.append(script);
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
