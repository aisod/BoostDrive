import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Provider SOS pool filtering', () {
    test('only matching pending requests are shown to mechanic providers', () {
      final all = [
        SosRequest(
          id: '1',
          userId: 'c1',
          type: 'mechanic',
          status: 'pending',
          lat: 1,
          lng: 2,
          userNote: '',
          createdAt: DateTime.now(),
        ),
        SosRequest(
          id: '2',
          userId: 'c2',
          type: 'towing',
          status: 'pending',
          lat: 1,
          lng: 2,
          userNote: '',
          createdAt: DateTime.now(),
        ),
      ];

      final filtered = filterProviderPendingPool(
        allPending: all,
        providerServiceTypes: const ['mechanic'],
      );

      expect(filtered, hasLength(1));
      expect(filtered.first.id, '1');
    });
  });
}
