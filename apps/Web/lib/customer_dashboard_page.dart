import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      ),
      child: Column( // Still no extra SingleChildScrollView
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              style: GoogleFonts.manrope(
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
            border: Border.all(color: Colors.white.withOpacity(0.05)),
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
        _buildSectionHeader('My Garage', Icons.directions_car),
        const SizedBox(height: 24),
        ref.watch(userVehiclesProvider(uid)).when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No vehicles found in your garage.', style: TextStyle(color: BoostDriveTheme.textDim)),
                  const SizedBox(height: 16),
                  _buildAddButton(context, 'Add Vehicle', () => _showAddVehicleDialog(context, ref, uid)),
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
                          child: _buildVehicleCard(context, ref, v),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildAddButton(context, 'Add Vehicle', () => _showAddVehicleDialog(context, ref, uid)),
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
                      child: _buildOrderCard(
                        itemsMap['title']?.toString() ?? 'Product Delivery',
                        '#${o.id.substring(0, 8).toUpperCase()}',
                        o.status.replaceAll('_', ' ').toUpperCase(),
                        itemsMap['description']?.toString() ?? 'See details for more info',
                        o.eta.isNotEmpty ? o.eta : 'Calculating ETA...',
                        progress,
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
                      ? _buildAddButton(context, 'Log First Service', () => _showLogServiceDialog(context, ref, uid, vehicles.first.id))
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
                  child: _buildHistoryItem(context, ref, uid, item),
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

  Widget _buildVehicleCard(BuildContext context, WidgetRef ref, Vehicle vehicle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vehicle.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black.withOpacity(0.05), // Darker background to handle transparent PNGs better
                  child: Image.network(
                    vehicle.imageUrls.first,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.contain, // Contain ensures the car isn't cropped awkwardly and shows transparency
                    errorBuilder: (_, _, _) => Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.black.withOpacity(0.02),
                      child: Icon(Icons.directions_car, color: Colors.white.withOpacity(0.05), size: 40),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (vehicle.healthStatus == 'Healthy' ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vehicle.healthStatus.toUpperCase(),
                    style: TextStyle(color: vehicle.healthStatus == 'Healthy' ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  vehicle.plateNumber,
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.speed, color: Colors.white24, size: 14),
              const SizedBox(width: 4),
              Text('${vehicle.mileage} KM', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _deleteVehicle(context, ref, vehicle),
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    tooltip: 'Delete Vehicle',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.05),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showAddVehicleDialog(context, ref, vehicle.ownerId, vehicle: vehicle),
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueAccent),
                    tooltip: 'Edit Vehicle',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.05),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: TextButton.icon(
                  onPressed: () => _showVehicleDetails(context, ref, vehicle),
                  icon: const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white38),
                  label: const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildOrderCard(String title, String id, String status, String description, String eta, double progress) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: BoostDriveTheme.primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: BoostDriveTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(id, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(description, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16)),
          const SizedBox(height: 32),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: const AlwaysStoppedAnimation(BoostDriveTheme.primaryColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(eta, style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, WidgetRef ref, String uid, ServiceRecord item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: BoostDriveTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.build_outlined, color: BoostDriveTheme.primaryColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.serviceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      '${item.completedAt.day}/${item.completedAt.month}/${item.completedAt.year}${item.mileageAtService != null ? ' @ ${item.mileageAtService} KM' : ''}',
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text('N\$ ${item.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        debugPrint('DEBUG: Delete button pressed for record ${item.id}');
                        _deleteServiceRecord(context, ref, uid, item);
                      },
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      tooltip: 'Delete Record',
                    ),
                    IconButton(
                      onPressed: () {
                        debugPrint('DEBUG: Edit button pressed for record ${item.id}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening edit dialog for ${item.serviceName}...'), duration: const Duration(milliseconds: 500))
                        );
                        _showLogServiceDialog(context, ref, uid, item.vehicleId, record: item);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueAccent),
                      tooltip: 'Edit Record',
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        debugPrint('DEBUG: Details button pressed for record ${item.id}');
                        _showServiceRecordDetails(context, item);
                      },
                      icon: const Icon(Icons.summarize_outlined, size: 14),
                      label: const Text('Details', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (item.receiptUrls.isNotEmpty)
                Builder(
                  builder: (context) => TextButton.icon(
                    onPressed: () => _viewReceipts(context, item.receiptUrls),
                    icon: const Icon(Icons.receipt_long, size: 14),
                    label: Text(item.receiptUrls.length > 1 ? 'Proofs' : 'Proof', style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: BoostDriveTheme.primaryColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewReceipts(BuildContext context, List<String> urls) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 600, maxWidth: 800),
                  child: ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: urls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(urls[index], fit: BoxFit.contain),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewReceipt(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(url, fit: BoxFit.contain),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleDetails(BuildContext context, WidgetRef ref, Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BoostDriveTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${vehicle.year} ${vehicle.make} ${vehicle.model}', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text(vehicle.plateNumber, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16)),
              const SizedBox(height: 24),
              if (vehicle.imageUrls.isNotEmpty)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: vehicle.imageUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _viewReceipt(context, vehicle.imageUrls[index]), // Reuse viewReceipt for full screen image
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(vehicle.imageUrls[index], width: 300, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              
              _buildDetailCategory(Icons.speed, 'MECHANICAL HEALTH & STATUS', [
                _buildInfoRow('Current Meter Reading', '${vehicle.mileage} KM'),
                _buildInfoRow('Next Service Due', vehicle.nextServiceDueMileage != null ? '${vehicle.nextServiceDueMileage} KM' : 'Not Set'),
                _buildInfoRow('Tire Condition', vehicle.tireHealth),
                _buildInfoRow('Oil Life', vehicle.oilLife ?? 'Not Logged'),
                _buildInfoRow('Brake Fluid Status', vehicle.brakeFluidStatus ?? 'Healthy'),
                _buildInfoRow('Active Faults', vehicle.activeFaults ?? 'None Identified'),
              ]),
              
              _buildDetailCategory(Icons.description, 'DOCUMENTATION & HISTORY', [
                _buildInfoRow('VIN', vehicle.vin ?? 'Not Provided'),
                _buildInfoRow('Service History', vehicle.serviceHistoryType),
                _buildInfoRow('License Renewal', vehicle.nextLicenseRenewal != null ? '${vehicle.nextLicenseRenewal!.day}/${vehicle.nextLicenseRenewal!.month}/${vehicle.nextLicenseRenewal!.year}' : 'Not Set'),
                _buildInfoRow('Insurance Expiry', vehicle.insuranceExpiry != null ? '${vehicle.insuranceExpiry!.day}/${vehicle.insuranceExpiry!.month}/${vehicle.insuranceExpiry!.year}' : 'Not Logged'),
                _buildInfoRow('Warranty Expiry', vehicle.warrantyExpiry != null ? '${vehicle.warrantyExpiry!.day}/${vehicle.warrantyExpiry!.month}/${vehicle.warrantyExpiry!.year}' : 'N/A'),
                _buildInfoRow('Spare Key', vehicle.spareKey ? 'Yes' : 'No'),
              ]),

              _buildDetailCategory(Icons.style, 'USAGE & FEATURES', [
                _buildInfoRow('Fuel Efficiency', vehicle.fuelEfficiency ?? 'Not Logged'),
                _buildInfoRow('Make & Model', '${vehicle.year} ${vehicle.make} ${vehicle.model}'),
                _buildInfoRow('Transmission', vehicle.transmission),
                _buildInfoRow('Fuel Type', vehicle.fuelType),
                _buildInfoRow('Drive Type', vehicle.driveType),
                _buildInfoRow('Engine Capacity', vehicle.engineCapacity ?? 'Not Specified'),
                _buildInfoRow('Exterior Condition', vehicle.exteriorCondition ?? 'Good'),
                _buildInfoRow('Interior Material', vehicle.interiorMaterial),
                _buildInfoRow('Towing Capacity', vehicle.towingCapacity ?? 'None'),
                _buildInfoRow('Safety Rating / Tech', vehicle.safetyTech ?? 'Standard'),
              ]),

              if (vehicle.description != null && vehicle.description!.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildFormHeader('OWNER DESCRIPTION'),
                const SizedBox(height: 12),
                Text(vehicle.description!, style: const TextStyle(color: Colors.white70, height: 1.5)),
              ],
              
              if (vehicle.modifications != null && vehicle.modifications!.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildFormHeader('MODIFICATIONS & EXTRAS'),
                const SizedBox(height: 12),
                Text(vehicle.modifications!, style: const TextStyle(color: Colors.white70)),
              ],

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogServiceDialog(context, ref, vehicle.ownerId, vehicle.id),
                  icon: const Icon(Icons.history_edu),
                  label: const Text('Update Digital Logbook'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoostDriveTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCategory(IconData icon, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            Icon(icon, color: BoostDriveTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: BoostDriveTheme.primaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, Map<String, String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...details.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key, style: const TextStyle(color: Colors.white38, fontSize: 13)),
              Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        )),
      ],
    );
  }

  void _deleteVehicle(BuildContext context, WidgetRef ref, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Delete Vehicle', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete ${vehicle.year} ${vehicle.make} ${vehicle.model}? This action cannot be undone.', 
          style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(vehicleServiceProvider).deleteVehicle(vehicle.id);
              if (context.mounted) {
                Navigator.pop(context);
                ref.read(dashboardRefreshProvider.notifier).update((state) => state + 1);
                ref.invalidate(userVehiclesProvider(vehicle.ownerId));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteServiceRecord(BuildContext context, WidgetRef ref, String uid, ServiceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Delete Service Record', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete the record for "${record.serviceName}"? This action cannot be undone.', 
          style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                debugPrint('DEBUG: Deleting service record ${record.id}');
                await ref.read(serviceRecordServiceProvider).deleteServiceRecord(record.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.read(dashboardRefreshProvider.notifier).update((state) => state + 1);
                  ref.invalidate(vehicleHistoryProvider(record.vehicleId));
                  ref.invalidate(userServiceHistoryProvider(uid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service record deleted successfully'))
                  );
                }
              } catch (e) {
                debugPrint('DEBUG: Error deleting service record: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showServiceRecordDetails(BuildContext context, ServiceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: Text(record.serviceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Cost', 'N\$ ${record.price.toStringAsFixed(2)}'),
                _buildInfoRow('Date', '${record.completedAt.day}/${record.completedAt.month}/${record.completedAt.year}'),
                if (record.mileageAtService != null)
                  _buildInfoRow('Mileage', '${record.mileageAtService} KM'),
                const SizedBox(height: 24),
                if (record.receiptUrls.isNotEmpty) ...[
                  const Text('RECEIPTS / PROOFS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: record.receiptUrls.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => _viewReceipt(context, record.receiptUrls[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(record.receiptUrls[index], height: 200, width: 200, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.05),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white10),
        ),
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context, WidgetRef ref, String uid, {Vehicle? vehicle}) {
    final makeController = TextEditingController(text: vehicle?.make);
    final modelController = TextEditingController(text: vehicle?.model);
    final yearController = TextEditingController(text: vehicle?.year.toString() ?? '2024');
    final plateController = TextEditingController(text: vehicle?.plateNumber);
    final mileageController = TextEditingController(text: vehicle?.mileage.toString());
    final capacityController = TextEditingController(text: vehicle?.engineCapacity);
    final descriptionController = TextEditingController(text: vehicle?.description);
    final modificationController = TextEditingController(text: vehicle?.modifications);
    final safetyController = TextEditingController(text: vehicle?.safetyTech);
    final towingController = TextEditingController(text: vehicle?.towingCapacity);
    
    // V3 Controllers
    final nextServiceController = TextEditingController(text: vehicle?.nextServiceDueMileage?.toString());
    final oilLifeController = TextEditingController(text: vehicle?.oilLife);
    final brakeFluidController = TextEditingController(text: vehicle?.brakeFluidStatus);
    final activeFaultsController = TextEditingController(text: vehicle?.activeFaults);
    final vinController = TextEditingController(text: vehicle?.vin);
    final efficiencyController = TextEditingController(text: vehicle?.fuelEfficiency);
    final exteriorController = TextEditingController(text: vehicle?.exteriorCondition);

    String tireHealth = vehicle?.tireHealth ?? 'Brand New';
    String serviceHistory = vehicle?.serviceHistoryType ?? 'Full Service History (FSH)';
    String transmission = vehicle?.transmission ?? 'Automatic';
    String fuelType = vehicle?.fuelType ?? 'Petrol';
    String driveType = vehicle?.driveType ?? '4x2';
    String accidentHistory = vehicle?.accidentHistory ?? 'No';
    bool spareKey = vehicle?.spareKey ?? false;
    String interiorMaterial = vehicle?.interiorMaterial ?? 'Cloth';
    DateTime? licenseRenewal = vehicle?.nextLicenseRenewal;
    DateTime? insuranceExpiry = vehicle?.insuranceExpiry;
    DateTime? warrantyExpiry = vehicle?.warrantyExpiry;

    final imagePicker = image_picker.ImagePicker();
    List<image_picker.XFile> selectedImages = [];
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: BoostDriveTheme.surfaceDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: Row(
            children: [
              Icon(vehicle == null ? Icons.add_road : Icons.edit_road, color: BoostDriveTheme.primaryColor),
              const SizedBox(width: 12),
              Text(vehicle == null ? 'Add Vehicle to Garage' : 'Edit Vehicle Details', 
                style: GoogleFonts.manrope(fontWeight: FontWeight.w900, color: Colors.white)),
              if (isSaving) ...[
                const SizedBox(width: 16),
                const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: BoostDriveTheme.primaryColor)),
              ],
            ],
          ),
          scrollable: false,
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual Section
                  _buildFormHeader('VEHICLE PHOTO'),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        if (selectedImages.isNotEmpty || (vehicle?.imageUrls.isNotEmpty ?? false))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SizedBox(
                              height: 120,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  if (vehicle != null)
                                    ...vehicle.imageUrls.map((url) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(url, height: 120, width: 120, fit: BoxFit.cover),
                                      ),
                                    )),
                                  ...selectedImages.asMap().entries.map((entry) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(entry.value.path, height: 120, width: 120, fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => setDialogState(() => selectedImages.removeAt(entry.key)),
                                            child: CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.black54,
                                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final imgs = await imagePicker.pickMultiImage();
                            if (imgs.isNotEmpty) setDialogState(() => selectedImages.addAll(imgs));
                          },
                          icon: Icon(selectedImages.isEmpty ? Icons.add_a_photo : Icons.add_photo_alternate, size: 18),
                          label: Text(selectedImages.isEmpty ? 'Upload New Photos' : 'Add More Photos'),
                          style: _dialogButtonStyle(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Basic Info
                  _buildFormHeader('BASIC INFORMATION'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(makeController, 'Make (e.g. Toyota)', Icons.branding_watermark)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(modelController, 'Model (e.g. Hilux)', Icons.car_rental)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(yearController, 'Year', Icons.calendar_today)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(plateController, 'Plate Number', Icons.credit_card)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Mechanical Health & Status
                  _buildFormHeader('MECHANICAL HEALTH & STATUS'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(mileageController, 'Current Meter Reading (KM)', Icons.speed)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(nextServiceController, 'Next Service Due (KM)', Icons.event_repeat)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Tire Condition',
                    tireHealth,
                    ['Brand New', 'Good', 'Fair', 'Needs Replacement'],
                    (v) => setDialogState(() => tireHealth = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(oilLifeController, 'Oil Life (e.g. 80%)', Icons.oil_barrel)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(brakeFluidController, 'Brake Fluid Status', Icons.water_drop)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(activeFaultsController, 'Active Faults (Log any known issues)', Icons.error_outline, maxLines: 2),
                  const SizedBox(height: 32),

                  // Documentation & History
                  _buildFormHeader('DOCUMENTATION & HISTORY'),
                  const SizedBox(height: 12),
                  _buildTextField(vinController, 'VIN (17-character Identifier)', Icons.fingerprint),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Service History',
                    serviceHistory,
                    ['Full Service History (FSH)', 'Partial', 'None'],
                    (v) => setDialogState(() => serviceHistory = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePickerTile(
                          context,
                          'License Renewal',
                          licenseRenewal,
                          (d) => setDialogState(() => licenseRenewal = d),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                         child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Spare Key', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          value: spareKey,
                          onChanged: (v) => setDialogState(() => spareKey = v),
                          activeThumbColor: BoostDriveTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Accident History',
                    accidentHistory,
                    ['No', 'Minor', 'Major (Repaired)', 'Write-off'],
                    (v) => setDialogState(() => accidentHistory = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePickerTile(
                          context,
                          'Insurance Expiry',
                          insuranceExpiry,
                          (d) => setDialogState(() => insuranceExpiry = d),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePickerTile(
                          context,
                          'Warranty Expiry',
                          warrantyExpiry,
                          (d) => setDialogState(() => warrantyExpiry = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Usage & Features
                  _buildFormHeader('USAGE & FEATURES (LISTING ENHANCEMENTS)'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(efficiencyController, 'Fuel Efficiency (L/100km)', Icons.eco)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(capacityController, 'Engine Capacity', Icons.settings_input_component)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Transmission',
                          transmission,
                          ['Manual', 'Automatic'],
                          (v) => setDialogState(() => transmission = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          'Fuel Type',
                          fuelType,
                          ['Diesel', 'Petrol', 'Hybrid', 'Electric'],
                          (v) => setDialogState(() => fuelType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Drive Type',
                    driveType,
                    ['4x2', '4x2 (Raised Body)', '4x4'],
                    (v) => setDialogState(() => driveType = v!),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(modificationController, 'Vehicle Modifications', Icons.build_circle, maxLines: 2),
                  const SizedBox(height: 16),
                  _buildTextField(exteriorController, 'Exterior Condition (Dents/Scratches)', Icons.edit_note, maxLines: 2),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Interior Material',
                          interiorMaterial,
                          ['Cloth', 'Leatherette', 'Leather', 'Canvas'],
                          (v) => setDialogState(() => interiorMaterial = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(towingController, 'Tow Bar / Towing Capacity', Icons.anchor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(safetyController, 'Safety Rating / Driver Assist Tech', Icons.security),
                  const SizedBox(height: 16),
                  _buildTextField(descriptionController, 'General Owner Description', Icons.description, maxLines: 3),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: BoostDriveTheme.textDim)),
            ),
            SizedBox(
              height: 48,
              width: 140,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BoostDriveTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: (selectedImages.isEmpty && (vehicle == null || vehicle.imageUrls.isEmpty)) ? null : () async {
                  try {
                    setDialogState(() => isSaving = true);
                    List<String> imageUrls = vehicle?.imageUrls != null ? List.from(vehicle!.imageUrls) : [];
                    
                    if (selectedImages.isNotEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Row(children: [CircularProgressIndicator(strokeWidth: 2), SizedBox(width: 12), Text('Uploading new photos...')]))
                        );
                      }

                      for (var img in selectedImages) {
                        final bytes = await img.readAsBytes();
                        final url = await ref.read(vehicleServiceProvider).uploadVehicleImage(uid, bytes, img.name);
                        if (url != null) imageUrls.add(url);
                      }
                    }

                    final updatedVehicle = Vehicle(
                      id: vehicle?.id ?? '',
                      ownerId: uid,
                      make: makeController.text,
                      model: modelController.text,
                      year: int.tryParse(yearController.text) ?? 2024,
                      plateNumber: plateController.text,
                      mileage: int.tryParse(mileageController.text) ?? 0,
                      tireHealth: tireHealth,
                      serviceHistoryType: serviceHistory,
                      transmission: transmission,
                      fuelType: fuelType,
                      driveType: driveType,
                      engineCapacity: capacityController.text,
                      nextLicenseRenewal: licenseRenewal,
                      accidentHistory: accidentHistory,
                      modifications: modificationController.text,
                      spareKey: spareKey,
                      interiorMaterial: interiorMaterial,
                      safetyTech: safetyController.text,
                      towingCapacity: towingController.text,
                      description: descriptionController.text,
                      imageUrls: imageUrls,
                      createdAt: vehicle?.createdAt ?? DateTime.now(),
                      nextServiceDueMileage: int.tryParse(nextServiceController.text),
                      oilLife: oilLifeController.text,
                      brakeFluidStatus: brakeFluidController.text,
                      activeFaults: activeFaultsController.text,
                      vin: vinController.text,
                      insuranceExpiry: insuranceExpiry,
                      warrantyExpiry: warrantyExpiry,
                      fuelEfficiency: efficiencyController.text,
                      exteriorCondition: exteriorController.text,
                    );

                    if (vehicle == null) {
                      await ref.read(vehicleServiceProvider).addVehicle(updatedVehicle);
                    } else {
                      await ref.read(vehicleServiceProvider).updateVehicle(updatedVehicle);
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vehicle == null ? 'Vehicle added successfully!' : 'Vehicle updated successfully!')));
                      Navigator.pop(context);
                      ref.read(dashboardRefreshProvider.notifier).update((state) => state + 1);
                      ref.invalidate(userVehiclesProvider(uid)); 
                    }
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving vehicle: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: Text(isSaving ? 'Saving...' : 'Save Vehicle', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: BoostDriveTheme.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white24, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: BoostDriveTheme.surfaceDark,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerTile(BuildContext context, String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
            );
            if (date != null) onDateSelected(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate == null ? 'Select Date' : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.white24, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ButtonStyle _dialogButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.05),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
    );
  }

  void _showLogServiceDialog(BuildContext context, WidgetRef ref, String uid, String vehicleId, {ServiceRecord? record}) {
    debugPrint('DEBUG: _showLogServiceDialog called. Record: ${record?.id}, vehicleId: $vehicleId');
    final serviceController = TextEditingController(text: record?.serviceName);
    final priceController = TextEditingController(text: record?.price.toString());
    final mileageController = TextEditingController(text: record?.mileageAtService?.toString());
    final imagePicker = image_picker.ImagePicker();
    List<image_picker.XFile> selectedReceipts = [];
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: BoostDriveTheme.surfaceDark,
          title: Row(
            children: [
              Flexible(child: Text(record == null ? 'Log Service Record' : 'Edit Service Record', overflow: TextOverflow.ellipsis)),
              if (isSaving) ...[
                const SizedBox(width: 16),
                const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: BoostDriveTheme.primaryColor)),
              ],
            ],
          ),
          scrollable: false,
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(serviceController, 'Service Name (e.g. Oil Change)', Icons.handyman),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(priceController, 'Cost (N\$)', Icons.payments)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(mileageController, 'Mileage (KM)', Icons.speed)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildFormHeader('SERVICE RECEIPTS / INVOICES (MULTIPLES)'),
                  const SizedBox(height: 12),
                  if (selectedReceipts.isNotEmpty || (record?.receiptUrls.isNotEmpty ?? false))
                    Container(
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (record != null)
                            ...record.receiptUrls.map((url) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(url, width: 120, height: 120, fit: BoxFit.cover, 
                                  errorBuilder: (_, _, _) => Container(width: 120, height: 120, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24))),
                              ),
                            )),
                          ...selectedReceipts.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(entry.value.path, width: 120, height: 120, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setDialogState(() => selectedReceipts.removeAt(entry.key)),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final imgs = await imagePicker.pickMultiImage();
                        if (imgs.isNotEmpty) setDialogState(() => selectedReceipts.addAll(imgs));
                      },
                      icon: Icon(selectedReceipts.isEmpty ? Icons.receipt_long : Icons.add_photo_alternate, size: 18),
                      label: Text(selectedReceipts.isEmpty ? 'Upload New Receipts' : 'Add More Receipts'),
                      style: _dialogButtonStyle(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: BoostDriveTheme.textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
              onPressed: isSaving ? null : () async {
                try {
                  setDialogState(() => isSaving = true);
                  List<String> imageUrls = record?.receiptUrls != null ? List.from(record!.receiptUrls) : [];
                  
                  if (selectedReceipts.isNotEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Uploading new receipts...'), duration: Duration(seconds: 2))
                      );
                    }

                    for (var img in selectedReceipts) {
                      final bytes = await img.readAsBytes();
                      final url = await ref.read(serviceRecordServiceProvider).uploadServiceReceipt(vehicleId, bytes, img.name);
                      if (url != null) imageUrls.add(url);
                    }
                  }

                  final updatedRecord = ServiceRecord(
                    id: record?.id ?? '',
                    vehicleId: vehicleId,
                    providerId: uid, 
                    serviceName: serviceController.text,
                    price: double.tryParse(priceController.text) ?? 0.0,
                    completedAt: record?.completedAt ?? DateTime.now(),
                    receiptUrls: imageUrls,
                    mileageAtService: int.tryParse(mileageController.text),
                  );
                  
                  if (record == null) {
                    await ref.read(serviceRecordServiceProvider).addServiceRecord(updatedRecord);
                  } else {
                    await ref.read(serviceRecordServiceProvider).updateServiceRecord(updatedRecord);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(record == null ? 'Service record saved to your Digital Logbook!' : 'Service record updated!'))
                    );
                    Navigator.pop(context);
                    ref.read(dashboardRefreshProvider.notifier).update((state) => state + 1);
                    ref.invalidate(vehicleHistoryProvider(vehicleId));
                    ref.invalidate(userServiceHistoryProvider(uid));
                  }
                } catch (e) {
                  setDialogState(() => isSaving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red)
                    );
                  }
                }
              },
              child: Text(isSaving ? 'Saving...' : 'Save to Logbook'),
            ),
          ],
        ),
      ),
    );
  }
}
