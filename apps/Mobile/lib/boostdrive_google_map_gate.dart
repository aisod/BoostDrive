import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:boostdrive_ui/boostdrive_ui.dart';

import 'platform/boostdrive_maps_web_types.dart';
import 'platform/google_maps_web_loader.dart';

/// On web, waits for Maps JS (via [ensureBoostdriveMapsReadyOnWeb]) before building [map].
/// On mobile, builds [map] immediately.
class BoostdriveGoogleMapGate extends StatefulWidget {
  const BoostdriveGoogleMapGate({
    super.key,
    required this.height,
    required this.map,
    this.fallbackLat,
    this.fallbackLng,
  });

  final double height;
  final Widget map;
  final double? fallbackLat;
  final double? fallbackLng;

  @override
  State<BoostdriveGoogleMapGate> createState() => _BoostdriveGoogleMapGateState();
}

class _BoostdriveGoogleMapGateState extends State<BoostdriveGoogleMapGate> {
  late final Future<BoostdriveMapsWebLoad> _future = ensureBoostdriveMapsReadyOnWeb();

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return SizedBox(height: widget.height, child: widget.map);
    }

    return FutureBuilder<BoostdriveMapsWebLoad>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final r = snap.data ?? BoostdriveMapsWebLoad.loadFailed;
        if (r == BoostdriveMapsWebLoad.skipped || r == BoostdriveMapsWebLoad.ready) {
          return SizedBox(height: widget.height, child: widget.map);
        }
        return SizedBox(
          height: widget.height,
          child: _MapsWebFallback(
            result: r,
            lat: widget.fallbackLat,
            lng: widget.fallbackLng,
          ),
        );
      },
    );
  }
}

class _MapsWebFallback extends StatelessWidget {
  const _MapsWebFallback({
    required this.result,
    this.lat,
    this.lng,
  });

  final BoostdriveMapsWebLoad result;
  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context) {
    final openMaps = lat != null && lng != null;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, color: Colors.white54, size: 36),
            const SizedBox(height: 10),
            Text(
              result == BoostdriveMapsWebLoad.missingApiKey
                  ? 'Maps need a Maps JavaScript API key.\n'
                      'Add GOOGLE_MAPS_WEB_API_KEY (or GOOGLE_MAPS_API_KEY) to assets/.env, '
                      'or run with --dart-define=GOOGLE_MAPS_WEB_API_KEY=...'
                  : 'Could not load Google Maps on the web. Check the API key and billing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12, height: 1.35),
            ),
            if (openMaps) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new, color: BoostDriveTheme.primaryColor),
                label: const Text('Open in Google Maps'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
