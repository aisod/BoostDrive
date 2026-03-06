import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'providers.dart';

class BaTLorriHLogisticsDashboard extends ConsumerStatefulWidget {
  const BaTLorriHLogisticsDashboard({super.key});

  @override
  ConsumerState<BaTLorriHLogisticsDashboard> createState() => _BaTLorriHLogisticsDashboardState();
}

class _BaTLorriHLogisticsDashboardState extends ConsumerState<BaTLorriHLogisticsDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(ref, user.id),
            const SizedBox(height: 32),
            _buildMetricsRow(ref, user.id),
            const SizedBox(height: 32),
            _buildPurposeHighlights(),
            const SizedBox(height: 32),
            _buildLiveDispatchMap(),
            const SizedBox(height: 32),
            _buildTabs(),
            const SizedBox(height: 24),
            _buildOrderList(ref, user.id),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CORE LOGISTICS FOCUS',
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        _buildPurposeCard(Icons.settings_input_component, 'Parts Delivery', 'Logistics from seller/warehouse to user or workshop.'),
        const SizedBox(height: 12),
        _buildPurposeCard(Icons.directions_car, 'Vehicle Transport', 'Rental deliveries and marketplace salvage movement.'),
        const SizedBox(height: 12),
        _buildPurposeCard(Icons.hub_outlined, 'Ecosystem Connectivity', 'Last-mile solution making digital transactions physical.'),
      ],
    );
  }

  Widget _buildPurposeCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: BoostDriveTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, String uid) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BoostDriveTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
               'BaTLorriH',
               style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Logistics • Parts & Vehicle Transport',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text('Error loading header'),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {bool hasNotification = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        if (hasNotification)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: BoostDriveTheme.backgroundDark, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricsRow(WidgetRef ref, String uid) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final deliveriesAsync = ref.watch(activeDeliveriesProvider(uid));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return deliveriesAsync.when(
          data: (deliveries) {
            final completedCount = deliveries.where((d) => d.status == 'delivered').length;
            
            return Row(
              children: [
                Expanded(child: _buildMetricCard('REVENUE', '\$${profile.totalEarnings.toStringAsFixed(0)}', '+12.4%', true)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('DELIVERIES', completedCount.toString(), '98% Success', false, isSuccess: true)),
              ],
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildMetricCard(String label, String value, String subtext, bool isTrend, {bool isSuccess = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: BoostDriveTheme.textDim,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isTrend) const Icon(Icons.trending_up, color: Colors.green, size: 14),
              if (isSuccess) const Icon(Icons.check_circle, color: Colors.green, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtext,
                  style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDispatchMap() {
    final user = ref.read(currentUserProvider);
    if (user == null) return const SizedBox();

    return ref.watch(activeDeliveriesProvider(user.id)).when(
      data: (deliveries) {
        final activeDeliveries = deliveries.where((d) => d.status != 'delivered' && d.status != 'cancelled').toList();
        
        final Set<Marker> markers = activeDeliveries.map((d) {
          final lat = d.dropoffLocation['lat'] as double? ?? -22.5609;
          final lng = d.dropoffLocation['lng'] as double? ?? 17.0658;
          
          return Marker(
            markerId: MarkerId(d.id),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              d.status == 'in_transit' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueAzure
            ),
          );
        }).toSet();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map_outlined, color: BoostDriveTheme.primaryColor, size: 18),
                    SizedBox(width: 8),
                    Text('Live Dispatch Map', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog.fullscreen(
                        child: Scaffold(
                          backgroundColor: BoostDriveTheme.backgroundDark,
                          appBar: AppBar(
                            backgroundColor: BoostDriveTheme.primaryColor,
                            title: const Text('Live Dispatch Map', style: TextStyle(color: Colors.white)),
                            leading: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          body: ref.watch(activeDeliveriesProvider(user.id)).when(
                            data: (deliveries) {
                              final activeDeliveries = deliveries.where((d) => d.status != 'delivered' && d.status != 'cancelled').toList();
                              final Set<Marker> markers = activeDeliveries.map((d) {
                                final lat = d.dropoffLocation['lat'] as double? ?? -22.5609;
                                final lng = d.dropoffLocation['lng'] as double? ?? 17.0658;
                                return Marker(
                                  markerId: MarkerId(d.id),
                                  position: LatLng(lat, lng),
                                  infoWindow: InfoWindow(title: 'Order ${d.id.substring(0, 4)}'),
                                );
                              }).toSet();
                              return GoogleMap(
                                initialCameraPosition: const CameraPosition(target: LatLng(-22.5609, 17.0658), zoom: 6),
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
                  },
                  child: const Row(
                    children: [
                      Text('FULLSCREEN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.open_in_full, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  GoogleMap(
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
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: BoostDriveTheme.backgroundDark.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('${activeDeliveries.length} DRIVERS LIVE', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      indicatorColor: BoostDriveTheme.primaryColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: BoostDriveTheme.primaryColor,
      unselectedLabelColor: BoostDriveTheme.textDim,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
      onTap: (index) => setState(() {}),
      tabs: const [
        Tab(text: 'Active Queue'),
        Tab(text: 'Pickups'),
        Tab(text: 'Completed'),
      ],
    );
  }

  Widget _buildOrderList(WidgetRef ref, String uid) {
    return ref.watch(activeDeliveriesProvider(uid)).when(
      data: (allOrders) {
        final orders = allOrders.where((o) {
          if (_tabController.index == 0) return o.status != 'delivered' && o.status != 'cancelled';
          if (_tabController.index == 1) return o.status == 'pending' || o.status == 'awaiting_pickup';
          if (_tabController.index == 2) return o.status == 'delivered';
          return true;
        }).toList();

        if (orders.isEmpty) return Text('No orders in this category.', style: TextStyle(color: BoostDriveTheme.textDim));
        return Column(
          children: orders.map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildOrderCard(
              status: o.status.toUpperCase().replaceAll('_', ' '),
              statusColor: o.status == 'delivered' ? Colors.green : (o.status == 'in_transit' ? Colors.orange : BoostDriveTheme.primaryColor),
              orderId: '#${o.id.substring(0, 8).toUpperCase()}',
              eta: o.eta.isNotEmpty ? o.eta : 'N/A',
              pickup: o.pickupLocation['address'] ?? 'Unknown Pickup',
              dropoff: o.dropoffLocation['address'] ?? 'Unknown Drop-off',
              driver: 'Assigned Driver', // Placeholder until driver profile fetching is implemented
              actionText: o.status == 'pending' ? 'Assign' : 'Manage',
              isAwaiting: o.status == 'pending',
            ),
          )).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error loading orders'),
    );
  }

  Widget _buildOrderCard({
    required String status,
    required Color statusColor,
    required String orderId,
    required String eta,
    String etaLabel = 'ETA',
    required String pickup,
    required String dropoff,
    required String driver,
    required String actionText,
    bool isAwaiting = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(etaLabel, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(eta, style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Order $orderId', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildLocationItem(Icons.radio_button_checked, Colors.blue, 'PICKUP', pickup),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Container(width: 1, height: 20, color: Colors.white10),
          ),
          _buildLocationItem(Icons.location_on, Colors.white24, 'DROP-OFF', dropoff),
          const SizedBox(height: 24),
          Row(
            children: [
              if (!isAwaiting)
                Container(
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                ),
              if (!isAwaiting) const SizedBox(width: 12),
              if (!isAwaiting)
                Text(driver, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              if (isAwaiting)
                const Text('Finding nearest optimized route...', style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic)),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute<void>(builder: (BuildContext ctx) => ServiceTrackingPage(orderId: orderId)),
                   );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: !isAwaiting ? Colors.white.withOpacity(0.05) : BoostDriveTheme.primaryColor,
                  foregroundColor: !isAwaiting ? BoostDriveTheme.primaryColor : Colors.white,
                  minimumSize: const Size(100, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(actionText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(IconData icon, Color iconColor, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 9, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
