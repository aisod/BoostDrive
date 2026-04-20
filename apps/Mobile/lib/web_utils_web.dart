// web stub, dart:html only on web
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebUtils {
  static void registerViewFactory(String viewType, String elementId) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => html.DivElement()
        ..id = elementId
        ..style.width = '48px'
        ..style.height = '48px'
        ..style.display = 'block',
    );
  }
}
