import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:intl/intl.dart';
import 'dashboard_palette.dart';
import 'mobile_logistics_ui.dart';

class ServiceTrackingPage extends ConsumerWidget {
  final String orderId;
  const ServiceTrackingPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(singleDeliveryProvider(orderId))
        .when(
          data: (order) {
            if (order == null)
              return const Scaffold(
                body: Center(child: Text('Order not found')),
              );
            final palette = DashboardPalette.of(context);

            final steps = _buildStepData(order.status);
            final timeline = _buildTimeline(order);
            final orderCode = order.id
                .substring(0, order.id.length >= 8 ? 8 : order.id.length)
                .toUpperCase();
            final etaValue = order.status == 'delivered'
                ? 'Delivered'
                : (order.eta.isNotEmpty ? order.eta : 'Calculating…');

            return Scaffold(
              backgroundColor: palette.background,
              appBar: MobileLogisticsUi.trackingAppBar(
                context: context,
                palette: palette,
                onContact: () {},
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MobileLogisticsUi.trackingMapHero(
                      palette: palette,
                      etaLabel: 'Estimated arrival',
                      etaValue: etaValue,
                    ),
                    const SizedBox(height: 16),
                    MobileLogisticsUi.trackingStepper(
                      palette: palette,
                      steps: steps,
                    ),
                    const SizedBox(height: 16),
                    MobileLogisticsUi.trackingInfoCard(
                      palette: palette,
                      title: 'ORDER DETAILS',
                      rows: [
                        (label: 'Order', value: '#$orderCode'),
                        (
                          label: 'Pickup',
                          value:
                              order.pickupLocation['address']?.toString() ??
                              'Unknown pickup',
                        ),
                        (
                          label: 'Drop-off',
                          value:
                              order.dropoffLocation['address']?.toString() ??
                              'Unknown destination',
                        ),
                        (
                          label: 'Status',
                          value: order.status
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MobileLogisticsUi.trackingPartnerCard(
                      palette: palette,
                      name: 'Logistics Partner',
                      role:
                          order.driverId != null &&
                              order.driverId!.trim().isNotEmpty
                          ? 'Driver Assigned: ${order.driverId}'
                          : 'Waiting for driver',
                      onCall: () {},
                      onMessage: () {},
                    ),
                    const SizedBox(height: 16),
                    MobileLogisticsUi.trackingHistorySection(
                      palette: palette,
                      events: timeline,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        );
  }

  List<({String label, bool complete, bool active})> _buildStepData(
    String status,
  ) {
    const order = ['pending', 'picking_up', 'in_transit', 'delivered'];
    final currentIndex = order.indexOf(status);

    return [
      (label: 'PENDING', complete: currentIndex > 0, active: currentIndex == 0),
      (label: 'PICKUP', complete: currentIndex > 1, active: currentIndex == 1),
      (
        label: 'IN TRANSIT',
        complete: currentIndex > 2,
        active: currentIndex == 2,
      ),
      (
        label: 'DELIVERED',
        complete: currentIndex >= 3,
        active: currentIndex == 3,
      ),
    ];
  }

  List<({String title, String time, bool isLatest})> _buildTimeline(
    DeliveryOrder order,
  ) {
    final events = <({String title, String time, bool isLatest})>[];
    final nowLabel = DateFormat('HH:mm').format(order.createdAt);

    events.add((
      title: 'Order created and confirmed',
      time: nowLabel,
      isLatest: order.status == 'pending',
    ));

    if (order.status == 'picking_up' ||
        order.status == 'in_transit' ||
        order.status == 'delivered') {
      events.add((
        title: 'Driver assigned and heading to pickup',
        time: 'Update',
        isLatest: order.status == 'picking_up',
      ));
    }

    if (order.status == 'in_transit' || order.status == 'delivered') {
      events.add((
        title: 'Package picked up and in transit',
        time: 'Update',
        isLatest: order.status == 'in_transit',
      ));
    }

    if (order.status == 'delivered') {
      events.add((
        title: 'Order delivered successfully',
        time: 'Final',
        isLatest: true,
      ));
    }

    return events.reversed.toList();
  }
}
