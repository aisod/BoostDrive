import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:flutter_test/flutter_test.dart';

SosRequest _request({
  String id = 'sos-1',
  String status = 'pending',
  String type = 'mechanic',
  String? emergencyCategory,
  String? assignedProviderId,
}) {
  return SosRequest(
    id: id,
    userId: 'customer-1',
    type: type,
    status: status,
    lat: -22.57,
    lng: 17.08,
    userNote: 'Need help',
    createdAt: DateTime.utc(2026, 4, 22, 10),
    assignedProviderId: assignedProviderId,
    emergencyCategory: emergencyCategory,
  );
}

void main() {
  group('SOS status helpers', () {
    test('customer live statuses', () {
      expect(sosStatusIsCustomerLive('pending'), isTrue);
      expect(sosStatusIsCustomerLive('assigned'), isTrue);
      expect(sosStatusIsCustomerLive('accepted'), isTrue);
      expect(sosStatusIsCustomerLive('active'), isTrue);
      expect(sosStatusIsCustomerLive('completed'), isFalse);
      expect(sosStatusIsCustomerLive('cancelled'), isFalse);
      expect(sosStatusIsCustomerLive('resolved'), isFalse);
    });

    test('provider assigned statuses', () {
      expect(sosStatusIsProviderAssigned('assigned'), isTrue);
      expect(sosStatusIsProviderAssigned('accepted'), isTrue);
      expect(sosStatusIsProviderAssigned('pending'), isFalse);
    });

    test('filterCustomerLiveRequests keeps only live rows', () {
      final rows = [
        _request(status: 'pending'),
        _request(id: 'sos-2', status: 'resolved'),
        _request(id: 'sos-3', status: 'active'),
      ];
      final live = filterCustomerLiveRequests(rows);
      expect(live.map((r) => r.id), ['sos-1', 'sos-3']);
    });
  });

  group('sosRequestMatchesProviderServiceTypes', () {
    test('matches on type', () {
      final request = _request(type: 'mechanic');
      expect(
        sosRequestMatchesProviderServiceTypes(request, ['mechanic', 'towing']),
        isTrue,
      );
    });

    test('matches on emergency category', () {
      final request = _request(type: 'emergency', emergencyCategory: 'flat_tire');
      expect(
        sosRequestMatchesProviderServiceTypes(request, ['flat_tire']),
        isTrue,
      );
    });

    test('returns false when provider has no service types', () {
      expect(sosRequestMatchesProviderServiceTypes(_request(), []), isFalse);
    });
  });

  group('SosProviderUiRules', () {
    const providerId = 'provider-1';

    test('provider can accept pending unassigned request', () {
      final request = _request(status: 'pending');
      expect(SosProviderUiRules.canAccept(request: request, userId: providerId), isTrue);
      expect(
        SosProviderUiRules.actionLabel(request: request, userId: providerId),
        'ACCEPT REQUEST',
      );
    });

    test('provider cannot accept request assigned to someone else', () {
      final request = _request(status: 'assigned', assignedProviderId: 'other');
      expect(SosProviderUiRules.canAccept(request: request, userId: providerId), isFalse);
      expect(
        SosProviderUiRules.actionLabel(request: request, userId: providerId),
        'ALREADY ASSIGNED',
      );
    });

    test('assigned provider can complete active assignment', () {
      final request = _request(status: 'active', assignedProviderId: providerId);
      expect(SosProviderUiRules.isAssignedToMe(request: request, userId: providerId), isTrue);
      expect(SosProviderUiRules.canComplete(request: request, userId: providerId), isTrue);
      expect(SosProviderUiRules.canCancelAssignment(request: request, userId: providerId), isTrue);
    });

    test('invalid requester location at 0,0 is rejected', () {
      final request = SosRequest(
        id: 'sos-x',
        userId: 'c1',
        type: 'mechanic',
        status: 'pending',
        lat: 0,
        lng: 0,
        userNote: '',
        createdAt: DateTime.now(),
      );
      expect(SosProviderUiRules.hasValidRequesterLocation(request), isFalse);
    });
  });

  group('filterProviderPendingPool', () {
    test('filters global pending list by provider capabilities', () {
      final all = [
        _request(id: 'a', type: 'mechanic'),
        _request(id: 'b', type: 'towing'),
        _request(id: 'c', type: 'towing', emergencyCategory: 'flat_tire'),
      ];
      final pending = filterProviderPendingPool(
        allPending: all,
        providerServiceTypes: ['mechanic'],
      );
      expect(pending.map((r) => r.id), ['a']);
    });
  });
}
