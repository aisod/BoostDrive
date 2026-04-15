import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' show ClientException;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'dart:async';

/// True when this SOS [type] or [emergencyCategory] matches any entry in [providerServiceTypes]
/// (e.g. profile `provider_service_types`: `mechanic`, `towing`, `parts`). Case-insensitive.
bool sosRequestMatchesProviderServiceTypes(SosRequest request, List<String> providerServiceTypes) {
  if (providerServiceTypes.isEmpty) return false;
  final caps = providerServiceTypes
      .map((e) => e.toLowerCase().trim())
      .where((e) => e.isNotEmpty)
      .toSet();
  final t = request.type.toLowerCase().trim();
  if (t.isNotEmpty && caps.contains(t)) return true;
  final cat = request.emergencyCategory?.toLowerCase().trim();
  if (cat != null && cat.isNotEmpty && caps.contains(cat)) return true;
  return false;
}

/// One provider heartbeat on a pending SOS (viewing / responding before accept).
class SosRespondingHeartbeat {
  const SosRespondingHeartbeat({
    required this.sosRequestId,
    required this.providerId,
    required this.lastSeenAt,
  });

  final String sosRequestId;
  final String providerId;
  final DateTime lastSeenAt;
}

/// Returns true when the error looks like a network/transport issue.
bool _looksLikeTransportFailure(Object e) {
  if (e is ClientException) return true;
  final s = e.toString();
  return s.contains('Failed to fetch') ||
      s.contains('SocketException') ||
      s.contains('Connection refused') ||
      s.contains('Connection reset') ||
      s.contains('HandshakeException') ||
      s.contains('Network is unreachable');
}

/// After a successful poll, keep streaming if later polls hit flaky network (web "Failed to fetch").
bool _isRecoverableSosPollFailure(Object e) {
  return _looksLikeTransportFailure(e) ||
      e.toString().contains('Could not reach Supabase while loading assigned SOS');
}

/// Service layer for SOS creation, assignment, tracking, and provider/customer helpers.
class SosService {
  final _supabase = Supabase.instance.client;
  static const String emergencyNumber = "+264811234567"; // Namibia dispatch placeholder

  /// Gets current location with permission checks and fallbacks.
  Future<Position?> getCurrentLocation() async {
    try {
      // Browser / some emulators report location services oddly; web uses the Geolocation API directly.
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final lastKnown = await Geolocator.getLastKnownPosition();

      Future<Position?> tryFix({
        required LocationAccuracy accuracy,
        required Duration timeLimit,
      }) async {
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: timeLimit,
          );
        } catch (_) {
          return null;
        }
      }

      // Web: "high" accuracy often times out or fails; last-known is usually unavailable. Step down.
      if (kIsWeb) {
        return await tryFix(accuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 30)) ??
            await tryFix(accuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 25)) ??
            await tryFix(accuracy: LocationAccuracy.lowest, timeLimit: const Duration(seconds: 20)) ??
            lastKnown;
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );
      } catch (_) {
        return await tryFix(accuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 15)) ??
            lastKnown;
      }
    } catch (_) {
      return null;
    }
  }

  /// Creates a new SOS request and returns request ID when successful.
  Future<String?> recordSosRequest({
    required String userId,
    required Position position,
    required String type,
    String? userNote,
    String? vehicleId,
    String? emergencyCategory,
  }) async {
    try {
      final note = (userNote ?? '').trim();

      final row = <String, dynamic>{
        'user_id': userId,
        'type': type,
        'status': 'pending',
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
        'user_note': note,
        'created_at': DateTime.now().toIso8601String(),
      };
      if (vehicleId != null && vehicleId.isNotEmpty) {
        row['vehicle_id'] = vehicleId;
      }
      if (emergencyCategory != null && emergencyCategory.isNotEmpty) {
        row['emergency_category'] = emergencyCategory;
      }

      final response = await _supabase.from('sos_requests').insert(row).select('id').single();
      
      return response['id'].toString();
    } catch (e) {
      print('Error recording SOS request: $e');
      return null;
    }
  }

  /// Opens SMS app with emergency message and current Google Maps location.
  Future<void> sendEmergencySms(Position position) async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
    final String message = "BOOSTDRIVE EMERGENCY SOS! My location: $googleMapsUrl";
    
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: emergencyNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  /// Streams active SOS requests for a specific customer.
  Stream<List<SosRequest>> streamActiveRequest(String userId) {
    return _supabase
        .from('sos_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data
            .where((item) {
              final st = (item['status']?.toString() ?? '').toLowerCase().trim();
              return const {'pending', 'accepted', 'assigned', 'active'}.contains(st);
            })
            .map((json) => SosRequest.fromMap(json))
            .toList());
  }

  /// Cancels the customer-owned SOS via RPC when available; otherwise RLS UPDATE.
  /// Also falls back on transport errors (`ClientException`, "Failed to fetch") so cancel
  /// still works if the RPC POST fails (CORS, proxy, flaky mobile/WASM networking).
  Future<void> cancelRequest(String requestId) async {
    Future<void> directCancel() async {
      await _supabase.from('sos_requests').update({'status': 'cancelled'}).eq('id', requestId);
    }

    try {
      await _supabase.rpc<void>(
        'cancel_my_sos_request',
        params: <String, dynamic>{'p_request_id': requestId},
      );
      return;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202' || e.code == '42883') {
        await directCancel();
        return;
      }
      rethrow;
    } on ClientException catch (_) {
      await directCancel();
      return;
    } catch (e) {
      if (_looksLikeTransportFailure(e)) {
        await directCancel();
        return;
      }
      rethrow;
    }
  }

  /// Opens phone dialer for emergency call.
  Future<void> callEmergencyServices(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    
    // Web needs platformDefault to let browser handle 'tel:'
    // Mobile needs externalApplication to launch dialer
    const mode = kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri, mode: mode);
    }
  }

  /// Pending SOS requests (for providers to accept).
  Stream<List<SosRequest>> getGlobalActiveRequests() {
    return _supabase
        .from('sos_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .where((row) => (row['status']?.toString() ?? '').toLowerCase().trim() == 'pending')
            .map((json) => SosRequest.fromMap(json))
            .toList());
  }

  /// Operationally active SOS requests for admin monitoring surfaces.
  /// Includes pending + in-progress assignment/execution statuses.
  Stream<List<SosRequest>> getGlobalOperationalActiveRequests() {
    const activeStatuses = <String>{'pending', 'assigned', 'accepted', 'active'};
    return _supabase
        .from('sos_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .where((row) => activeStatuses.contains((row['status']?.toString() ?? '').toLowerCase().trim()))
            .map((json) => SosRequest.fromMap(json))
            .toList());
  }

  /// Provider marks themselves as viewing a pending SOS (heartbeat for customer map).
  Future<void> upsertProviderResponding(String requestId) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    await _supabase.from('sos_provider_responding').upsert(
      <String, dynamic>{
        'sos_request_id': requestId,
        'provider_id': uid,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'sos_request_id,provider_id',
    );
  }

  /// Stop sending heartbeats when leaving the request screen without accepting.
  Future<void> deleteMyProviderResponding(String requestId) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    await _supabase
        .from('sos_provider_responding')
        .delete()
        .eq('sos_request_id', requestId)
        .eq('provider_id', uid);
  }

  /// Customer (or provider) listens for responding heartbeats on this SOS id.
  Stream<List<SosRespondingHeartbeat>> streamProviderRespondingForRequest(String requestId) {
    if (requestId.isEmpty) {
      return Stream.value(<SosRespondingHeartbeat>[]);
    }
    return _supabase
        .from('sos_provider_responding')
        .stream(primaryKey: ['sos_request_id', 'provider_id'])
        .eq('sos_request_id', requestId)
        .map((rows) {
          return rows.map((r) {
            return SosRespondingHeartbeat(
              sosRequestId: r['sos_request_id']?.toString() ?? '',
              providerId: r['provider_id']?.toString() ?? '',
              lastSeenAt: DateTime.tryParse(r['last_seen_at']?.toString() ?? '') ?? DateTime.utc(1970),
            );
          }).toList();
        });
  }

  /// Requests assigned to this provider (accepted by them).
  Stream<List<SosRequest>> streamProviderAssignedRequests(String providerId) {
    if (providerId.isEmpty) return Stream.value(<SosRequest>[]);
    return _pollProviderAssignedRequests(providerId);
  }

  /// Fetches provider-assigned SOS requests with retry on transient network failures.
  Future<List<SosRequest>> _fetchProviderAssignedRequests(String providerId) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
      try {
        final rows = await _supabase
            .from('sos_requests')
            .select()
            .eq('assigned_provider_id', providerId)
            .order('created_at', ascending: false);
        return (rows as List<dynamic>)
            .where((r) {
              final st = (r['status']?.toString() ?? '').toLowerCase().trim();
              return const {'accepted', 'assigned'}.contains(st);
            })
            .map((json) => SosRequest.fromMap(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        lastError = e;
        if (!_looksLikeTransportFailure(e)) rethrow;
        if (attempt == 2) {
          throw Exception(
            'Could not reach Supabase while loading assigned SOS orders. This is usually a brief network issue; '
            'on the web it is often caused by strict privacy blockers, flaky Wi‑Fi, or mixed-content rules. '
            'Try refreshing, another browser or network, or the Android/iOS app. '
            'Original error: $e',
          );
        }
      }
    }
    throw lastError ?? Exception('Failed to load assigned SOS');
  }

  /// Polls assigned SOS requests continuously and survives recoverable transient failures.
  Stream<List<SosRequest>> _pollProviderAssignedRequests(String providerId) async* {
    var everSucceeded = false;
    List<SosRequest> lastOk = [];
    while (true) {
      try {
        lastOk = await _fetchProviderAssignedRequests(providerId);
        everSucceeded = true;
        yield lastOk;
      } catch (e) {
        if (everSucceeded && _isRecoverableSosPollFailure(e)) {
          yield lastOk;
        } else {
          rethrow;
        }
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  /// Provider accepts a pending SOS request (sets assigned_provider_id, responded_at, status).
  Future<void> acceptRequest(String requestId, String providerId) async {
    // Check if the provider is suspended before allowing acceptance
    final profileResponse = await _supabase.from('profiles').select('status').eq('id', providerId).maybeSingle();
    if (profileResponse != null) {
      final status = profileResponse['status']?.toString().toLowerCase();
      if (status == 'suspended' || status == 'banned' || status == 'frozen') {
        throw Exception('Account is restricted. You cannot accept new SOS requests.');
      }
    }

    await _supabase.from('sos_requests').update({
      'assigned_provider_id': providerId,
      'responded_at': DateTime.now().toIso8601String(),
      'status': 'assigned',
    }).eq('id', requestId).eq('status', 'pending');

    final pos = await getCurrentLocation();
    if (pos != null) {
      await updateProviderTracking(
        requestId: requestId,
        providerId: providerId,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    }
  }

  /// Completes provider assignment via RPC after location validation.
  Future<void> completeAssignment({
    required String requestId,
    String? completionNote,
    int requiredDistanceMeters = 300,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final pos = await getCurrentLocation();
    if (pos == null) {
      throw Exception(
        kIsWeb
            ? 'Could not get your live location to close this SOS. Allow browser location and retry.'
            : 'Could not get GPS location. Enable location and retry.',
      );
    }
    await _supabase.rpc<void>(
      'complete_sos_assignment',
      params: <String, dynamic>{
        'p_request_id': requestId,
        'p_provider_lat': pos.latitude,
        'p_provider_lng': pos.longitude,
        'p_completion_note': (completionNote ?? '').trim().isEmpty ? null : completionNote!.trim(),
        'p_required_distance_meters': requiredDistanceMeters,
      },
    );
  }

  /// Cancels current provider assignment and optionally stores a reason.
  Future<void> cancelAssignmentByProvider({
    required String requestId,
    String? reason,
  }) async {
    if (requestId.isEmpty) throw Exception('Invalid SOS request');
    await _supabase.rpc<void>(
      'cancel_sos_assignment_by_provider',
      params: <String, dynamic>{
        'p_request_id': requestId,
        'p_reason': (reason ?? '').trim().isEmpty ? null : reason!.trim(),
      },
    );
  }

  /// Gets pending provider review prompts for a customer.
  Future<List<Map<String, dynamic>>> getPendingReviewPrompts(String customerId) async {
    if (customerId.isEmpty) return <Map<String, dynamic>>[];
    final rows = await _supabase
        .from('sos_provider_reviews')
        .select()
        .eq('customer_id', customerId)
        .isFilter('submitted_at', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List<dynamic>);
  }

  /// Submits a customer review for provider performance.
  Future<void> submitProviderReview({
    required String reviewId,
    required int rating,
    String? reviewText,
  }) async {
    await _supabase.from('sos_provider_reviews').update({
      'rating': rating.clamp(1, 5),
      'review_text': (reviewText ?? '').trim(),
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', reviewId);
  }

  /// Updates live provider position and heuristic ETA for the assigned SOS row.
  Future<bool> updateProviderTracking({
    required String requestId,
    required String providerId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final row = await _supabase
          .from('sos_requests')
          .select('assigned_provider_id, location')
          .eq('id', requestId)
          .maybeSingle();
      if (row == null) return false;
      if (row['assigned_provider_id']?.toString() != providerId) return false;

      final loc = row['location'] as Map<String, dynamic>? ?? {};
      final userLat = (loc['lat'] as num?)?.toDouble() ?? 0;
      final userLng = (loc['lng'] as num?)?.toDouble() ?? 0;
      final eta = GeoEta.etaMinutesBetweenPoints(latitude, longitude, userLat, userLng);

      await _supabase.from('sos_requests').update({
        'provider_last_lat': latitude,
        'provider_last_lng': longitude,
        'provider_location_updated_at': DateTime.now().toUtc().toIso8601String(),
        'eta_minutes': eta,
      }).eq('id', requestId).eq('assigned_provider_id', providerId);

      return true;
    } catch (e) {
      print('updateProviderTracking: $e');
      return false;
    }
  }

  /// SOS requests assigned to this provider that reached `completed` status.
  Future<int> countProviderCompletedSos(String providerId) async {
    if (providerId.isEmpty) return 0;
    try {
      final response = await _supabase
          .from('sos_requests')
          .select('id')
          .eq('assigned_provider_id', providerId)
          .inFilter('status', ['completed', 'resolved']);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Approximate count of verified provider profiles (for SOS “providers available” confidence UI).
  Future<int> countVerifiedProviders() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('verification_status', 'approved')
          .inFilter('role', [
            'provider',
            'service_provider',
            'service_pro',
            'mechanic',
            'towing',
            'logistics',
            'rental',
          ]);
      return (response as List).length;
    } catch (e) {
      print('DEBUG: countVerifiedProviders: $e');
      return 0;
    }
  }
}

final sosServiceProvider = Provider<SosService>((ref) => SosService());

final globalActiveSosRequestsProvider = StreamProvider<List<SosRequest>>((ref) {
  return ref.watch(sosServiceProvider).getGlobalActiveRequests();
});

/// Admin-focused live SOS stream with broader active statuses.
final globalOperationalActiveSosRequestsProvider = StreamProvider<List<SosRequest>>((ref) {
  return ref.watch(sosServiceProvider).getGlobalOperationalActiveRequests();
});

final userActiveSosRequestsProvider = StreamProvider.family<List<SosRequest>, String>((ref, userId) {
  return ref.watch(sosServiceProvider).streamActiveRequest(userId);
});

final verifiedProviderCountProvider = FutureProvider<int>((ref) {
  return ref.watch(sosServiceProvider).countVerifiedProviders();
});

/// For service providers: requests they have accepted (assigned to them).
final providerAssignedRequestsProvider = StreamProvider.family<List<SosRequest>, String>((ref, providerId) {
  return ref.watch(sosServiceProvider).streamProviderAssignedRequests(providerId);
});

/// Completed SOS count for provider dashboard stats.
final providerCompletedSosCountProvider = FutureProvider.family<int, String>((ref, providerId) {
  return ref.watch(sosServiceProvider).countProviderCompletedSos(providerId);
});

/// Live heartbeats: providers viewing this pending SOS (for customer map indicators).
final sosRespondingForRequestProvider =
    StreamProvider.family<List<SosRespondingHeartbeat>, String>((ref, requestId) {
  if (requestId.isEmpty) {
    return Stream.value(<SosRespondingHeartbeat>[]);
  }
  return ref.watch(sosServiceProvider).streamProviderRespondingForRequest(requestId);
});

final pendingSosReviewPromptsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) {
  return ref.watch(sosServiceProvider).getPendingReviewPrompts(customerId);
});
