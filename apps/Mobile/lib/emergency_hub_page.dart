import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';

class EmergencyHubPage extends ConsumerStatefulWidget {
  const EmergencyHubPage({super.key});

  @override
  ConsumerState<EmergencyHubPage> createState() => _EmergencyHubPageState();
}

class _EmergencyHubPageState extends ConsumerState<EmergencyHubPage> {
  bool _isRequesting = false;
  // ignore: unused_field - tracks active SOS request for cancel/status
  String? _activeRequestId;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final sosService = ref.read(sosServiceProvider);
    final pos = await sosService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentPosition = pos;
      });
    }
  }

  Future<void> _handleEmergencyRequest(String serviceType) async {
    setState(() => _isRequesting = true);
    
    try {
      final sosService = ref.read(sosServiceProvider);
      final user = ref.read(authStateProvider).value?.session?.user;
      
      if (user == null) {
        throw 'You must be logged in to request assistance';
      }

      final pos = _currentPosition ?? await sosService.getCurrentLocation();
      if (pos == null) {
        throw 'Could not determine your location. Please check GPS settings.';
      }

      final requestId = await sosService.recordSosRequest(
        userId: user.id,
        position: pos,
        type: serviceType, // e.g., 'towing' or 'mechanic'
        userNote: 'Stranded motorist requesting $serviceType assistance.',
      );

      if (requestId != null) {
        setState(() => _activeRequestId = requestId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request for $serviceType sent! Finding nearest provider...'),
              backgroundColor: Colors.green,
            ),
          );
          // Auto-trigger SMS fallback for demo
          await sosService.sendEmergencySms(pos);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value?.session?.user;
    final activeRequests = user != null
        ? ref.watch(userActiveSosRequestsProvider(user.id)).valueOrNull ?? []
        : <Map<String, dynamic>>[];
    final hasActiveRequest = activeRequests.isNotEmpty;
    final activeRequest = hasActiveRequest ? activeRequests.first : null;
    final assignedProviderId = activeRequest?['assigned_provider_id'] as String?;

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('EMERGENCY ASSISTANCE'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.emergency_share_rounded, size: 80, color: BoostDriveTheme.primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Stranded? We\'ve got you covered.',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Select the type of assistance you need. We will match you with the nearest verified provider immediately.',
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (hasActiveRequest && activeRequest != null) ...[
              _ActiveRequestCard(
                request: activeRequest,
                assignedProviderId: assignedProviderId,
                onCancel: () async {
                  final id = activeRequest['id'] as String?;
                  if (id != null) {
                    await ref.read(sosServiceProvider).cancelRequest(id);
                    if (mounted) setState(() => _activeRequestId = null);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
            _buildEmergencyCard(
              title: 'Request Towing',
              description: 'Flatbed or wheel-lift towing to the nearest garage.',
              icon: Icons.local_shipping_rounded,
              onTap: () => _handleEmergencyRequest('towing'),
              color: BoostDriveTheme.primaryColor,
            ),
            const SizedBox(height: 20),
            _buildEmergencyCard(
              title: 'Mobile Mechanic',
              description: 'Jump starts, tire changes, or minor repairs on the spot.',
              icon: Icons.home_repair_service_rounded,
              onTap: () => _handleEmergencyRequest('mechanic'),
              color: Colors.blueAccent,
            ),
            if (_isRequesting) ...[
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: BoostDriveTheme.primaryColor),
              const SizedBox(height: 16),
              const Text('Locating providers...', style: TextStyle(color: Colors.white)),
            ],
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: () => ref.read(sosServiceProvider).callEmergencyServices('911'),
              icon: const Icon(Icons.phone_in_talk, color: Colors.red),
              label: const Text('Call Dispatch Directly', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: _isRequesting ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Shows active SOS request status and assigned provider (when set) so the customer knows who is en route.
class _ActiveRequestCard extends ConsumerWidget {
  const _ActiveRequestCard({
    required this.request,
    this.assignedProviderId,
    required this.onCancel,
  });

  final Map<String, dynamic> request;
  final String? assignedProviderId;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = (request['type'] as String?) ?? 'assistance';
    final status = (request['status'] as String?) ?? 'pending';
    final providerProfile = assignedProviderId != null
        ? ref.watch(userProfileProvider(assignedProviderId!)).valueOrNull
        : null;
    final providerName = providerProfile?.fullName ?? 'Provider';
    final providerPhone = providerProfile?.phoneNumber ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BoostDriveTheme.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BoostDriveTheme.primaryColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions, color: BoostDriveTheme.primaryColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active request: ${type.toString().toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: BoostDriveTheme.textDim,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
          if (assignedProviderId != null && providerName.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_pin_circle, color: BoostDriveTheme.primaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$providerName is on the way',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                if (providerPhone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: BoostDriveTheme.primaryColor),
                    onPressed: () => ref.read(sosServiceProvider).callEmergencyServices(providerPhone),
                    tooltip: 'Call provider',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Finding a verified provider...';
      case 'accepted':
      case 'assigned':
        return 'Provider assigned — en route';
      default:
        return status;
    }
  }
}
