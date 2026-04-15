import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';

class ProviderPerformance {
  final String providerId;
  final String name;
  final double avgResponseTimeMinutes;
  final double completionRate;
  final double avgRating;

  ProviderPerformance({
    required this.providerId,
    required this.name,
    required this.avgResponseTimeMinutes,
    required this.completionRate,
    required this.avgRating,
  });
}

class PricingSuggestion {
  final String region;
  final double currentSurcharge;
  final double recommendedSurcharge;
  final String reason;

  PricingSuggestion({
    required this.region,
    required this.currentSurcharge,
    required this.recommendedSurcharge,
    required this.reason,
  });
}

class AnalyticsService {
  final _supabase = Supabase.instance.client;

  Future<List<ProviderPerformance>> getTopPerformers() async {
    try {
      // 1. Fetch all service providers
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, full_name, role, registered_business_name')
          .or('role.eq.service_provider,role.eq.mechanic,role.eq.towing')
          .limit(20);
      
      final profiles = profilesResponse as List;
      if (profiles.isEmpty) return [];
      final providerIds = profiles
          .map((p) => p['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      // 2. Fetch SOS requests handled by these providers to compute metrics
      final sosResponse = await _supabase
          .from('sos_requests')
          .select('assigned_provider_id, created_at, responded_at, status')
          .not('assigned_provider_id', 'is', null);
      
      final allSos = sosResponse as List;

      // 3. Fetch submitted provider reviews so ratings are fully dynamic.
      final reviewsResponse = providerIds.isEmpty
          ? <dynamic>[]
          : await _supabase
              .from('sos_provider_reviews')
              .select('provider_id, rating, submitted_at')
              .inFilter('provider_id', providerIds)
              .not('rating', 'is', null)
              .not('submitted_at', 'is', null);
      final allReviews = List<dynamic>.from(reviewsResponse as List<dynamic>);

      // 4. Aggregate metrics per provider
      return profiles.map((p) {
        final id = p['id'].toString();
        final name = p['registered_business_name']?.toString() ?? p['full_name']?.toString() ?? 'Unknown Provider';
        
        final providerSos = allSos.where((s) => s['assigned_provider_id'] == id).toList();
        final providerReviews = allReviews.where((r) => r['provider_id'] == id).toList();
        
        double avgResponse = 15.0; // Default fallback if no data
        double completionRes = 0.0;
        double avgRating = 0.0;
        
        if (providerSos.isNotEmpty) {
          int completed = providerSos.where((s) => s['status'] == 'completed').length;
          completionRes = completed / providerSos.length;

          double totalResponseTime = 0;
          int respondedCount = 0;
          for (var sos in providerSos) {
            if (sos['created_at'] != null && sos['responded_at'] != null) {
              final start = DateTime.tryParse(sos['created_at'].toString());
              final end = DateTime.tryParse(sos['responded_at'].toString());
              if (start != null && end != null) {
                totalResponseTime += end.difference(start).inMinutes;
                respondedCount++;
              }
            }
          }
          if (respondedCount > 0) {
            avgResponse = totalResponseTime / respondedCount;
          }
        }
        if (providerReviews.isNotEmpty) {
          final ratings = providerReviews
              .map((r) => (r['rating'] as num?)?.toDouble())
              .whereType<double>()
              .toList();
          if (ratings.isNotEmpty) {
            final totalRatings = ratings.fold<double>(0, (sum, v) => sum + v);
            avgRating = totalRatings / ratings.length;
          }
        }

        return ProviderPerformance(
          providerId: id,
          name: name,
          avgResponseTimeMinutes: avgResponse,
          completionRate: completionRes,
          avgRating: avgRating,
        );
      }).toList()
        ..sort((a, b) => b.completionRate.compareTo(a.completionRate)); // Sort by completion rate
    } catch (e) {
      print('DEBUG: Analytics Error (getTopPerformers): $e');
      return [];
    }
  }

  Future<List<PricingSuggestion>> getPricingSuggestions() async {
    try {
      // Logic: Analyze recent SOS density
      final activeSosResponse = await _supabase
          .from('sos_requests')
          .select('id, type')
          .eq('status', 'pending');
      
      final activeSos = activeSosResponse as List;
      final count = activeSos.length;

      // Derived dynamic regions (in a real app, use Geo-clustering)
      final suggestions = <PricingSuggestion>[];
      
      if (count > 0) {
        suggestions.add(PricingSuggestion(
          region: 'High Demand Areas',
          currentSurcharge: 0.0,
          recommendedSurcharge: count > 5 ? 25.0 : 10.0,
          reason: '$count active SOS requests currently pending response.',
        ));
      }

      // Add a default trend-based suggestion
      suggestions.add(PricingSuggestion(
        region: 'Platform-wide',
        currentSurcharge: 0.0,
        recommendedSurcharge: 0.0,
        reason: count == 0 ? 'Optimal provider availability detected.' : 'Monitoring high-load patterns.',
      ));

      return suggestions;
    } catch (e) {
      print('DEBUG: Analytics Error (getPricingSuggestions): $e');
      return [];
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());

final topPerformersProvider = FutureProvider<List<ProviderPerformance>>((ref) {
  return ref.watch(analyticsServiceProvider).getTopPerformers();
});

final pricingSuggestionsProvider = FutureProvider<List<PricingSuggestion>>((ref) {
  return ref.watch(analyticsServiceProvider).getPricingSuggestions();
});
