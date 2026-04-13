/// Result of preparing Google Maps on Flutter web (mobile uses [skipped]).
enum BoostdriveMapsWebLoad {
  /// Not web — use [GoogleMap] as usual.
  skipped,

  /// Maps JS is available.
  ready,

  /// Run with `--dart-define=GOOGLE_MAPS_WEB_API_KEY=your_key`
  missingApiKey,

  /// Script failed to load (network, invalid key, or blocked).
  loadFailed,
}
