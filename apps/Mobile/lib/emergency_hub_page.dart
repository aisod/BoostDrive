import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'boostdrive_google_map_gate.dart';
import 'customer_sos_waiting_map.dart';
import 'messages_page.dart';
import 'emergency_directory_page.dart';

/// Mobile SOS hub: situational context, hold-to-trigger, cancel window, category, active dispatch UI.
class EmergencyHubPage extends ConsumerStatefulWidget {
  const EmergencyHubPage({super.key});

  @override
  ConsumerState<EmergencyHubPage> createState() => _EmergencyHubPageState();
}

class _EmergencyHubPageState extends ConsumerState<EmergencyHubPage> with TickerProviderStateMixin {
  bool _isRequesting = false;
  Position? _currentPosition;
  int _vehicleIndex = 0;
  bool _reviewDialogOpen = false;
  final Set<String> _shownReviewPromptIds = <String>{};

  late final AnimationController _holdController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _holdController.reset();
          _showCancelCountdownThenCategory();
        }
      });
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    // Avoid ref.invalidate / provider lookups during initState (Riverpod + inherited scope).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchLocation();
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final user = ref.read(authStateProvider).value?.session?.user;
    if (user != null) {
      ref.invalidate(userActiveSosRequestsProvider(user.id));
    }
    final pos = await ref.read(sosServiceProvider).getCurrentLocation();
    if (mounted) setState(() => _currentPosition = pos);
  }

  Future<void> _dispatchSos({
    required String serviceType,
    required String emergencyCategory,
    String? vehicleId,
  }) async {
    setState(() => _isRequesting = true);
    try {
      final sosService = ref.read(sosServiceProvider);
      final user = ref.read(authStateProvider).value?.session?.user;
      if (user == null) throw 'You must be logged in to request assistance';

      final pos = _currentPosition ?? await sosService.getCurrentLocation();
      if (pos == null) {
        throw kIsWeb
            ? 'Could not get your location. Allow location for this site (address bar lock icon), use HTTPS or localhost, then tap Retry location.'
            : 'Could not determine your location. Turn on device location and allow BoostDrive to use it, then try again.';
      }

      final requestId = await sosService.recordSosRequest(
        userId: user.id,
        position: pos,
        type: serviceType,
        vehicleId: vehicleId,
        emergencyCategory: emergencyCategory,
        userNote: 'BoostDrive SOS — $emergencyCategory (${serviceType.toUpperCase()})',
      );

      if (requestId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS sent. Help is being coordinated.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _showCancelCountdownThenCategory() async {
    if (!mounted) return;
    final cancelled = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _SosCountdownDialog();
      },
    );
    if (!mounted || cancelled == true) return;
    await _pickEmergencyCategory();
  }

  Future<void> _pickEmergencyCategory() async {
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: BoostDriveTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'What do you need help with?',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _categoryTile(ctx, 'Mechanical failure', Icons.build_circle_outlined, 'mechanical', 'mechanic'),
                _categoryTile(ctx, 'Flat tire', Icons.album_outlined, 'flat_tire', 'mechanic'),
                _categoryTile(ctx, 'Accident', Icons.car_crash_outlined, 'accident', 'towing'),
                _categoryTile(ctx, 'Out of fuel', Icons.local_gas_station_outlined, 'out_of_fuel', 'mechanic'),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    final parts = choice.split('|');
    final category = parts[0];
    final type = parts.length > 1 ? parts[1] : 'mechanic';

    final user = ref.read(authStateProvider).value?.session?.user;
    String? vehicleId;
    if (user != null) {
      final vehicles = ref.read(userVehiclesProvider(user.id)).valueOrNull;
      if (vehicles != null && vehicles.isNotEmpty) {
        vehicleId = vehicles[_vehicleIndex.clamp(0, vehicles.length - 1)].id;
      }
    }
    await _dispatchSos(serviceType: type, emergencyCategory: category, vehicleId: vehicleId);
  }

  Widget _categoryTile(BuildContext ctx, String label, IconData icon, String category, String serviceType) {
    return ListTile(
      leading: Icon(icon, color: BoostDriveTheme.primaryColor),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      onTap: () => Navigator.pop(ctx, '$category|$serviceType'),
    );
  }

  Future<void> _shareWhatsAppLocation() async {
    final pos = _currentPosition ?? await ref.read(sosServiceProvider).getCurrentLocation();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not available yet')));
      }
      return;
    }
    final url =
        'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}';
    final text = Uri.encodeComponent(
      'BoostDrive — I am sharing my live location during a roadside situation: $url',
    );
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _maybeShowReviewPopup(String userId, List<Map<String, dynamic>> pendingReviews) {
    if (_reviewDialogOpen || pendingReviews.isEmpty || !mounted) return;
    final first = pendingReviews.first;
    final reviewId = first['id']?.toString() ?? '';
    if (reviewId.isEmpty || _shownReviewPromptIds.contains(reviewId)) return;
    _shownReviewPromptIds.add(reviewId);
    _reviewDialogOpen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PendingReviewCard(
            review: first,
            onSubmitted: () {
              if (mounted) {
                Navigator.of(ctx).pop();
                ref.invalidate(pendingSosReviewPromptsProvider(userId));
              }
            },
          ),
        ),
      );
      if (mounted) {
        setState(() => _reviewDialogOpen = false);
      } else {
        _reviewDialogOpen = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value?.session?.user;
    final activeRequestsRaw = user != null
        ? ref.watch(userActiveSosRequestsProvider(user.id)).valueOrNull ?? []
        : <SosRequest>[];
    final activeRequests = activeRequestsRaw.where((r) => r.isCustomerSosLive).toList();
    final hasActiveRequest = activeRequests.isNotEmpty;
    final activeRequest = hasActiveRequest ? activeRequests.first : null;
    final assignedProviderId = activeRequest?.assignedProviderId;

    final vehiclesAsync = user != null ? ref.watch(userVehiclesProvider(user.id)) : null;
    final providerCountAsync = ref.watch(verifiedProviderCountProvider);
    final pendingReviews = user != null
        ? ref.watch(pendingSosReviewPromptsProvider(user.id)).valueOrNull ?? const <Map<String, dynamic>>[]
        : const <Map<String, dynamic>>[];
    if (user != null) {
      _maybeShowReviewPopup(user.id, pendingReviews);
    }

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('EMERGENCY SOS'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            onPressed: _fetchLocation,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasActiveRequest && activeRequest != null) ...[
              _ActiveDispatchCard(
                request: activeRequest,
                assignedProviderId: assignedProviderId,
                onCancel: () async {
                  final id = activeRequest.id;
                  if (id.isEmpty) return;
                  final assigned = activeRequest.assignedProviderId != null &&
                      activeRequest.assignedProviderId!.isNotEmpty;
                  if (assigned && context.mounted) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: BoostDriveTheme.surfaceDark,
                        title: const Text('Cancel SOS?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Text(
                          'A provider is on this job. Cancel only if you no longer need help.',
                          style: TextStyle(color: BoostDriveTheme.textDim),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Keep request'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Cancel SOS', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                  }
                  try {
                    await ref.read(sosServiceProvider).cancelRequest(id);
                  } catch (e) {
                    final msg = e.toString();
                    final alreadyDone = msg.contains('P0001') ||
                        msg.toLowerCase().contains('already finished');
                    if (user != null && alreadyDone) {
                      ref.invalidate(userActiveSosRequestsProvider(user.id));
                      return;
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not cancel: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                onShareWhatsApp: _shareWhatsAppLocation,
              ),
              const SizedBox(height: 24),
            ],
            if (user != null)
              vehiclesAsync!.when(
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return Text(
                      'Add a vehicle in Garage for faster SOS hand-off.',
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                    );
                  }
                  final safeV = _vehicleIndex.clamp(0, vehicles.length - 1);
                  final v = vehicles[safeV];
                  return InkWell(
                    onTap: () async {
                      final picked = await showDialog<int>(
                        context: context,
                        builder: (ctx) => SimpleDialog(
                          title: const Text('Active vehicle'),
                          children: List.generate(vehicles.length, (i) {
                            final x = vehicles[i];
                            return SimpleDialogOption(
                              onPressed: () => Navigator.pop(ctx, i),
                              child: Text('${x.year} ${x.make} ${x.model}'),
                            );
                          }),
                        ),
                      );
                      if (picked != null && mounted) setState(() => _vehicleIndex = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, color: BoostDriveTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Active vehicle', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11)),
                                Text(
                                  '${v.year} ${v.make} ${v.model}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                Text('Tap to change', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white54),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (_, _) => const SizedBox(),
              ),
            const SizedBox(height: 16),
            providerCountAsync.when(
              data: (n) => Row(
                children: [
                  Icon(Icons.verified_user, size: 18, color: Colors.greenAccent.shade200),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      n > 0
                          ? '$n verified providers on the BoostDrive network.'
                          : 'Verified providers are available — help is coordinated automatically.',
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 16),
            _LocationPreviewCard(position: _currentPosition, onRetryLocation: _fetchLocation),
            const SizedBox(height: 28),
            if (!hasActiveRequest) ...[
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_holdController, _pulseController]),
                  builder: (context, child) {
                    final glow = 12 + 16 * _pulseController.value;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: BoostDriveTheme.primaryColor.withValues(alpha: 0.45),
                            blurRadius: glow,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Listener(
                    onPointerDown: (_) {
                      if (_isRequesting) return;
                      _holdController.forward(from: 0);
                    },
                    onPointerUp: (_) {
                      if (_holdController.status != AnimationStatus.completed) {
                        _holdController.reset();
                      }
                    },
                    onPointerCancel: (_) => _holdController.reset(),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: _holdController.value,
                              strokeWidth: 8,
                              backgroundColor: Colors.white12,
                              color: BoostDriveTheme.primaryColor,
                            ),
                          ),
                          Container(
                            width: 150,
                            height: 150,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: BoostDriveTheme.primaryColor,
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'Hold to call for help',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Hold the button for 2 seconds. You will get 5 seconds to cancel before we send your location.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: BoostDriveTheme.textDim, fontSize: 13, height: 1.4),
              ),
            ],
            if (_isRequesting) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor)),
            ],
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const EmergencyDirectoryPage()),
                );
              },
              icon: const Icon(Icons.phone_in_talk, color: BoostDriveTheme.primaryColor),
              label: const Text('Call emergency line', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPreviewCard extends StatelessWidget {
  const _LocationPreviewCard({this.position, this.onRetryLocation});

  final Position? position;
  final VoidCallback? onRetryLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: position != null
          ? BoostdriveGoogleMapGate(
              height: 140,
              fallbackLat: position!.latitude,
              fallbackLng: position!.longitude,
              map: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(position!.latitude, position!.longitude),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('preview_me'),
                    position: LatLng(position!.latitude, position!.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(title: 'Your position'),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                liteModeEnabled: false,
                mapToolbarEnabled: false,
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _MapGridPainter()),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined, color: Colors.white54, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          kIsWeb
                              ? 'Allow location for this site to see the map.'
                              : 'Turn on GPS and allow location to see the map.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                        ),
                        if (onRetryLocation != null) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: onRetryLocation,
                            child: const Text('Retry location'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.04);
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Opens the same direct-message thread used elsewhere (web shop / profile messaging).
Future<void> _openSosProviderChat(
  BuildContext context,
  WidgetRef ref,
  String customerUserId,
  String providerId,
) async {
  try {
    final convId = await ref.read(messageServiceProvider).getOrCreateDirectConversation(
          userId: customerUserId,
          providerId: providerId,
        );
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MessagesPage(initialConversationId: convId),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open chat: $e'), backgroundColor: Colors.red),
    );
  }
}

class _ActiveDispatchCard extends ConsumerWidget {
  const _ActiveDispatchCard({
    required this.request,
    this.assignedProviderId,
    required this.onCancel,
    required this.onShareWhatsApp,
  });

  final SosRequest request;
  final String? assignedProviderId;
  final VoidCallback onCancel;
  final VoidCallback onShareWhatsApp;

  Future<void> _openMaps(SosRequest r) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${r.lat},${r.lng}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = request.type.isNotEmpty ? request.type : 'assistance';
    final status = request.status.isNotEmpty ? request.status : 'pending';
    final providerProfile = assignedProviderId != null
        ? ref.watch(userProfileProvider(assignedProviderId!)).valueOrNull
        : null;
    final providerName = providerProfile?.fullName ?? 'Assigned provider';
    final company = providerProfile?.tradingName ?? providerProfile?.registeredBusinessName ?? '';
    final providerPhone = providerProfile?.phoneNumber ?? '';
    final canCancel = request.isCustomerSosLive;
    final waitingForAssignment =
        assignedProviderId == null || assignedProviderId!.trim().isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'LIVE SOS — ${type.toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              Tooltip(
                message: canCancel ? 'End this SOS request' : 'This request is already closed',
                child: TextButton(
                  onPressed: canCancel ? onCancel : null,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: canCancel ? Colors.redAccent : BoostDriveTheme.textDim),
                  ),
                ),
              ),
            ],
          ),
          Text(_statusLabel(status), style: TextStyle(color: BoostDriveTheme.textDim)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              child: waitingForAssignment
                  ? CustomerSosWaitingMap(request: request, height: 228)
                  : SizedBox(
                      height: 160,
                      child: BoostdriveGoogleMapGate(
                        height: 160,
                        fallbackLat: request.lat,
                        fallbackLng: request.lng,
                        map: Stack(
                          fit: StackFit.expand,
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(request.lat, request.lng),
                                zoom: 13,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('sos_customer'),
                                  position: LatLng(request.lat, request.lng),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                  infoWindow: const InfoWindow(title: 'You'),
                                ),
                                if (request.providerLastLat != null && request.providerLastLng != null)
                                  Marker(
                                    markerId: const MarkerId('sos_provider'),
                                    position: LatLng(request.providerLastLat!, request.providerLastLng!),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                                    infoWindow: InfoWindow(title: providerName),
                                  ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              liteModeEnabled: false,
                              mapToolbarEnabled: false,
                            ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: IconButton.filled(
                                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                onPressed: () => _openMaps(request),
                                icon: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          if (assignedProviderId != null) ...[
            const SizedBox(height: 12),
            Text(providerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            if (company.isNotEmpty) Text(company, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13)),
            Text(_etaLine(request), style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: providerPhone.isEmpty
                        ? null
                        : () => ref.read(sosServiceProvider).callEmergencyServices(providerPhone),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call provider'),
                    style: FilledButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () => _openSosProviderChat(context, ref, request.userId, assignedProviderId!),
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onShareWhatsApp,
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text('Share location (WhatsApp)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _etaLine(SosRequest request) {
    if (request.etaMinutes != null) {
      return 'ETA: ~${request.etaMinutes} min (straight-line estimate)';
    }
    if (request.providerLastLat != null && request.providerLastLng != null) {
      return 'ETA: recalculating…';
    }
    return 'ETA: waiting for provider location…';
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Finding a verified provider…';
      case 'accepted':
      case 'assigned':
        return 'Provider assigned — stay by your vehicle if safe.';
      default:
        return status;
    }
  }
}

class _SosCountdownDialog extends StatefulWidget {
  @override
  State<_SosCountdownDialog> createState() => _SosCountdownDialogState();
}

class _PendingReviewCard extends ConsumerStatefulWidget {
  const _PendingReviewCard({
    required this.review,
    required this.onSubmitted,
  });

  final Map<String, dynamic> review;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_PendingReviewCard> createState() => _PendingReviewCardState();
}

class _PendingReviewCardState extends ConsumerState<_PendingReviewCard> {
  int _rating = 5;
  bool _submitting = false;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerName =
        widget.review['provider_name_snapshot']?.toString().trim().isNotEmpty == true
            ? widget.review['provider_name_snapshot'].toString()
            : 'service provider';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RATE YOUR SOS PROVIDER',
            style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          Text('How was $providerName?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: _submitting ? null : () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          TextField(
            controller: _text,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Optional comment',
              hintStyle: TextStyle(color: BoostDriveTheme.textDim),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _submitting
                ? null
                : () async {
                    setState(() => _submitting = true);
                    try {
                      await ref.read(sosServiceProvider).submitProviderReview(
                            reviewId: widget.review['id'].toString(),
                            rating: _rating,
                            reviewText: _text.text.trim(),
                          );
                      widget.onSubmitted();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thanks for your feedback!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not submit review: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
            child: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SUBMIT REVIEW'),
          ),
        ],
      ),
    );
  }
}

class _SosCountdownDialogState extends State<_SosCountdownDialog> {
  static const int _start = 5;
  int _secondsLeft = _start;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        Navigator.of(context).pop(false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BoostDriveTheme.surfaceDark,
      title: const Text('Sending SOS…', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text(
        'Tap Cancel if this was a mistake.\nAuto-send in $_secondsLeft s.',
        style: TextStyle(color: BoostDriveTheme.textDim),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop(true);
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}
