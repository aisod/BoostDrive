// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BaTLorriHLogisticsDashboard extends ConsumerStatefulWidget {
  const BaTLorriHLogisticsDashboard({super.key});

  @override
  ConsumerState<BaTLorriHLogisticsDashboard> createState() =>
      _BaTLorriHLogisticsDashboardState();
}

class _BaTLorriHLogisticsDashboardState
    extends ConsumerState<BaTLorriHLogisticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // ignore: unused_field - used by GoogleMap onMapCreated callback
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: Text('Please log in'));
    final palette = DashboardPalette.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: MobileLogisticsUi.marginMobile,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildHeader(user.id, palette),
          const SizedBox(height: 20),
          _buildMetrics(user.id, palette),
          const SizedBox(height: 16),
          MobileLogisticsUi.focusCardsRow(
            palette: palette,
            items: const [
              (icon: Icons.local_shipping_outlined, label: 'PARTS DELIVERY'),
              (
                icon: Icons.directions_car_filled_outlined,
                label: 'VEHICLE TRANSPORT',
              ),
              (icon: Icons.hub_outlined, label: 'ECOSYSTEM LINK'),
            ],
          ),
          const SizedBox(height: 20),
          _buildMap(user.id, palette),
          const SizedBox(height: 20),
          MobileLogisticsUi.orderTabs(
            palette: palette,
            selectedIndex: _tabController.index,
            onChanged: (i) => _tabController.animateTo(i),
            labels: const ['ACTIVE', 'PICKUPS', 'DONE'],
          ),
          const SizedBox(height: 16),
          _buildOrders(user.id, palette),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildHeader(String uid, DashboardPalette palette) {
    return ref
        .watch(userProfileProvider(uid))
        .when(
          data: (profile) {
            if (profile == null) return const SizedBox();
            return MobileLogisticsUi.shiftHeader(
              palette: palette,
              partnerName: profile.fullName,
              chips: const ['ON DUTY', 'LIVE GPS', 'BATLORRIH'],
            );
          },
          loading: () => const SizedBox(height: 88),
          error: (_, _) => const SizedBox(),
        );
  }

  Widget _buildMetrics(String uid, DashboardPalette palette) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final deliveriesAsync = ref.watch(logisticsOrdersProvider(uid));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return deliveriesAsync.when(
          data: (deliveries) {
            final completedCount = deliveries
                .where((d) => d.status == 'delivered')
                .length;

            return MobileLogisticsUi.metricsRow(
              palette: palette,
              revenueLabel: 'Revenue',
              revenueValue: '\$${profile.totalEarnings.toStringAsFixed(0)}',
              jobsLabel: 'Deliveries',
              jobsValue: '$completedCount',
              revenueTrend: 'On track',
              jobsTrend: 'Completed',
            );
          },
          loading: () => const SizedBox(),
          error: (_, _) => const SizedBox(),
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildMap(String uid, DashboardPalette palette) {
    return ref
        .watch(logisticsOrdersProvider(uid))
        .when(
          data: (deliveries) {
            final activeDeliveries = deliveries
                .where(
                  (d) => d.status != 'delivered' && d.status != 'cancelled',
                )
                .toList();

            final Set<Marker> markers = activeDeliveries.map((d) {
              final lat =
                  d.driverLastLat ??
                  (d.dropoffLocation['lat'] as double?) ??
                  -22.5609;
              final lng =
                  d.driverLastLng ??
                  (d.dropoffLocation['lng'] as double?) ??
                  17.0658;

              return Marker(
                markerId: MarkerId(d.id),
                position: LatLng(lat, lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  d.status == 'in_transit'
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueAzure,
                ),
              );
            }).toSet();

            final nextDrop = activeDeliveries.isNotEmpty
                ? (activeDeliveries.first.dropoffLocation['address']
                          ?.toString() ??
                      'Drop-off point')
                : null;

            return MobileLogisticsUi.liveDispatchMap(
              palette: palette,
              nextDropoffAddress: nextDrop,
              onFullscreen: () => _showFullscreenMap(uid, palette),
              mapChild: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-22.5609, 17.0658),
                  zoom: 6,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: markers,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              ),
            );
          },
          loading: () => const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SizedBox(),
        );
  }

  Future<void> _showFullscreenMap(String uid, DashboardPalette palette) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.primaryContainer,
            title: const Text(
              'Live Dispatch Map',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.maybePop(context),
            ),
            actions: const [DashboardThemeToggle(), SizedBox(width: 8)],
          ),
          body: ref
              .watch(logisticsOrdersProvider(uid))
              .when(
                data: (deliveries) {
                  final activeDeliveries = deliveries
                      .where(
                        (d) =>
                            d.status != 'delivered' && d.status != 'cancelled',
                      )
                      .toList();
                  final Set<Marker> markers = activeDeliveries.map((d) {
                    final lat =
                        d.driverLastLat ??
                        (d.dropoffLocation['lat'] as double?) ??
                        -22.5609;
                    final lng =
                        d.driverLastLng ??
                        (d.dropoffLocation['lng'] as double?) ??
                        17.0658;
                    return Marker(
                      markerId: MarkerId(d.id),
                      position: LatLng(lat, lng),
                      infoWindow: InfoWindow(
                        title:
                            'Order ${d.id.substring(0, d.id.length >= 6 ? 6 : d.id.length).toUpperCase()}',
                      ),
                    );
                  }).toSet();
                  return GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-22.5609, 17.0658),
                      zoom: 6,
                    ),
                    markers: markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
        ),
      ),
    );
  }

  Widget _buildOrders(String uid, DashboardPalette palette) {
    return ref
        .watch(logisticsOrdersProvider(uid))
        .when(
          data: (allOrders) {
            final orders = allOrders.where((o) {
              if (_tabController.index == 0) {
                return o.status != 'delivered' && o.status != 'cancelled';
              }
              if (_tabController.index == 1) {
                return o.status == 'pending' || o.status == 'picking_up';
              }
              if (_tabController.index == 2) return o.status == 'delivered';
              return true;
            }).toList();

            if (orders.isEmpty) {
              return MobileLogisticsUi.emptyOrders(
                palette: palette,
                message: 'No orders in this category.',
              );
            }
            return Column(
              children: orders
                  .map((o) => _buildOrderCard(uid, o, palette))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Error loading orders'),
        );
  }

  Widget _buildOrderCard(
    String uid,
    DeliveryOrder order,
    DashboardPalette palette,
  ) {
    final status = order.status.toLowerCase();
    final orderIdDisplay =
        '#${order.id.substring(0, order.id.length >= 8 ? 8 : order.id.length).toUpperCase()}';
    final eta = order.eta.isNotEmpty ? order.eta : 'N/A';
    final pickup =
        order.pickupLocation['address']?.toString() ?? 'Unknown Pickup';
    final dropoff =
        order.dropoffLocation['address']?.toString() ?? 'Unknown Drop-off';
    final isAwaiting = status == 'pending';
    final driverId = order.driverId?.trim();
    final driverProfile = (driverId != null && driverId.isNotEmpty)
        ? ref.watch(userProfileProvider(driverId)).valueOrNull
        : null;
    final driverLabel = driverProfile?.fullName.trim().isNotEmpty == true
        ? driverProfile!.fullName
        : ((driverId != null && driverId.isNotEmpty)
              ? 'Driver: ${driverId.substring(0, driverId.length >= 8 ? 8 : driverId.length)}'
              : 'Unassigned');

    final isAssignedToMe = driverId != null && driverId == uid;
    final canAssign = status == 'pending';
    final canProgress =
        isAssignedToMe && (status == 'picking_up' || status == 'in_transit');
    final nextStatus = status == 'picking_up'
        ? 'in_transit'
        : (status == 'in_transit' ? 'delivered' : null);
    final actionText = canAssign
        ? 'Assign to me'
        : (canProgress
              ? (nextStatus == 'in_transit'
                    ? 'Start transit'
                    : 'Mark delivered')
              : 'View');

    if (status == 'delivered') {
      return MobileLogisticsUi.deliveredOrderCard(
        palette: palette,
        title: 'Order $orderIdDisplay',
        subtitle: dropoff,
        destination: dropoff,
        completedLabel: eta,
        onView: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext ctx) =>
                  ServiceTrackingPage(orderId: order.id),
            ),
          );
        },
      );
    }

    return MobileLogisticsUi.logisticsOrderCard(
      palette: palette,
      title: 'Order $orderIdDisplay',
      subtitle: dropoff,
      status: status,
      leadingIcon: status == 'pending'
          ? Icons.assignment_late_outlined
          : Icons.local_shipping,
      highlightBorder: status == 'picking_up' || status == 'in_transit',
      statCells: [(label: 'Pickup', value: pickup), (label: 'ETA', value: eta)],
      progress: status == 'picking_up' || status == 'in_transit'
          ? MobileLogisticsUi.statusProgress(status)
          : null,
      actions: [
        if (!isAwaiting)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              driverLabel,
              style: DashboardTypography.bodySm(palette).copyWith(
                color: palette.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        MobileLogisticsUi.actionRow(
          palette: palette,
          secondary: MobileLogisticsUi.secondaryActionButton(
            palette: palette,
            label: 'DETAILS',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext ctx) =>
                      ServiceTrackingPage(orderId: order.id),
                ),
              );
            },
          ),
          primary: MobileLogisticsUi.primaryActionButton(
            label: actionText.toUpperCase(),
            icon: canAssign
                ? Icons.person_add
                : (canProgress ? Icons.speed : Icons.visibility_outlined),
            onPressed: () async {
              try {
                if (canAssign) {
                  await ref
                      .read(deliveryServiceProvider)
                      .updateDeliveryStatus(
                        order.id,
                        'picking_up',
                        driverId: uid,
                        eta: order.eta.isNotEmpty ? order.eta : '30 min',
                      );
                  ref.invalidate(logisticsOrdersProvider(uid));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Assigned to you. Proceed to pickup.'),
                      ),
                    );
                  }
                  return;
                }
                if (canProgress && nextStatus != null) {
                  await ref
                      .read(deliveryServiceProvider)
                      .updateDeliveryStatus(order.id, nextStatus);
                  ref.invalidate(logisticsOrdersProvider(uid));
                  if (context.mounted) {
                    final label = nextStatus == 'in_transit'
                        ? 'Order now in transit.'
                        : 'Order marked delivered.';
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(label)));
                  }
                  return;
                }
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext ctx) =>
                        ServiceTrackingPage(orderId: order.id),
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not update order: $e')),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
