import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SosRequest', () {
    test('fromMap parses optional telemetry and live statuses', () {
      final request = SosRequest.fromMap({
        'id': 'sos-1',
        'user_id': 'user-1',
        'status': 'active',
        'location': {'lat': -22.57, 'lng': 17.08},
        'provider_last_lat': '-22.58',
        'provider_last_lng': 17.09,
        'eta_minutes': '8',
        'created_at': '2026-04-22T10:00:00Z',
      });

      expect(request.id, 'sos-1');
      expect(request.providerLastLat, closeTo(-22.58, 0.0001));
      expect(request.providerLastLng, closeTo(17.09, 0.0001));
      expect(request.etaMinutes, 8);
      expect(request.isCustomerSosLive, isTrue);
    });

    test('fromMap accepts sos_request_id alias', () {
      final request = SosRequest.fromMap({
        'sos_request_id': 'legacy-id',
        'user_id': 'u1',
        'status': 'pending',
        'location': {'lat': 1, 'lng': 2},
      });
      expect(request.id, 'legacy-id');
    });

    test('isCustomerSosLive is false for resolved requests', () {
      final request = SosRequest.fromMap({
        'id': 'sos-2',
        'user_id': 'user-2',
        'status': 'resolved',
        'location': {'lat': -22.0, 'lng': 17.0},
      });

      expect(request.isCustomerSosLive, isFalse);
    });

    test('copyWith updates assignment fields', () {
      final original = SosRequest.fromMap({
        'id': 'sos-3',
        'user_id': 'user-3',
        'status': 'pending',
        'location': {'lat': -22.0, 'lng': 17.0},
      });
      final updated = original.copyWith(
        status: 'assigned',
        assignedProviderId: 'provider-9',
        etaMinutes: 12,
      );
      expect(updated.status, 'assigned');
      expect(updated.assignedProviderId, 'provider-9');
      expect(updated.etaMinutes, 12);
      expect(original.status, 'pending');
    });
  });
}
