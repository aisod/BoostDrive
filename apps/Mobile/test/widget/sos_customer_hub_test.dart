import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/emergency_hub_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/fake_sos_service.dart';
import '../support/sos_fixtures.dart';
import '../support/test_bootstrap.dart';

User _customerUser() {
  return User(
    id: 'customer-1',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime.utc(2026, 1, 1).toIso8601String(),
    email: 'customer@test.com',
  );
}

AuthState _signedInState(User user) {
  return AuthState(
    AuthChangeEvent.signedIn,
    Session(
      accessToken: 'test-token',
      tokenType: 'bearer',
      user: user,
    ),
  );
}

Widget _wrap({
  required Widget child,
  required FakeSosService fakeSos,
  required User user,
}) {
  return ProviderScope(
    overrides: [
      sosServiceProvider.overrideWithValue(fakeSos),
      authStateProvider.overrideWith((ref) => Stream.value(_signedInState(user))),
      verifiedProviderCountProvider.overrideWith((ref) async => 3),
      pendingSosReviewPromptsProvider(user.id).overrideWith((ref) async => []),
      userVehiclesProvider(user.id).overrideWith((ref) => Stream.value([])),
    ],
    child: MaterialApp(home: child),
  );
}

Future<void> _pumpHub(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureTestSupabase();
  });

  group('EmergencyHubPage customer SOS', () {
    testWidgets('shows hold trigger when no active SOS', (tester) async {
      final fake = FakeSosService();
      await tester.pumpWidget(
        _wrap(
          fakeSos: fake,
          user: _customerUser(),
          child: const EmergencyHubPage(),
        ),
      );
      await _pumpHub(tester);

      expect(find.text('EMERGENCY SOS'), findsOneWidget);
      expect(find.textContaining('LIVE SOS'), findsNothing);
    });

    testWidgets('shows live dispatch card for active pending request', (tester) async {
      final fake = FakeSosService();
      final request = pendingMechanicRequest();
      fake.userActiveRequests['customer-1'] = [request];

      await tester.pumpWidget(
        _wrap(
          fakeSos: fake,
          user: _customerUser(),
          child: const EmergencyHubPage(),
        ),
      );
      await _pumpHub(tester);

      expect(find.textContaining('LIVE SOS'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('customer cancel calls FakeSosService.cancelRequest', (tester) async {
      final fake = FakeSosService();
      final request = pendingMechanicRequest();
      fake.userActiveRequests['customer-1'] = [request];

      await tester.pumpWidget(
        _wrap(
          fakeSos: fake,
          user: _customerUser(),
          child: const EmergencyHubPage(),
        ),
      );
      await _pumpHub(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(fake.cancelCustomerCalls, contains(request.id));
    });
  });
}
