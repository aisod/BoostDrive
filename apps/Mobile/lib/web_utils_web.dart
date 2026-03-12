// ignore: deprecated_member_use, avoid_web_libraries_in_flutter — web stub, dart:html only on web
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebUtils {
  static void registerViewFactory(String viewType, String elementId) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => html.DivElement()..id = elementId,
    );
  }
}
