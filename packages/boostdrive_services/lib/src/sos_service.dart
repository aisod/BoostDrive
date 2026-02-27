import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SosService {
  final _supabase = Supabase.instance.client;
  static const String emergencyNumber = "+264811234567"; // Namibia dispatch placeholder

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String?> recordSosRequest({
    required String userId,
    required Position position,
    required String type,
    String? userNote,
  }) async {
    try {
      final response = await _supabase.from('sos_requests').insert({
        'user_id': userId,
        'type': type,
        'status': 'pending',
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
        'user_note': userNote ?? '',
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();
      
      return response['id'].toString();
    } catch (e) {
      print('Error recording SOS request: $e');
      return null;
    }
  }

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

  Stream<List<Map<String, dynamic>>> streamActiveRequest(String userId) {
    return _supabase
        .from('sos_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.where((item) => ['pending', 'accepted', 'assigned'].contains(item['status'])).toList());
  }

  Future<void> cancelRequest(String requestId) async {
    await _supabase.from('sos_requests').update({
      'status': 'cancelled',
    }).eq('id', requestId);
  }

  Future<void> callEmergencyServices(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    
    // Web needs platformDefault to let browser handle 'tel:'
    // Mobile needs externalApplication to launch dialer
    const mode = kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri, mode: mode);
    }
  }

  Stream<List<Map<String, dynamic>>> getGlobalActiveRequests() {
    return _supabase
        .from('sos_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }
}

final sosServiceProvider = Provider<SosService>((ref) => SosService());

final globalActiveSosRequestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(sosServiceProvider).getGlobalActiveRequests();
});

final userActiveSosRequestsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return ref.watch(sosServiceProvider).streamActiveRequest(userId);
});
