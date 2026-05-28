import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MobileLogisticsUi helpers', () {
    test('orderDisplayTitle prefers item name fields', () {
      expect(
        MobileLogisticsUi.orderDisplayTitle(
          orderId: 'abc12345',
          items: {'name': 'Brake Kit'},
        ),
        'Brake Kit',
      );
    });

    test('orderDisplayTitle falls back to short order id', () {
      expect(
        MobileLogisticsUi.orderDisplayTitle(orderId: 'abc12345'),
        'Order #ABC12345',
      );
    });

    test('statusBadgeLabel maps known delivery statuses', () {
      expect(MobileLogisticsUi.statusBadgeLabel('pending'), 'Pending');
      expect(MobileLogisticsUi.statusBadgeLabel('picking_up'), 'In Progress');
      expect(MobileLogisticsUi.statusBadgeLabel('in_transit'), 'In Transit');
      expect(MobileLogisticsUi.statusBadgeLabel('delivered'), 'Delivered');
    });

    test('statusProgress increases through active delivery states', () {
      expect(MobileLogisticsUi.statusProgress('pending'), lessThan(0.5));
      expect(MobileLogisticsUi.statusProgress('picking_up'), 0.5);
      expect(MobileLogisticsUi.statusProgress('in_transit'), greaterThan(0.5));
      expect(MobileLogisticsUi.statusProgress('delivered'), 1.0);
    });
  });

  group('MobileLogisticsUi widgets', () {
    testWidgets('shiftHeader shows partner name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final palette = DashboardPalette.of(context);
              return Scaffold(
                body: MobileLogisticsUi.shiftHeader(
                  palette: palette,
                  partnerName: 'Test Driver',
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('ACTIVE SHIFT'), findsOneWidget);
      expect(find.textContaining('BaTLorriH Logistics: Test Driver'), findsOneWidget);
    });

    testWidgets('orderTabs highlights selected tab', (tester) async {
      var selected = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              final palette = DashboardPalette.of(context);
              return Scaffold(
                body: MobileLogisticsUi.orderTabs(
                  palette: palette,
                  selectedIndex: selected,
                  labels: const ['ACTIVE', 'PICKUPS', 'DONE'],
                  onChanged: (index) => setState(() => selected = index),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('PICKUPS'), findsOneWidget);
      await tester.tap(find.text('DONE'));
      await tester.pump();
      expect(selected, 2);
    });
  });
}
