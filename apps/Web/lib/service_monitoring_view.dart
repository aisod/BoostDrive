import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';

class ServiceMonitoringView extends ConsumerStatefulWidget {
  const ServiceMonitoringView({super.key});

  @override
  ConsumerState<ServiceMonitoringView> createState() => _ServiceMonitoringViewState();
}

class _ServiceMonitoringViewState extends ConsumerState<ServiceMonitoringView> {
  GoogleMapController? _mapController;
  SosRequest? _selectedRequest;
  
  // Default map position (Windhoek, Namibia)
  static const _defaultPos = CameraPosition(
    target: LatLng(-22.5609, 17.0658),
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(globalActiveSosRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 0),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map View
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: requestsAsync.when(
                    data: (requests) => _buildMap(requests),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error loading map: $err')),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Side List
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: requestsAsync.when(
                    data: (requests) => _buildRequestList(requests),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMap(List<SosRequest> requests) {
    final markers = requests.map((r) {
      return Marker(
        markerId: MarkerId(r.id),
        position: LatLng(r.lat, r.lng),
        infoWindow: InfoWindow(
          title: r.type.toUpperCase(),
          snippet: 'Status: ${r.status}',
        ),
        onTap: () => setState(() => _selectedRequest = r),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          r.status == 'pending' ? BitmapDescriptor.hueRed : BitmapDescriptor.hueYellow,
        ),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: _defaultPos,
      markers: markers,
      onMapCreated: (controller) => _mapController = controller,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
    );
  }

  Widget _buildRequestList(List<SosRequest> requests) {
    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
            SizedBox(height: 16),
            Text('No active SOS requests', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Active Requests (${requests.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: requests.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = requests[index];
              final isSelected = _selectedRequest?.id == r.id;
              
              return ListTile(
                selected: isSelected,
                selectedTileColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.05),
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(r.status).withValues(alpha: 0.1),
                  child: Icon(_getTypeIcon(r.type), color: _getStatusColor(r.status), size: 18),
                ),
                title: Text(r.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Status: ${r.status}', style: const TextStyle(fontSize: 11)),
                onTap: () {
                  setState(() => _selectedRequest = r);
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(LatLng(r.lat, r.lng), 15),
                  );
                },
              );
            },
          ),
        ),
        if (_selectedRequest != null) _buildSelectedDetails(),
      ],
    );
  }

  Widget _buildSelectedDetails() {
    final r = _selectedRequest!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.12))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() => _selectedRequest = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _detailRow('ID', r.id),
          _detailRow('Status', r.status.toUpperCase()),
          _detailRow('Note', r.userNote),
          _detailRow('Created', _formatDate(r.createdAt)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                  _openDispatchDetailsDialog(r);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BoostDriveTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('View Dispatch Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 60, child: Text('$label:', style: const TextStyle(fontSize: 11, color: Colors.black87))),
          Expanded(child: Text(value.isEmpty ? 'N/A' : value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.red;
      case 'accepted':
      case 'assigned': return Colors.orange;
      case 'active': return BoostDriveTheme.primaryColor;
      case 'resolved': return Colors.green;
      default: return Colors.black54;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'towing': return Icons.local_shipping;
      case 'mechanic': return Icons.build;
      case 'fuel': return Icons.local_gas_station;
      case 'battery': return Icons.battery_charging_full;
      default: return Icons.warning;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}';
  }

  Future<void> _openDispatchDetailsDialog(SosRequest r) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          scrollable: true,
          title: const Text(
            'Dispatch Details',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900),
          ),
          content: SizedBox(
            width: 560,
            child: FutureBuilder<_DispatchContextData>(
              future: _loadDispatchContext(r),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final data = snap.data ?? _DispatchContextData.empty();
                final level = _emergencyLevel(r);
                final levelColor = _emergencyLevelColor(level);
                final canDirectAssign = r.status.toLowerCase() == 'pending' && data.nearbyProviders.isNotEmpty;
                final maxDialogContentHeight = MediaQuery.of(context).size.height * 0.72;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxDialogContentHeight < 320 ? 320 : maxDialogContentHeight,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: levelColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: levelColor.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                'EMERGENCY: $level',
                                style: TextStyle(color: levelColor, fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Broadcasted: ${_broadcastAge(r.createdAt)}',
                              style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Requesting Customer/Seller',
                            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
                        const SizedBox(height: 6),
                        _detailRow('Name', data.customerName),
                        _detailRow('Role', data.customerRole),
                        _detailRow('Phone', data.customerPhone),
                        const SizedBox(height: 10),
                        const Text('Accepted Provider',
                            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
                        const SizedBox(height: 6),
                        _detailRow('Name', data.acceptedProviderName),
                        _detailRow('Role', data.acceptedProviderRole),
                        _detailRow('Phone', data.acceptedProviderPhone),
                        const SizedBox(height: 10),
                        const Text('Dispatch',
                            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
                        const SizedBox(height: 6),
                        _detailRow('Status', r.status.toUpperCase()),
                        _detailRow('Type', r.type.toUpperCase()),
                        _detailRow('Wait Time', _broadcastAge(r.createdAt)),
                        _detailRow('Nearby', '${data.nearbyProviders.length} providers (10 km)'),
                        _detailRow('Created', _formatDate(r.createdAt)),
                        _detailRow('Coords', '${r.lat.toStringAsFixed(6)}, ${r.lng.toStringAsFixed(6)}'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: canDirectAssign
                                ? () async {
                                    await _openDirectAssignDialog(r, data.nearbyProviders);
                                    if (mounted) Navigator.of(ctx).pop();
                                  }
                                : null,
                            icon: const Icon(Icons.person_add_alt_1),
                            style: FilledButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
                            label: Text(canDirectAssign ? 'DIRECT ASSIGN TO PROVIDER' : 'DIRECT ASSIGN (UNAVAILABLE)'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('CLOSE'),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(LatLng(r.lat, r.lng), 15),
                                );
                              },
                              child: const Text('CENTER ON MAP'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                final uri = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=${r.lat.toStringAsFixed(6)},${r.lng.toStringAsFixed(6)}',
                                );
                                final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
                                if (!ok && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open external map.')),
                                  );
                                }
                              },
                              style: FilledButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
                              child: const Text('OPEN IN MAPS'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<_DispatchContextData> _loadDispatchContext(SosRequest r) async {
    try {
      final profile = await ref.read(userProfileProvider(r.userId).future);
      final acceptedProviderProfile = (r.assignedProviderId != null && r.assignedProviderId!.trim().isNotEmpty)
          ? await ref.read(userProfileProvider(r.assignedProviderId!.trim()).future)
          : null;
      final vehicles = await ref.read(vehicleServiceProvider).getUserVehicles(r.userId).first;
      final vehicle = (r.vehicleId != null && r.vehicleId!.trim().isNotEmpty)
          ? vehicles.where((v) => v.id == r.vehicleId).cast<Vehicle?>().firstWhere((_) => true, orElse: () => null)
          : (vehicles.isNotEmpty ? vehicles.first : null);
      final nearby = await ref.read(userServiceProvider).getNearbyVerifiedProviders(
            customerLat: r.lat,
            customerLng: r.lng,
            serviceType: r.type,
          );

      // Pull full SOS row to read optional telemetry-like fields if present.
      final row = await Supabase.instance.client
          .from('sos_requests')
          .select()
          .eq('id', r.id)
          .maybeSingle();
      final battery = row?['battery_level']?.toString();
      final signal = row?['signal_level']?.toString() ?? row?['network_signal']?.toString();
      final landmark = row?['landmark']?.toString();

      final color = vehicle?.exteriorCondition?.trim().isNotEmpty == true
          ? vehicle!.exteriorCondition!.trim()
          : 'Not available';
      return _DispatchContextData(
        customerName: (profile?.fullName.trim().isNotEmpty == true) ? profile!.fullName : 'Unknown customer',
        customerRole: (profile?.role.trim().isNotEmpty == true) ? profile!.role : 'customer/seller',
        customerPhone: (profile?.phoneNumber.trim().isNotEmpty == true) ? profile!.phoneNumber! : 'Not available',
        acceptedProviderName: (acceptedProviderProfile?.fullName.trim().isNotEmpty == true)
            ? acceptedProviderProfile!.fullName
            : ((r.assignedProviderId?.trim().isNotEmpty ?? false) ? 'Assigned provider' : 'Not assigned yet'),
        acceptedProviderRole: (acceptedProviderProfile?.role.trim().isNotEmpty == true)
            ? acceptedProviderProfile!.role
            : ((r.assignedProviderId?.trim().isNotEmpty ?? false) ? 'service provider' : 'n/a'),
        acceptedProviderPhone: (acceptedProviderProfile?.phoneNumber.trim().isNotEmpty == true)
            ? acceptedProviderProfile!.phoneNumber!
            : ((r.assignedProviderId?.trim().isNotEmpty ?? false) ? 'Not available' : 'Not assigned yet'),
        vehicle: vehicle,
        vehicleColor: color,
        nearbyProviders: nearby,
        batteryLevel: (battery?.trim().isNotEmpty == true) ? battery!.trim() : 'Not captured',
        signalLevel: (signal?.trim().isNotEmpty == true) ? signal!.trim() : 'Not captured',
        landmark: (landmark?.trim().isNotEmpty == true) ? landmark!.trim() : 'Near request coordinates',
      );
    } catch (_) {
      return _DispatchContextData.empty();
    }
  }

  Future<void> _openDirectAssignDialog(SosRequest r, List<UserProfile> providers) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Direct Assign'),
          content: SizedBox(
            width: 420,
            child: providers.isEmpty
                ? const Text('No nearby providers available.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: providers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = providers[i];
                      final name = p.tradingName?.trim().isNotEmpty == true
                          ? p.tradingName!
                          : (p.fullName.isNotEmpty ? p.fullName : 'Provider');
                      return ListTile(
                        title: Text(name),
                        subtitle: Text(p.phoneNumber?.isNotEmpty == true ? p.phoneNumber! : 'No phone'),
                        trailing: FilledButton(
                          onPressed: () async {
                            try {
                              await ref.read(sosServiceProvider).acceptRequest(r.id, p.uid);
                              if (!mounted) return;
                              setState(() => _selectedRequest = r.copyWith(status: 'assigned', assignedProviderId: p.uid));
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Assigned to $name')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not assign: $e')),
                              );
                            }
                          },
                          child: const Text('Assign'),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('CLOSE')),
          ],
        );
      },
    );
  }

  String _emergencyLevel(SosRequest r) {
    final t = r.type.toLowerCase();
    if (t.contains('accident') || t.contains('medical') || t.contains('fire')) return 'CRITICAL';
    if (t.contains('lock') || t.contains('battery') || t.contains('towing')) return 'MEDIUM';
    return 'LOW';
  }

  Color _emergencyLevelColor(String level) {
    switch (level) {
      case 'CRITICAL':
        return Colors.redAccent;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _broadcastAge(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    final m = diff.inMinutes;
    final s = diff.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _DispatchContextData {
  const _DispatchContextData({
    required this.customerName,
    required this.customerRole,
    required this.customerPhone,
    required this.acceptedProviderName,
    required this.acceptedProviderRole,
    required this.acceptedProviderPhone,
    required this.vehicle,
    required this.vehicleColor,
    required this.nearbyProviders,
    required this.batteryLevel,
    required this.signalLevel,
    required this.landmark,
  });

  final String customerName;
  final String customerRole;
  final String customerPhone;
  final String acceptedProviderName;
  final String acceptedProviderRole;
  final String acceptedProviderPhone;
  final Vehicle? vehicle;
  final String vehicleColor;
  final List<UserProfile> nearbyProviders;
  final String batteryLevel;
  final String signalLevel;
  final String landmark;

  factory _DispatchContextData.empty() => const _DispatchContextData(
        customerName: 'Unknown customer',
        customerRole: 'customer/seller',
        customerPhone: 'Not available',
        acceptedProviderName: 'Not assigned yet',
        acceptedProviderRole: 'n/a',
        acceptedProviderPhone: 'Not assigned yet',
        vehicle: null,
        vehicleColor: 'Not available',
        nearbyProviders: <UserProfile>[],
        batteryLevel: 'Not captured',
        signalLevel: 'Not captured',
        landmark: 'Near request coordinates',
      );
}
