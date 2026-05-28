import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/provider_orders_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/fake_job_card_service.dart';
import '../support/fake_provider_ops_service.dart';
import '../support/fake_sos_service.dart';
import '../support/provider_orders_fixtures.dart';
import '../support/sos_fixtures.dart';
import '../support/test_bootstrap.dart';

Widget _wrap({
  required Widget child,
  required FakeSosService fakeSos,
  FakeProviderOpsService? fakeOps,
  FakeJobCardService? fakeJobs,
  User? user,
  UserProfile? profile,
}) {
  final uid = user?.id ?? 'provider-1';
  return ProviderScope(
    overrides: [
      sosServiceProvider.overrideWithValue(fakeSos),
      if (fakeOps != null) providerOpsServiceProvider.overrideWithValue(fakeOps),
      if (fakeJobs != null) jobCardServiceProvider.overrideWithValue(fakeJobs),
      currentUserProvider.overrideWithValue(user),
      userProfileProvider(uid).overrideWith((ref) async => profile),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: child,
    ),
  );
}

Future<void> _pumpOrders(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _selectTab(WidgetTester tester, String label) async {
  final tabBar = find.byType(TabBar);
  await tester.tap(find.descendant(of: tabBar, matching: find.text(label)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureTestSupabase();
  });

  group('ProviderOrdersPage', () {
    testWidgets('shows ORDERS header and SOS / REQUESTS / HISTORY tabs', (tester) async {
      final fakeSos = FakeSosService();
      await tester.pumpWidget(
        _wrap(
          fakeSos: fakeSos,
          user: testProviderUser(),
          profile: mechanicProviderProfile(),
          child: const ProviderOrdersPage(),
        ),
      );
      await _pumpOrders(tester);

      expect(find.text('ORDERS'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('REQUESTS'), findsOneWidget);
      expect(find.text('HISTORY'), findsOneWidget);
      expect(find.text('Urgent Assistance'), findsOneWidget);
    });

    testWidgets('SOS tab prompts to set service types when profile has none', (tester) async {
      final fakeSos = FakeSosService();
      await tester.pumpWidget(
        _wrap(
          fakeSos: fakeSos,
          user: testProviderUser(),
          profile: emptyServiceTypesProfile(),
          child: const ProviderOrdersPage(),
        ),
      );
      await _pumpOrders(tester);

      expect(
        find.text('Set service types in your profile to see matching SOS requests.'),
        findsOneWidget,
      );
    });

    testWidgets('SOS tab lists matching pending requests from global pool', (tester) async {
      final fakeSos = FakeSosService()
        ..globalPending = [
          pendingForOrdersPool(),
          SosRequest(
            id: 'pool-2',
            userId: 'c2',
            type: 'towing',
            status: 'pending',
            lat: 1,
            lng: 2,
            userNote: 'Need tow',
            createdAt: DateTime.utc(2026, 5, 27),
          ),
        ];

      await tester.pumpWidget(
        _wrap(
          fakeSos: fakeSos,
          user: testProviderUser(),
          profile: mechanicProviderProfile(),
          child: const ProviderOrdersPage(),
        ),
      );
      await _pumpOrders(tester);

      expect(find.text('No matching pending SOS.'), findsNothing);
      expect(find.text('ACCEPT'), findsOneWidget);
      expect(find.textContaining('Engine stalled'), findsOneWidget);
    });

    testWidgets('SOS tab shows focused job when provider already has assignment', (tester) async {
      final assigned = assignedToProviderRequest(providerId: 'provider-1');
      final fakeSos = FakeSosService()
        ..assignedByProvider['provider-1'] = [assigned]
        ..globalPending = [pendingForOrdersPool()];

      await tester.pumpWidget(
        _wrap(
          fakeSos: fakeSos,
          user: testProviderUser(),
          profile: mechanicProviderProfile(),
          child: const ProviderOrdersPage(),
        ),
      );
      await _pumpOrders(tester);

      expect(
        find.textContaining('You already accepted an SOS'),
        findsOneWidget,
      );
      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('CANCEL ASSIGNMENT'), findsOneWidget);
      expect(find.text('ACCEPT'), findsNothing);
    });

    testWidgets('SOS ACCEPT button calls FakeSosService.acceptRequest', (tester) async {
      final request = pendingForOrdersPool();
      final fakeSos = FakeSosService()..globalPending = [request];

      await tester.pumpWidget(
        _wrap(
          fakeSos: fakeSos,
          user: testProviderUser(),
          profile: mechanicProviderProfile(),
          child: const ProviderOrdersPage(),
        ),
      );
      await _pumpOrders(tester);

      await tester.tap(find.text('ACCEPT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakeSos.acceptCalls, hasLength(1));
      expect(fakeSos.acceptCalls.first.$1, request.id);
      expect(fakeSos.acceptCalls.first.$2, 'provider-1');
    });

    testWidgets('REQUESTS tab shows empty state when no jobs or requests', (tester) async {
      final fakeSos = FakeSosService();
      final fakeOps = FakeProviderOpsService();
      final fakeJobs = FakeJobCardService();

      await tester.pumpWidget(
        _wrap(
          fakeSos: fakeSos,
          fakeOps: fakeOps,
          fakeJobs: fakeJobs,
          user: testProviderUser(),
          profile: mechanicProviderProfile(),
          child: const ProviderOrdersPage(),
        ),
      );
      await _pumpOrders(tester);
      await _selectTab(tester, 'REQUESTS');

      expect(find.text('No active requests right now.'), findsOneWidget);
    });

    testWidgets('REQUESTS tab shows job card execution section', (tester) async {
      final fakeSos = FakeSosService();
      final fakeOps = FakeProviderOpsService();
      final fakeJobs = FakeJobCardService()
        ..executionByProvider['provider-1'] = [sampleExecutionJobCard()];

      await tester.pumpWidget(
        _wrap(
          fakeSos: fakeSos,
          fakeOps: fakeOps,
          fakeJobs: fakeJobs,
          user: testProviderUser(),
          profile: mechanicProviderProfile(),
          child: const ProviderOrdersPage(),
        ),
      );
      await _pumpOrders(tester);
      await _selectTab(tester, 'REQUESTS');

      expect(find.text('JOB CARD EXECUTION'), findsOneWidget);
      expect(find.text('Toyota Hilux'), findsOneWidget);
      expect(find.text('SET ACTIVE'), findsOneWidget);
    });

    testWidgets('HISTORY tab shows empty state', (tester) async {
      final fakeSos = FakeSosService();
      final fakeOps = FakeProviderOpsService();
      final fakeJobs = FakeJobCardService();

      await tester.pumpWidget(
        _wrap(
          fakeSos: fakeSos,
          fakeOps: fakeOps,
          fakeJobs: fakeJobs,
          user: testProviderUser(),
          profile: mechanicProviderProfile(),
          child: const ProviderOrdersPage(),
        ),
      );
      await _pumpOrders(tester);
      await _selectTab(tester, 'HISTORY');

      expect(find.text('No completed or cancelled history yet.'), findsOneWidget);
    });

    testWidgets('HISTORY tab lists completed job cards', (tester) async {
      final fakeSos = FakeSosService();
      final fakeOps = FakeProviderOpsService();
      final fakeJobs = FakeJobCardService()
        ..historyByProvider['provider-1'] = [sampleHistoryJobCard()];

      await tester.pumpWidget(
        _wrap(
          fakeSos: fakeSos,
          fakeOps: fakeOps,
          fakeJobs: fakeJobs,
          user: testProviderUser(),
          profile: mechanicProviderProfile(),
          child: const ProviderOrdersPage(),
        ),
      );
      await _pumpOrders(tester);
      await _selectTab(tester, 'HISTORY');

      expect(find.text('Ford Ranger'), findsOneWidget);
      expect(find.textContaining('completed'), findsWidgets);
    });

    testWidgets('shows login prompt when user is not signed in', (tester) async {
      final fakeSos = FakeSosService();
      await tester.pumpWidget(
        _wrap(
          fakeSos: fakeSos,
          user: null,
          profile: null,
          child: const ProviderOrdersPage(),
        ),
      );
      await _pumpOrders(tester);

      expect(find.text('Please log in'), findsOneWidget);
      expect(find.text('ORDERS'), findsNothing);
    });
  });
}
