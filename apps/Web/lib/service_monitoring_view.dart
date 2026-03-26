import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
        const Text(
          'Live Service Monitoring',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 24),
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
        color: const Color(0xFFF8F9FA),
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
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
                // Future: Dispatcher controls
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
          SizedBox(width: 60, child: Text('$label:', style: const TextStyle(fontSize: 11, color: Colors.black54))),
          Expanded(child: Text(value.isEmpty ? 'N/A' : value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.red;
      case 'accepted':
      case 'assigned': return Colors.orange;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
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
}
