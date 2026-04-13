import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'user_support_view.dart';
import 'boostdrive_banner.dart';

class CustomerDashboardPage extends ConsumerWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return PremiumPageLayout(
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Customer Dashboard',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1, color: Colors.white),
        ),
        actions: [
          _buildNotificationBell(context, ref, user.id),
          const SizedBox(width: 16),
        ],
      ),
      child: Column( // Still no extra SingleChildScrollView
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final alertsAsync = ref.watch(activeDashboardAlertsStreamProvider(user.id));
              return alertsAsync.when(
                data: (alerts) {
                  if (alerts.isEmpty) return const SizedBox.shrink();
                  return BoostDriveBanner(
                    alert: alerts.first,
                    onAction: (ticketId) {
                      ref.read(pendingSupportTicketIdProvider.notifier).state = ticketId;
                      // No need to switch section as CustomerDashboard is unified, 
                      // but we scroll to the bottom or let auto-open handle it.
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context, ref, user.id),
                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    return Column(
                      children: [
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildMainContent(context, ref, user.id)),
                              const SizedBox(width: 40),
                              Expanded(flex: 1, child: _buildSideContent(context, ref, user.id)),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildMainContent(context, ref, user.id),
                              const SizedBox(height: 40),
                              _buildSideContent(context, ref, user.id),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, WidgetRef ref, String uid) {
    final vehicles = ref.watch(userVehiclesProvider(uid)).valueOrNull ?? [];
    final orders = ref.watch(activeDeliveriesProvider(uid)).valueOrNull ?? [];
    
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${profile.fullName}',
              style: TextStyle(fontFamily: 'Manrope', 
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have ${vehicles.length} ${vehicles.length == 1 ? 'vehicle' : 'vehicles'} and ${orders.length} active ${orders.length == 1 ? 'order' : 'orders'}.',
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 18),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text('Error loading profile'),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Live Tracking', Icons.map_outlined),
            TextButton.icon(
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
                      body: ref.watch(activeDeliveriesProvider(uid)).when(
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
              icon: const Icon(Icons.open_in_full, color: Colors.white, size: 18),
              label: const Text('FULLSCREEN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          clipBehavior: Clip.antiAlias,
          child: ref.watch(activeDeliveriesProvider(uid)).when(
            data: (deliveries) {
              final activeDeliveries = deliveries.where((d) => d.status != 'delivered' && d.status != 'cancelled').toList();
              final Set<Marker> markers = activeDeliveries.map((d) {
                final lat = d.dropoffLocation['lat'] as double? ?? -22.5609;
                final lng = d.dropoffLocation['lng'] as double? ?? 17.0658;
                return Marker(
                  markerId: MarkerId(d.id),
                  position: LatLng(lat, lng),
                );
              }).toSet();
              return GoogleMap(
                initialCameraPosition: const CameraPosition(target: LatLng(-22.5609, 17.0658), zoom: 6),
                markers: markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        const SizedBox(height: 48),
        const CustomerGarageSectionHeader(title: 'My Garage', icon: Icons.directions_car),
        const SizedBox(height: 24),
        ref.watch(userVehiclesProvider(uid)).when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No vehicles found in your garage.', style: TextStyle(color: BoostDriveTheme.textDim)),
                  const SizedBox(height: 16),
                  CustomerGarageAddButton(label: 'Add Vehicle', onPressed: () => showCustomerAddVehicleDialog(context, ref, uid)),
                ],
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                // Use a much taller ratio on mobile (crossAxisCount == 1) to prevent bottom overflows
                final childAspectRatio = crossAxisCount == 2 ? 1.2 : 0.85;
                
                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vehicles.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final v = vehicles[index];
                        return KeyedSubtree(
                          key: ValueKey('vehicle-${v.id}'),
                          child: CustomerGarageVehicleCard(
                            vehicle: v,
                            onDelete: () => confirmDeleteCustomerVehicle(context, ref, v),
                            onEdit: () => showCustomerAddVehicleDialog(context, ref, uid, vehicle: v),
                            onDetails: () => showCustomerVehicleDetailsModal(context, ref, v),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomerGarageAddButton(label: 'Add Vehicle', onPressed: () => showCustomerAddVehicleDialog(context, ref, uid)),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Error loading garage'),
        ),
        const SizedBox(height: 48),
        _buildSectionHeader('Active Orders', Icons.local_shipping),
        const SizedBox(height: 24),
        ref.watch(activeDeliveriesProvider(uid)).when(
          data: (orders) {
            if (orders.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No active orders.', style: TextStyle(color: BoostDriveTheme.textDim)),
                ],
              );
            }
            return Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    final itemsMap = Map<String, dynamic>.from(o.items);
                    
                    // Simple logic for progress based on status
                    double progress = 0.2;
                    if (o.status == 'at_pickup' || o.status == 'picking_up') progress = 0.4;
                    if (o.status == 'in_transit') progress = 0.7;
                    if (o.status == 'delivered') progress = 1.0;

                    return KeyedSubtree(
                      key: ValueKey('order-${o.id}'),
                      child: CustomerGarageOrderCard(
                        title: itemsMap['title']?.toString() ?? 'Product Delivery',
                        id: '#${o.id.substring(0, 8).toUpperCase()}',
                        status: o.status.replaceAll('_', ' ').toUpperCase(),
                        description: itemsMap['description']?.toString() ?? 'See details for more info',
                        eta: o.eta.isNotEmpty ? o.eta : 'Calculating ETA...',
                        progress: progress,
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Error loading orders'),
        ),
        const SizedBox(height: 64),
        UserSupportView(userId: uid, userType: 'customer'),
      ],
    );
  }

  Widget _buildSideContent(BuildContext context, WidgetRef ref, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Service History', Icons.history),
        const SizedBox(height: 24),
        ref.watch(userServiceHistoryProvider(uid)).when(
          data: (history) {
            if (history.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No service records found.', style: TextStyle(color: BoostDriveTheme.textDim)),
                  const SizedBox(height: 16),
                  ref.watch(userVehiclesProvider(uid)).when(
                    data: (vehicles) => vehicles.isNotEmpty 
                      ? CustomerGarageAddButton(
                          label: 'Log First Service',
                          onPressed: () => showCustomerLogServiceDialog(context, ref, uid, vehicles.first.id),
                        )
                      : const SizedBox(),
                    loading: () => const SizedBox(),
                    error: (_, _) => const SizedBox(),
                  ),
                ],
              );
            }
            return Column(
              children: [
                ...history.map((item) => KeyedSubtree(
                  key: ValueKey('history-${item.id}'),
                  child: CustomerGarageHistoryItem(
                    item: item,
                    onDelete: () => confirmDeleteCustomerServiceRecord(context, ref, uid, item),
                    onEdit: () => showCustomerLogServiceDialog(context, ref, uid, item.vehicleId, record: item),
                    onDetails: () => showCustomerServiceRecordDetailsDialog(context, item),
                    onViewReceipts: item.receiptUrls.isNotEmpty
                        ? () => showCustomerViewReceiptsDialog(context, item.receiptUrls)
                        : null,
                  ),
                )),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (err, _) => Column(
            children: [
               const Icon(Icons.error_outline, color: Colors.redAccent),
               const SizedBox(height: 8),
               Text('Sync Error: $err', style: const TextStyle(color: Colors.redAccent, fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: BoostDriveTheme.primaryColor, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }


  Widget _buildNotificationBell(BuildContext context, WidgetRef ref, String uid) {
    final notificationsAsync = ref.watch(userNotificationsStreamProvider(uid));
    
    return notificationsAsync.when(
      data: (list) {
        final unreadCount = list.where((n) => n['is_read'] == false).length;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
              onPressed: () => _showNotificationsOverlay(context, ref, uid),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => IconButton(
        icon: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        onPressed: () => _showNotificationsOverlay(context, ref, uid),
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.notifications_off, color: Colors.white70),
        onPressed: () => _showNotificationsOverlay(context, ref, uid),
      ),
    );
  }

  void _showNotificationsOverlay(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) => NotificationsOverlay(
        onNotificationTap: (type, id) {
          if (type == 'support') {
            ref.read(pendingSupportTicketIdProvider.notifier).state = id;
            // No navigation needed as support is integrated on this page
          }
        },
      ),
    );
  }
}
