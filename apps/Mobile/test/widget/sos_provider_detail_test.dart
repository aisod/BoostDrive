import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/sos_request_detail_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/fake_sos_service.dart';
import '../support/sos_fixtures.dart';
import '../support/test_bootstrap.dart';

User _testUser({required String id, String email = 'test@boostdrive.local'}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime.utc(2026, 1, 1).toIso8601String(),
    email: email,
  );
}

Widget _wrap({
  required Widget child,
  required FakeSosService fakeSos,
  User? user,
}) {
  final uid = user?.id;
  return ProviderScope(
    overrides: [
      sosServiceProvider.overrideWithValue(fakeSos),
      if (user != null) currentUserProvider.overrideWithValue(user),
      if (uid != null) userProfileProvider(uid).overrideWith((ref) async => null),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureTestSupabase();
  });

  group('SosRequestDetailPage provider actions', () {
    testWidgets('shows ACCEPT for pending unassigned request', (tester) async {
      final fake = FakeSosService();
      final request = pendingMechanicRequest();

      await tester.pumpWidget(
        _wrap(
          fakeSos: fake,
          user: _testUser(id: 'provider-1'),
          child: SosRequestDetailPage(request: request),
        ),
      );
      await tester.pump();

      expect(find.text('ACCEPT REQUEST'), findsOneWidget);
      expect(find.text('ASSIGNMENT DONE'), findsNothing);
    });

    testWidgets('accept button calls FakeSosService.acceptRequest', (tester) async {
      final fake = FakeSosService();
      final request = pendingMechanicRequest();

      await tester.pumpWidget(
        _wrap(
          fakeSos: fake,
          user: _testUser(id: 'provider-1'),
          child: SosRequestDetailPage(request: request),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('ACCEPT REQUEST'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fake.acceptCalls, hasLength(1));
      expect(fake.acceptCalls.first.$1, request.id);
      expect(fake.acceptCalls.first.$2, 'provider-1');
    });

    testWidgets('assigned provider sees complete and cancel assignment actions', (tester) async {
      final fake = FakeSosService();
      final request = assignedToProviderRequest(providerId: 'provider-1');

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(
          fakeSos: fake,
          user: _testUser(id: 'provider-1'),
          child: SosRequestDetailPage(request: request),
        ),
      );
      await tester.pump();

      expect(find.text('ASSIGNED TO YOU'), findsOneWidget);
      expect(find.text('ASSIGNMENT DONE'), findsOneWidget);
      expect(find.text('CANCEL ASSIGNMENT'), findsOneWidget);
    });

    testWidgets('provider assigned to another user cannot accept', (tester) async {
      final fake = FakeSosService();
      final request = assignedToProviderRequest(providerId: 'other-provider');

      await tester.pumpWidget(
        _wrap(
          fakeSos: fake,
          user: _testUser(id: 'provider-1'),
          child: SosRequestDetailPage(request: request),
        ),
      );
      await tester.pump();

      expect(find.text('ALREADY ASSIGNED'), findsOneWidget);
      final acceptButton = tester.widget<FilledButton>(find.byType(FilledButton).first);
      expect(acceptButton.onPressed, isNull);
    });
  });
}
