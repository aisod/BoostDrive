import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';

class NamibiaSOSRadar extends StatelessWidget {
  final List<SosRequest> activeRequests;
  const NamibiaSOSRadar({super.key, required this.activeRequests});

  @override
  Widget build(BuildContext context) {
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Mock Map Placeholder
                  Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(Icons.map, size: 200, color: Colors.black),
                    ),
                  ),
                  // Dynamic Heatmap Clusters
                  ...activeRequests.map((r) => _buildSosPoint(context, r, constraints)),
                  // Legend
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
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildSosPoint(BuildContext context, SosRequest r, BoxConstraints constraints) {
    // Namibia Bounding Box Approximation
    const minLat = -29.0;
    const maxLat = -17.0;
    const minLng = 11.5;
    const maxLng = 25.5;

    // Default to roughly Windhoek if lat/lng is 0,0
    double lat = r.lat;
    double lng = r.lng;
    if (lat == 0.0 && lng == 0.0) {
      lat = -22.56;
      lng = 17.06;
    }

    // Clamp coordinates to keep them inside the visual bounding box
    lat = lat.clamp(minLat, maxLat);
    lng = lng.clamp(minLng, maxLng);

    // Normalize (Lat is inverted because top of screen is Y=0 and North is higher lat)
    final double normalizedX = (lng - minLng) / (maxLng - minLng);
    final double normalizedY = (maxLat - lat) / (maxLat - minLat);

    final double left = (normalizedX * constraints.maxWidth) - 6; // offset by child width/2
    final double top = (normalizedY * constraints.maxHeight) - 6; // offset by child height/2

    return Positioned(
      left: left,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            r.type.toUpperCase(),
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
        ],
      ),
    );
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
