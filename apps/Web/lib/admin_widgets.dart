import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';

class NamibiaSOSRadar extends StatefulWidget {
  final List<SosRequest> activeRequests;
  const NamibiaSOSRadar({super.key, required this.activeRequests});

  @override
  State<NamibiaSOSRadar> createState() => _NamibiaSOSRadarState();
}

class _NamibiaSOSRadarState extends State<NamibiaSOSRadar> {
  bool _mapInitialized = false;
  String? _mapInitError;

  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(-22.5609, 17.0658),
    zoom: 6.2,
  );

  @override
  Widget build(BuildContext context) {
    final points = _buildPlottableRequests(widget.activeRequests);
    final rawCount = widget.activeRequests.length;
    final hasValidCoords = points.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live SOS Radar (Namibia)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Stack(
            children: [
              if (points.isEmpty)
                const Positioned.fill(
                  child: Center(
                    child: Text(
                      'No active SOS requests to display.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black45),
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(points.first.lat, points.first.lng),
                      zoom: 10.5,
                    ),
                    markers: points.map(_toMarker).toSet(),
                    circles: points.map(_toCircle).toSet(),
                    onMapCreated: (_) {
                      if (!mounted) return;
                      setState(() {
                        _mapInitialized = true;
                        _mapInitError = null;
                      });
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                  ),
                ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _mapInitError != null
                        ? 'Map: error | rows: $rawCount | plotted: ${points.length}'
                        : 'Map: ${_mapInitialized ? 'initialized' : 'initializing'} | rows: $rawCount | plotted: ${points.length} | coords: ${hasValidCoords ? 'ok' : 'none'}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    '${points.length} active',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black54),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Color(0x22FF6600), blurRadius: 4)],
                  ),
                  child: Column(
                    children: [
                      _buildLegendItem('Critical', Colors.redAccent),
                      _buildLegendItem('Major', Colors.orange),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<SosRequest> _buildPlottableRequests(List<SosRequest> requests) {
    final withCoords = requests.where((r) => r.lat != 0.0 || r.lng != 0.0).toList();
    if (withCoords.isNotEmpty) return withCoords;
    return const <SosRequest>[];
  }

  Marker _toMarker(SosRequest r) {
    final isCritical = _isCritical(r);
    final hue = isCritical ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange;
    return Marker(
      markerId: MarkerId(r.id),
      position: LatLng(r.lat, r.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      infoWindow: InfoWindow(
        title: r.type.toUpperCase(),
        snippet: 'Status: ${r.status}',
      ),
    );
  }

  Circle _toCircle(SosRequest r) {
    final isCritical = _isCritical(r);
    final color = isCritical ? Colors.redAccent : Colors.orange;
    return Circle(
      circleId: CircleId('pulse_${r.id}'),
      center: LatLng(r.lat, r.lng),
      radius: isCritical ? 220 : 150,
      fillColor: color.withValues(alpha: 0.18),
      strokeColor: color.withValues(alpha: 0.45),
      strokeWidth: 1,
    );
  }

  bool _isCritical(SosRequest r) {
    final t = r.type.toLowerCase();
    final s = r.status.toLowerCase();
    return t.contains('accident') || t.contains('medical') || s == 'pending';
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}

class ProviderPerformanceLeaderboard extends ConsumerWidget {
  const ProviderPerformanceLeaderboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(topPerformersProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Performers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Icon(Icons.emoji_events_outlined, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          perfAsync.when(
            data: (list) => Column(
              children: list.map((p) => _buildPerformerRow(context, p)).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformerRow(BuildContext context, ProviderPerformance p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(p.name[0], style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                Text('${p.avgResponseTimeMinutes}m average response', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 12),
                  Text(' ${p.avgRating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                ],
              ),
              Text('${(p.completionRate * 100).toInt()}% Success', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class DynamicPricingMonitor extends ConsumerWidget {
  const DynamicPricingMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(pricingSuggestionsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF000000), // Dark contrast for "Dynamic" feel
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Pricing Pulse',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          suggestionsAsync.when(
            data: (suggestions) => Column(
              children: suggestions.map((s) => _buildSuggestionRow(s)).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionRow(PricingSuggestion s) {
    final hasSurcharge = s.recommendedSurcharge > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.region, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(s.reason, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasSurcharge ? '+\$${s.recommendedSurcharge.toInt()}' : 'NORMAL',
                style: TextStyle(color: hasSurcharge ? Colors.orange : Colors.green, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const Text('RECOM. SURCHARGE', style: TextStyle(color: Color(0x22FF6600), fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}
