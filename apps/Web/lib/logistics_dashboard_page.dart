import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class LogisticsDashboardPage extends ConsumerStatefulWidget {
  const LogisticsDashboardPage({super.key});

  @override
  ConsumerState<LogisticsDashboardPage> createState() => _LogisticsDashboardPageState();
}

class _LogisticsDashboardPageState extends ConsumerState<LogisticsDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  String _currentSection = 'HOME';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: Text('Please log in'));

    final isMobile = MediaQuery.of(context).size.width < 900;
    final contentPadding = isMobile ? const EdgeInsets.symmetric(horizontal: 12, vertical: 20) : const EdgeInsets.symmetric(horizontal: 64, vertical: 40);

    return SingleChildScrollView(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogisticsHeader(ref, user.id, isMobile),
          const SizedBox(height: 32),
          _buildTopNavBar(isMobile),
          const SizedBox(height: 48),
          _buildSectionContent(user.id, isMobile),
        ],
      ),
    );
  }

  Widget _buildTopNavBar(bool isMobile) {
    final sections = ['HOME', 'ROUTES', 'FLEET', 'FINANCE'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF101828),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: sections.map((section) {
            final isActive = _currentSection == section;
            IconData icon;
            switch (section) {
              case 'HOME': icon = Icons.grid_view_rounded; break;
              case 'ROUTES': icon = Icons.map_outlined; break;
              case 'FLEET': icon = Icons.local_shipping_outlined; break;
              case 'FINANCE': icon = Icons.account_balance_wallet_outlined; break;
              default: icon = Icons.help_outline;
            }
            return InkWell(
              onTap: () => setState(() => _currentSection = section),
              borderRadius: BorderRadius.circular(12),
              mouseCursor: SystemMouseCursors.click,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? BoostDriveTheme.surfaceDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: isActive ? BoostDriveTheme.primaryColor : Colors.white24, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      section,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white24,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLogisticsHeader(WidgetRef ref, String uid, bool isMobile) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BaTLorriH Logistics: ${profile.fullName}',
                  style: GoogleFonts.manrope(
                    fontSize: isMobile ? 28 : 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Parts Delivery • Vehicle Transport • Last-Mile Solutions',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: isMobile ? 14 : 18),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildSectionContent(String userId, bool isMobile) {
    if (_currentSection != 'HOME') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(80.0),
          child: Column(
            children: [
              Icon(Icons.construction, size: 64, color: BoostDriveTheme.primaryColor.withOpacity(0.5)),
              const SizedBox(height: 18),
              Text(
                '$_currentSection feature coming soon',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricsGrid(ref, userId, isMobile),
        const SizedBox(height: 35),
        _buildPurposeHighlights(isMobile),
        const SizedBox(height: 48),
        _buildDispatchMapHeader(context, ref, userId),
        const SizedBox(height: 24),
        _buildDispatchMap(ref, userId),
        const SizedBox(height: 48),
        _buildTabSection(),
        const SizedBox(height: 32),
        _buildOrderQueue(ref, userId),
      ],
    );
  }

  Widget _buildPurposeHighlights(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CORE LOGISTICS FOCUS',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        isMobile 
          ? Column(
              children: [
                _buildPurposeCard(Icons.settings_input_component, 'Parts Delivery', 'New, second-hand, or salvage parts from sellers to users/workshops.', isMobile),
                const SizedBox(height: 12),
                _buildPurposeCard(Icons.directions_car, 'Vehicle Transport', 'Rental deliveries and marketplace salvage/scrap vehicle movement.', isMobile),
                const SizedBox(height: 12),
                _buildPurposeCard(Icons.hub_outlined, 'Ecosystem Connectivity', 'Last-mile integration ensuring digital transactions become physical actions.', isMobile),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildPurposeCard(Icons.settings_input_component, 'Parts Delivery', 'New, second-hand, or salvage parts from sellers to users/workshops.', isMobile)),
                const SizedBox(width: 16),
                Expanded(child: _buildPurposeCard(Icons.directions_car, 'Vehicle Transport', 'Rental deliveries and marketplace salvage/scrap vehicle movement.', isMobile)),
                const SizedBox(width: 16),
                Expanded(child: _buildPurposeCard(Icons.hub_outlined, 'Ecosystem Connectivity', 'Last-mile integration ensuring digital transactions become physical actions.', isMobile)),
              ],
            ),
      ],
    );
  }

  Widget _buildPurposeCard(IconData icon, String title, String desc, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: BoostDriveTheme.primaryColor, size: 24),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(WidgetRef ref, String uid, bool isMobile) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final deliveriesAsync = ref.watch(activeDeliveriesProvider(uid));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return deliveriesAsync.when(
          data: (deliveries) {
            final activeCount = deliveries.where((d) => d.status != 'delivered' && d.status != 'cancelled').length;
            final completedCount = deliveries.where((d) => d.status == 'delivered').length;
            final successRate = completedCount == 0 ? 100 : (completedCount / (completedCount + deliveries.where((d) => d.status == 'cancelled').length) * 100).toInt();

            return LayoutBuilder(
              builder: (context, constraints) {
                final double horizontalPadding = isMobile ? 16 : 48;
                final double availableWidth = constraints.maxWidth - (horizontalPadding * 2);
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Center(
                    child: Wrap(
                      spacing: isMobile ? 12 : 24,
                      runSpacing: isMobile ? 12 : 24,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          width: isMobile ? (availableWidth - 12) / 2 : 240,
                          child: AspectRatio(
                            aspectRatio: isMobile ? 1.4 : 1.8,
                            child: _buildMetricCard(
                              'REVENUE', 
                              '\$${profile.totalEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}', 
                              '+12.4%', 
                              Icons.trending_up, 
                              Colors.green,
                              isMobile
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? (availableWidth - 12) / 2 : 240,
                          child: AspectRatio(
                            aspectRatio: isMobile ? 1.4 : 1.8,
                            child: _buildMetricCard(
                              'ACTIVE', 
                              activeCount.toString(), 
                              'Ongoing Tasks', 
                              Icons.local_shipping_outlined, 
                              BoostDriveTheme.primaryColor,
                              isMobile
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? (availableWidth - 12) / 2 : 240,
                          child: AspectRatio(
                            aspectRatio: isMobile ? 1.4 : 1.8,
                            child: _buildMetricCard(
                              'COMPLETED', 
                              completedCount.toString(), 
                              '$successRate% Success', 
                              Icons.check_circle_outline, 
                              Colors.green,
                              isMobile
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? (availableWidth - 12) / 2 : 240,
                          child: AspectRatio(
                            aspectRatio: isMobile ? 1.4 : 1.8,
                            child: _buildMetricCard(
                              'VOLUME', 
                              '${deliveries.length}', 
                              'Total Requests', 
                              Icons.bar_chart, 
                              Colors.blue,
                              isMobile
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const SizedBox(height: 75, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox(),
        );
      },
      loading: () => const SizedBox(height: 75, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildMetricCard(String label, String value, String subtext, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D25),
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
              fontSize: isMobile ? 9 : 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 0),
          Row(
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtext,
                  style: TextStyle(color: color, fontSize: isMobile ? 10 : 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchMapHeader(BuildContext context, WidgetRef ref, String uid) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Icon(Icons.map_outlined, color: BoostDriveTheme.primaryColor, size: 24),
             const SizedBox(width: 12),
             const Text(
              'Active Routes Map',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => Dialog.fullscreen(
                child: Scaffold(
                  backgroundColor: BoostDriveTheme.backgroundDark,
                  appBar: AppBar(
                    backgroundColor: BoostDriveTheme.primaryColor,
                    title: const Text('Active Routes Map', style: TextStyle(color: Colors.white)),
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: ref.watch(activeDeliveriesProvider(uid)).when(
                    data: (deliveries) {
                      final activeDeliveries = deliveries.where((d) => d.status != 'delivered' && d.status != 'cancelled').toList();
                      final Set<Marker> markers = activeDeliveries.map((d) {
                        final lat = d.dropoffLocation['lat'] as double? ?? -22.5609;
                        final lng = d.dropoffLocation['lng'] as double? ?? 17.0658;
                        return Marker(
                          markerId: MarkerId(d.id),
                          position: LatLng(lat, lng),
                          infoWindow: InfoWindow(
                            title: 'Order ${d.id.substring(0, 4)}',
                            snippet: d.status.replaceAll('_', ' ').toUpperCase(),
                          ),
                        );
                      }).toSet();
                      return GoogleMap(
                        initialCameraPosition: const CameraPosition(target: LatLng(-22.5609, 17.0658), zoom: 6),
                        markers: markers,
                        style: _mapStyle,
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
          icon: const Text('FULLSCREEN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          label: const Icon(Icons.open_in_full, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Widget _buildDispatchMap(WidgetRef ref, String uid) {
    return ref.watch(activeDeliveriesProvider(uid)).when(
      data: (deliveries) {
        final activeDeliveries = deliveries.where((d) => d.status != 'delivered' && d.status != 'cancelled').toList();
        
        // Compute markers locally to avoid side effects in build
        final Set<Marker> markers = activeDeliveries.map((d) {
          final lat = d.dropoffLocation['lat'] as double? ?? -22.5609; 
          final lng = d.dropoffLocation['lng'] as double? ?? 17.0658;
          
          return Marker(
            markerId: MarkerId(d.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: 'Order ${d.id.substring(0, 4)}',
              snippet: d.status.replaceAll('_', ' ').toUpperCase(),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              d.status == 'in_transit' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueAzure
            ),
          );
        }).toSet();

        return Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              _buildGoogleMap(markers),
              Positioned(
                top: 24,
                left: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D25).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Text('${activeDeliveries.length} ACTIVE DELIVERIES', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 400, 
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(32)),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  static const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#131d25"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#263c3f"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9a76"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#38414e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#212a37"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1f2835"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3d19c"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2f3948"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#515c6d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  }
]
''';

  Widget _buildGoogleMap(Set<Marker> markers) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(-22.5609, 17.0658),
        zoom: 6,
      ),
      markers: markers,
      style: _mapStyle,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildTabSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: BoostDriveTheme.primaryColor,
          unselectedLabelColor: BoostDriveTheme.textDim,
          indicatorColor: BoostDriveTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          onTap: (index) => setState(() {}),
          tabs: const [
            Tab(text: 'Active Queue'),
            Tab(text: 'Pickups'),
            Tab(text: 'Completed'),
          ],
        ),
        const Divider(color: Colors.white10, height: 1),
      ],
    );
  }

  Widget _buildOrderQueue(WidgetRef ref, String uid) {
    return ref.watch(activeDeliveriesProvider(uid)).when(
      data: (allOrders) {
        final orders = allOrders.where((o) {
          if (_tabController.index == 0) return o.status != 'delivered' && o.status != 'cancelled';
          if (_tabController.index == 1) return o.status == 'pending' || o.status == 'awaiting_pickup';
          if (_tabController.index == 2) return o.status == 'delivered';
          return true;
        }).toList();

        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: BoostDriveTheme.textDim.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No orders found for this category',
                    style: TextStyle(color: BoostDriveTheme.textDim),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final o = orders[index];
            return _buildOrderCard(
              status: o.status.toUpperCase().replaceAll('_', ' '),
              statusColor: o.status == 'delivered' ? Colors.green : BoostDriveTheme.primaryColor,
              id: '#BTL-${o.id.substring(0, 4).toUpperCase()}',
              eta: o.eta.isNotEmpty ? o.eta : 'N/A',
              pickup: o.pickupLocation['address'] ?? 'Unknown',
              dropoff: o.dropoffLocation['address'] ?? 'Unknown',
              isAwaiting: o.status == 'pending',
              orderIdForAction: o.id,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading queue'),
    );
  }

  Widget _buildOrderCard({
    required String status,
    required Color statusColor,
    required String id,
    required String eta,
    String etaLabel = 'ETA',
    required String pickup,
    required String dropoff,
    String? driver,
    bool isAwaiting = false,
    String? orderIdForAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131D25),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(etaLabel, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(eta, style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Order $id',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildLocationItem(Icons.radio_button_checked, Colors.blue, 'PICKUP', pickup),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Container(width: 2, height: 30, color: Colors.white10),
          ),
          const SizedBox(height: 12),
          _buildLocationItem(Icons.location_on, Colors.white24, 'DROP-OFF', dropoff),
          const SizedBox(height: 40),
          Row(
            children: [
              if (isAwaiting)
                 const Expanded(
                   child: Text(
                     'Finding nearest optimized route...',
                     style: TextStyle(color: Colors.white24, fontSize: 14, fontStyle: FontStyle.italic),
                   ),
                 )
              else
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      child: const Icon(Icons.person, color: Colors.white54, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      driver ?? 'Assigning...',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              if (!isAwaiting) const Spacer(),
              ElevatedButton(
                onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute<void>(builder: (BuildContext ctx) => ServiceTrackingPage(orderId: orderIdForAction ?? '')),
                   );
                   if (orderIdForAction != null) {
                      ref.read(deliveryServiceProvider).updateDeliveryStatus(orderIdForAction, 'delivered');
                   }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAwaiting ? BoostDriveTheme.primaryColor : const Color(0xFF1D2939),
                  minimumSize: const Size(140, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isAwaiting ? 'Assign' : 'Manage',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(IconData icon, Color iconColor, String label, String val) {
    return Row(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              val,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
