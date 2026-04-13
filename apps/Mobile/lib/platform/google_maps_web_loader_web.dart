// Conditional web-only loader; dart:html is the stable choice for script injection here.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'boostdrive_maps_web_types.dart';

String? _normalizeApiKey(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.length >= 2) {
    final a = s.codeUnitAt(0);
    final b = s.codeUnitAt(s.length - 1);
    if ((a == 0x22 || a == 0x27) && a == b) {
      s = s.substring(1, s.length - 1).trim();
    }
  }
  return s.isEmpty ? null : s;
}

/// Maps JavaScript API key: `--dart-define` wins, else [dotenv] (loaded in [main] from `assets/.env`).
///
/// Supported env names (any one): `GOOGLE_MAPS_WEB_API_KEY`, `GOOGLE_MAPS_API_KEY`,
/// `GOOGLE_MAPS_KEY`, `MAPS_API_KEY`.
String _googleMapsJavaScriptApiKey() {
  const fromDefine = String.fromEnvironment('GOOGLE_MAPS_WEB_API_KEY', defaultValue: '');
  final fromDefineNorm = _normalizeApiKey(fromDefine);
  if (fromDefineNorm != null) return fromDefineNorm;

  const fromDefineAlt = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  final fromDefineAltNorm = _normalizeApiKey(fromDefineAlt);
  if (fromDefineAltNorm != null) return fromDefineAltNorm;

  const envKeyNames = <String>[
    'GOOGLE_MAPS_WEB_API_KEY',
    'GOOGLE_MAPS_API_KEY',
    'GOOGLE_MAPS_KEY',
    'MAPS_API_KEY',
  ];

  try {
    for (final name in envKeyNames) {
      final v = _normalizeApiKey(dotenv.maybeGet(name));
      if (v != null) return v;
    }
  } catch (_) {}

  if (kDebugMode) {
    // ignore: avoid_print
    print(
      'BoostDrive Maps (web): no API key found. Add one of $envKeyNames to assets/.env '
      '(must be listed under flutter: assets: in pubspec), or use '
      '--dart-define=GOOGLE_MAPS_WEB_API_KEY=YOUR_KEY',
    );
  }

  return '';
}

/// Injected once per page session.
Future<BoostdriveMapsWebLoad>? _inFlight;

Future<BoostdriveMapsWebLoad> ensureBoostdriveMapsReadyOnWeb() {
  if (!kIsWeb) return Future.value(BoostdriveMapsWebLoad.skipped);
  _inFlight ??= _injectIfNeeded();
  return _inFlight!;
}

Future<BoostdriveMapsWebLoad> _injectIfNeeded() async {
  final key = _googleMapsJavaScriptApiKey();
  if (key.isEmpty) {
    return BoostdriveMapsWebLoad.missingApiKey;
  }

  final existing = html.document.querySelectorAll('script[src*="maps.googleapis.com/maps/api/js"]');
  if (existing.isNotEmpty) {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return BoostdriveMapsWebLoad.ready;
  }

  final completer = Completer<BoostdriveMapsWebLoad>();
  final script = html.ScriptElement()
    ..type = 'text/javascript'
    ..async = true
    ..src = 'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeComponent(key)}';

  void complete(BoostdriveMapsWebLoad v) {
    if (!completer.isCompleted) completer.complete(v);
  }

  script.onLoad.listen((_) => complete(BoostdriveMapsWebLoad.ready));
  script.onError.listen((_) => complete(BoostdriveMapsWebLoad.loadFailed));

  html.document.head!.append(script);

  return completer.future.timeout(
    const Duration(seconds: 20),
    onTimeout: () => BoostdriveMapsWebLoad.loadFailed,
  );
}
