import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boost_drive_web/add_fleet_vehicle_dialog.dart';

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

    final palette = DashboardPalette.of(context);
    return ColoredBox(
      color: palette.background,
      child: SingleChildScrollView(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogisticsHeader(ref, user.id, isMobile, palette),
            const SizedBox(height: 32),
            _buildTopNavBar(isMobile, palette),
            const SizedBox(height: 48),
            _buildSectionContent(user.id, isMobile, palette),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar(bool isMobile, DashboardPalette palette) {
    const sections = ['HOME', 'ROUTES', 'FLEET', 'FINANCE'];
    final items = sections.map((section) {
      final icon = switch (section) {
        'HOME' => Icons.grid_view_rounded,
        'ROUTES' => Icons.map_outlined,
        'FLEET' => Icons.local_shipping_outlined,
        'FINANCE' => Icons.account_balance_wallet_outlined,
        _ => Icons.help_outline,
      };
      return ProviderSectionNavItem(id: section, label: section, icon: icon);
    }).toList();
    return ProviderDashboardUi.sectionNav(
      palette: palette,
      items: items,
      currentId: _currentSection,
      onSelected: (id) => setState(() => _currentSection = id),
    );
  }

  Widget _buildLogisticsHeader(WidgetRef ref, String uid, bool isMobile, DashboardPalette palette) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return ProviderDashboardUi.logisticsHeader(
          palette: palette,
          providerName: profile.fullName,
          compact: isMobile,
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: palette.primary)),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildSectionContent(String userId, bool isMobile, DashboardPalette palette) {
    switch (_currentSection) {
      case 'ROUTES':
        return _buildRoutesSection(userId, isMobile, palette);
      case 'FLEET':
        return _buildFleetSection(userId, isMobile, palette);
      case 'FINANCE':
        return _buildFinanceSection(userId, isMobile, palette);
      case 'HOME':
        break;
      default:
        return _buildRoutesSection(userId, isMobile, palette);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricsGrid(ref, userId, isMobile, palette),
        const SizedBox(height: 35),
        _buildPurposeHighlights(isMobile, palette),
        const SizedBox(height: 48),
        _buildDispatchMapHeader(context, ref, userId, palette),
        const SizedBox(height: 24),
        _buildDispatchMap(ref, userId, palette),
        const SizedBox(height: 48),
        _buildTabSection(palette),
        const SizedBox(height: 32),
        _buildOrderQueue(ref, userId, palette),
      ],
    );
  }

  Widget _buildPurposeHighlights(bool isMobile, DashboardPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CORE LOGISTICS FOCUS', style: DashboardTypography.sectionLabel(palette)),
        const SizedBox(height: 16),
        isMobile 
          ? Column(
              children: [
                ProviderDashboardUi.purposeCard(palette: palette, icon: Icons.settings_input_component, title: 'Parts Delivery', description: 'New, second-hand, or salvage parts from sellers to users/workshops.'),
                const SizedBox(height: 12),
                ProviderDashboardUi.purposeCard(palette: palette, icon: Icons.directions_car, title: 'Vehicle Transport', description: 'Rental deliveries and marketplace salvage/scrap vehicle movement.'),
                const SizedBox(height: 12),
                ProviderDashboardUi.purposeCard(palette: palette, icon: Icons.hub_outlined, title: 'Ecosystem Connectivity', description: 'Last-mile integration ensuring digital transactions become physical actions.'),
              ],
            )
          : Row(
              children: [
                Expanded(child: ProviderDashboardUi.purposeCard(palette: palette, icon: Icons.settings_input_component, title: 'Parts Delivery', description: 'New, second-hand, or salvage parts from sellers to users/workshops.')),
                const SizedBox(width: 16),
                Expanded(child: ProviderDashboardUi.purposeCard(palette: palette, icon: Icons.directions_car, title: 'Vehicle Transport', description: 'Rental deliveries and marketplace salvage/scrap vehicle movement.')),
                const SizedBox(width: 16),
                Expanded(child: ProviderDashboardUi.purposeCard(palette: palette, icon: Icons.hub_outlined, title: 'Ecosystem Connectivity', description: 'Last-mile integration ensuring digital transactions become physical actions.')),
              ],
            ),
      ],
    );
  }

  Widget _buildMetricsGrid(WidgetRef ref, String uid, bool isMobile, DashboardPalette palette) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final deliveriesAsync = ref.watch(logisticsOrdersProvider(uid));

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
                          child: ProviderDashboardUi.metricTile(
                            palette: palette,
                            label: 'REVENUE',
                            value: '\$${profile.totalEarnings.toStringAsFixed(0)}',
                            subtext: '+12.4%',
                            icon: Icons.trending_up,
                            accent: palette.success,
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? (availableWidth - 12) / 2 : 240,
                          child: ProviderDashboardUi.metricTile(
                            palette: palette,
                            label: 'ACTIVE',
                            value: activeCount.toString(),
                            subtext: 'Ongoing Tasks',
                            icon: Icons.local_shipping_outlined,
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? (availableWidth - 12) / 2 : 240,
                          child: ProviderDashboardUi.metricTile(
                            palette: palette,
                            label: 'COMPLETED',
                            value: completedCount.toString(),
                            subtext: '$successRate% Success',
                            icon: Icons.check_circle_outline,
                            accent: palette.success,
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? (availableWidth - 12) / 2 : 240,
                          child: ProviderDashboardUi.metricTile(
                            palette: palette,
                            label: 'VOLUME',
                            value: '${deliveries.length}',
                            subtext: 'Total Requests',
                            icon: Icons.bar_chart,
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
          error: (_, _) => const SizedBox(),
        );
      },
      loading: () => const SizedBox(height: 75, child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildDispatchMapHeader(BuildContext context, WidgetRef ref, String uid, DashboardPalette palette) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        DashboardSectionHeader(title: 'Active Routes Map', icon: Icons.map_outlined),
        TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => Dialog.fullscreen(
                child: Scaffold(
                  backgroundColor: palette.background,
                  appBar: AppBar(
                    backgroundColor: palette.primaryContainer,
                    foregroundColor: palette.onPrimary,
                    title: const Text('Active Routes Map'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: ref.watch(logisticsOrdersProvider(uid)).when(
                    data: (deliveries) {
                      final activeDeliveries = deliveries.where((d) => d.status != 'delivered' && d.status != 'cancelled').toList();
                      final markers = _buildDeliveryMarkers(activeDeliveries);
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
          icon: Text('FULLSCREEN', style: DashboardTypography.labelMd(palette).copyWith(fontWeight: FontWeight.w800)),
          label: Icon(Icons.open_in_full, color: palette.onBackground, size: 18),
        ),
      ],
    );
  }

  Widget _buildDispatchMap(WidgetRef ref, String uid, DashboardPalette palette) {
    return ref.watch(logisticsOrdersProvider(uid)).when(
      data: (deliveries) {
        final activeDeliveries = deliveries.where((d) => d.status != 'delivered' && d.status != 'cancelled').toList();
        final markers = _buildDeliveryMarkers(activeDeliveries);

        return Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              _buildGoogleMap(markers),
              Positioned(
                top: 24,
                left: 24,
                child: ProviderDashboardUi.mapLiveStatusBar(palette, activeCount: activeDeliveries.length),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 400, 
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(32)),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox(),
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

  Widget _buildTabSection(DashboardPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: palette.primary,
          unselectedLabelColor: palette.muted,
          indicatorColor: palette.primary,
          indicatorWeight: 3,
          labelStyle: DashboardTypography.labelLg(palette),
          onTap: (index) => setState(() {}),
          tabs: const [
            Tab(text: 'Active Queue'),
            Tab(text: 'Pickups'),
            Tab(text: 'Completed'),
          ],
        ),
        Divider(color: palette.primary.withValues(alpha: 0.25), height: 1),
      ],
    );
  }

  Widget _buildOrderQueue(WidgetRef ref, String uid, DashboardPalette palette) {
    return ref.watch(logisticsOrdersProvider(uid)).when(
      data: (allOrders) {
        final orders = allOrders.where((o) {
          if (_tabController.index == 0) return o.status != 'delivered' && o.status != 'cancelled';
          if (_tabController.index == 1) return o.status == 'pending' || o.status == 'picking_up';
          if (_tabController.index == 2) return o.status == 'delivered';
          return true;
        }).toList();

        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: BoostDriveTheme.textDim.withValues(alpha: 0.5)),
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
          separatorBuilder: (_, _) => const SizedBox(height: 24),
          itemBuilder: (context, index) => _buildOrderCardFromOrder(ref, uid, orders[index], palette),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error loading queue'),
    );
  }

  Widget _buildOrderCard({
    required DashboardPalette palette,
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
    DeliveryOrder? order,
    String? logisticsUserId,
  }) {
    final uid = logisticsUserId ?? '';
    final statusLower = order?.status.toLowerCase() ?? status.toLowerCase();
    final driverId = order?.driverId?.trim();
    final isAssignedToMe = driverId != null && driverId == uid;
    final canAssign = statusLower == 'pending' && uid.isNotEmpty;
    final canProgress = isAssignedToMe && (statusLower == 'picking_up' || statusLower == 'in_transit');
    final nextStatus = statusLower == 'picking_up'
        ? 'in_transit'
        : (statusLower == 'in_transit' ? 'delivered' : null);
    final actionText = canAssign
        ? 'Assign'
        : (canProgress ? (nextStatus == 'in_transit' ? 'Start transit' : 'Mark delivered') : 'Manage');
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: ProviderDashboardUi.surfaceCard(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
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
                  Text(etaLabel, style: DashboardTypography.labelMd(palette)),
                  const SizedBox(height: 4),
                  Text(
                    eta,
                    style: DashboardTypography.headlineMd(palette).copyWith(color: palette.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Order $id', style: DashboardTypography.headlineMd(palette)),
          const SizedBox(height: 24),
          _buildLocationItem(palette, Icons.radio_button_checked, palette.primary, 'PICKUP', pickup),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Container(width: 2, height: 30, color: palette.primary.withValues(alpha: 0.35)),
          ),
          const SizedBox(height: 12),
          _buildLocationItem(palette, Icons.location_on, palette.muted, 'DROP-OFF', dropoff),
          const SizedBox(height: 40),
          Row(
            children: [
              if (isAwaiting)
                 const Expanded(
                   child: Text(
                     'Finding nearest optimized route...',
                     style: TextStyle(color: Color(0x22FF6600), fontSize: 14, fontStyle: FontStyle.italic),
                   ),
                 )
              else
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
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
                onPressed: orderIdForAction == null
                    ? null
                    : () async {
                        try {
                          if (canAssign && order != null) {
                            await ref.read(deliveryServiceProvider).assignOrderToDriver(
                                  orderId: order.id,
                                  driverId: uid,
                                  eta: order.eta.isNotEmpty ? order.eta : '30 min',
                                );
                            ref.invalidate(logisticsOrdersProvider(uid));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Assigned to you. Proceed to pickup.')),
                              );
                            }
                            return;
                          }
                          if (canProgress && nextStatus != null && order != null) {
                            await ref.read(deliveryServiceProvider).updateDeliveryStatus(order.id, nextStatus);
                            ref.invalidate(logisticsOrdersProvider(uid));
                            if (mounted) {
                              final label = nextStatus == 'in_transit' ? 'Order now in transit.' : 'Order marked delivered.';
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
                            }
                            return;
                          }
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext ctx) => ServiceTrackingPage(orderId: orderIdForAction),
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not update order: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAssign ? palette.primaryBright : palette.surfaceContainerHighest,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(140, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildDeliveryMarkers(List<DeliveryOrder> orders, {bool activeOnly = true}) {
    final filtered = activeOnly
        ? orders.where((d) => d.status != 'delivered' && d.status != 'cancelled')
        : orders;
    return filtered.map((d) {
      final pos = d.markerCoordinates();
      return Marker(
        markerId: MarkerId(d.id),
        position: LatLng(pos.lat, pos.lng),
        infoWindow: InfoWindow(
          title: 'Order ${d.id.substring(0, 4).toUpperCase()}',
          snippet: d.status.replaceAll('_', ' ').toUpperCase(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          d.status == 'in_transit'
              ? BitmapDescriptor.hueOrange
              : (d.status == 'picking_up' ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueAzure),
        ),
      );
    }).toSet();
  }

  Widget _buildRoutesSection(String userId, bool isMobile, DashboardPalette palette) {
    return ref.watch(logisticsOrdersProvider(userId)).when(
      data: (orders) {
        final active = orders.where((d) => d.status != 'delivered' && d.status != 'cancelled').toList();
        final markers = _buildDeliveryMarkers(active);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACTIVE ROUTES', style: DashboardTypography.sectionLabel(palette)),
            const SizedBox(height: 8),
            Text(
              '${active.length} routes in progress • Markers use live driver GPS when available',
              style: DashboardTypography.bodySm(palette),
            ),
            const SizedBox(height: 24),
            Container(
              height: isMobile ? 360 : 520,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildGoogleMap(markers),
            ),
            const SizedBox(height: 32),
            if (active.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('No active routes.', style: TextStyle(color: BoostDriveTheme.textDim)),
                ),
              )
            else
              ...active.map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildOrderCardFromOrder(ref, userId, o, palette),
                  )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading routes: $e', style: const TextStyle(color: Colors.redAccent)),
    );
  }

  Widget _buildFleetSection(String userId, bool isMobile, DashboardPalette palette) {
    return ref.watch(userVehiclesProvider(userId)).when(
      data: (vehicles) {
        final fleet = vehicles.where((v) => v.type == 'logistics').toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardPageHeader(
              title: 'FLEET VEHICLES',
              subtitle: 'Trucks and vans registered for BaTLorriH deliveries',
              trailing: ProviderDashboardUi.primaryFilledButton(
                palette: palette,
                label: 'Add vehicle',
                icon: Icons.add,
                onPressed: () async {
                  final added = await showDialog<bool>(
                    context: context,
                    builder: (_) => AddFleetVehicleDialog(ownerId: userId),
                  );
                  if (added == true && mounted) {
                    ref.invalidate(userVehiclesProvider(userId));
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            if (fleet.isEmpty)
              ProviderDashboardUi.emptyPanel(
                palette: palette,
                icon: Icons.local_shipping_outlined,
                title: 'No Assets Registered',
                message:
                    'Your fleet management dashboard is currently empty. Register your first transport unit to begin tracking.',
                minHeight: 400,
                action: OutlinedButton(
                  onPressed: () async {
                    final added = await showDialog<bool>(
                      context: context,
                      builder: (_) => AddFleetVehicleDialog(ownerId: userId),
                    );
                    if (added == true && mounted) ref.invalidate(userVehiclesProvider(userId));
                  },
                  child: const Text('Register first vehicle'),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = isMobile ? 1 : (constraints.maxWidth > 900 ? 3 : 2);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isMobile ? 2.2 : 1.6,
                    ),
                    itemCount: fleet.length,
                    itemBuilder: (context, index) => _buildFleetCard(fleet[index], userId, palette),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading fleet: $e'),
    );
  }

  Widget _buildFleetCard(Vehicle vehicle, String userId, DashboardPalette palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ProviderDashboardUi.surfaceCard(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: BoostDriveTheme.primaryColor, size: 28),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () async {
                  await ref.read(vehicleServiceProvider).deleteVehicle(vehicle.id);
                  if (mounted) ref.invalidate(userVehiclesProvider(userId));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${vehicle.year} ${vehicle.make} ${vehicle.model}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(vehicle.plateNumber, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13)),
          const SizedBox(height: 8),
          Text('${vehicle.healthStatus} • ${vehicle.fuelLevel} fuel', style: TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFinanceSection(String userId, bool isMobile, DashboardPalette palette) {
    final financeAsync = ref.watch(logisticsFinanceProvider(userId));
    return financeAsync.when(
      data: (summary) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProviderDashboardUi.logisticsSectionTitle(palette: palette, section: 'FINANCE OVERVIEW'),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  ProviderDashboardUi.metricTile(palette: palette, label: 'LIFETIME EARNINGS', value: 'N\$${summary.lifetimeEarnings.toStringAsFixed(2)}', subtext: 'All time', icon: Icons.account_balance_wallet),
                  ProviderDashboardUi.metricTile(palette: palette, label: 'THIS MONTH', value: 'N\$${summary.periodEarnings.toStringAsFixed(2)}', subtext: 'Current period', icon: Icons.calendar_today, accent: palette.secondary),
                  ProviderDashboardUi.metricTile(palette: palette, label: 'PENDING PAYOUT', value: 'N\$${summary.pendingPayouts.toStringAsFixed(2)}', subtext: 'Awaiting transfer', icon: Icons.pending_outlined, highlightBorder: true),
                  ProviderDashboardUi.metricTile(palette: palette, label: 'COMPLETED', value: '${summary.completedCount}', subtext: 'Deliveries', icon: Icons.check_circle_outline, accent: palette.success),
                ];
                if (isMobile || constraints.maxWidth < 700) {
                  return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
                }
                return Row(
                  children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList(),
                );
              },
            ),
            const SizedBox(height: 40),
            const Text('RECENT COMPLETED DELIVERIES', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 16),
            if (summary.recentCompleted.isEmpty)
              Text('No completed deliveries yet.', style: TextStyle(color: BoostDriveTheme.textDim))
            else
              ...summary.recentCompleted.map((o) {
                final fee = o.deliveryFee ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#BTL-${o.id.substring(0, 6).toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(o.dropoffLocation['address']?.toString() ?? 'Delivery', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        fee > 0 ? 'N\$${fee.toStringAsFixed(2)}' : '—',
                        style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.read(paymentServiceProvider).getProviderTransactions(userId),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.isEmpty) {
                  return Text('No payout transactions on file.', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PAYOUT TRANSACTIONS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    ...snap.data!.take(8).map((tx) {
                      final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
                      final status = tx['status']?.toString() ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('N\$${amt.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(status.toUpperCase(), style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11)),
                        trailing: Text(
                          tx['created_at']?.toString().substring(0, 10) ?? '',
                          style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading finance: $e'),
    );
  }

  Widget _buildOrderCardFromOrder(WidgetRef ref, String uid, DeliveryOrder order, DashboardPalette palette) {
    final status = order.status.toLowerCase();
    final driverId = order.driverId?.trim();
    final driverProfile = (driverId != null && driverId.isNotEmpty)
        ? ref.watch(userProfileProvider(driverId)).valueOrNull
        : null;
    final driverLabel = driverProfile?.fullName ?? (driverId != null && driverId.isNotEmpty ? 'Driver assigned' : null);

    return _buildOrderCard(
      palette: palette,
      status: order.status.toUpperCase().replaceAll('_', ' '),
      statusColor: status == 'delivered' ? palette.success : palette.primary,
      id: '#BTL-${order.id.substring(0, 4).toUpperCase()}',
      eta: order.eta.isNotEmpty ? order.eta : 'N/A',
      pickup: order.pickupLocation['address']?.toString() ?? 'Unknown',
      dropoff: order.dropoffLocation['address']?.toString() ?? 'Unknown',
      isAwaiting: status == 'pending',
      orderIdForAction: order.id,
      driver: driverLabel,
      order: order,
      logisticsUserId: uid,
    );
  }

  Widget _buildLocationItem(DashboardPalette palette, IconData icon, Color iconColor, String label, String val) {
    return Row(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: DashboardTypography.labelMd(palette)),
            const SizedBox(height: 4),
            Text(
              val,
              style: DashboardTypography.labelLg(palette),
            ),
          ],
        ),
      ],
    );
  }
}
