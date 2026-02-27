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
    js.context['GOOGLE_MAPS_API_KEY'] = key;
  }
}
