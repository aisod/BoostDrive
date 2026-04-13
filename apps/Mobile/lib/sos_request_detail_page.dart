import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

import 'boostdrive_google_map_gate.dart';

/// Provider opens this screen to review a pending SOS; customer sees a responding heartbeat on the map.
class SosRequestDetailPage extends ConsumerStatefulWidget {
  const SosRequestDetailPage({super.key, required this.request});

  final SosRequest request;

  @override
  ConsumerState<SosRequestDetailPage> createState() => _SosRequestDetailPageState();
}

class _SosRequestDetailPageState extends ConsumerState<SosRequestDetailPage> {
  Timer? _heartbeat;
  GoogleMapController? _mapController;

  /// [SosRequest.fromMap] defaults missing coords to `0,0`; treat that as unknown.
  bool get _hasValidRequesterLocation {
    final lat = widget.request.lat;
    final lng = widget.request.lng;
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    return true;
  }

  bool _isCompleting = false;

  void _refreshSosState(String? providerId) {
    ref.invalidate(globalActiveSosRequestsProvider);
    ref.invalidate(userActiveSosRequestsProvider(widget.request.userId));
    if (providerId != null && providerId.isNotEmpty) {
      ref.invalidate(providerAssignedRequestsProvider(providerId));
      ref.invalidate(providerCompletedSosCountProvider(providerId));
    }
    ref.invalidate(pendingSosReviewPromptsProvider(widget.request.userId));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startHeartbeat());
  }

  Future<void> _startHeartbeat() async {
    final sos = ref.read(sosServiceProvider);
    try {
      await sos.upsertProviderResponding(widget.request.id);
    } catch (_) {}
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 12), (_) async {
      try {
        await sos.upsertProviderResponding(widget.request.id);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _mapController?.dispose();
    final id = widget.request.id;
    if (id.isNotEmpty) {
      unawaited(ref.read(sosServiceProvider).deleteMyProviderResponding(id));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;
    final cat = widget.request.emergencyCategory;
    final type = widget.request.type;
    final normalizedStatus = widget.request.status.toLowerCase().trim();
    final isAlreadyAssigned = widget.request.assignedProviderId != null &&
        widget.request.assignedProviderId!.isNotEmpty;
    final isPending = normalizedStatus == 'pending';
    final canAccept = userId != null &&
        widget.request.id.isNotEmpty &&
        (isPending || !isAlreadyAssigned);
    final isAssignedToMe = userId != null && widget.request.assignedProviderId == userId;
    final canComplete = isAssignedToMe &&
        const {'assigned', 'accepted', 'active'}.contains(normalizedStatus);
    final canCancelAssignment = isAssignedToMe &&
        const {'assigned', 'accepted', 'active'}.contains(normalizedStatus);
    final actionLabel = canAccept
        ? 'ACCEPT REQUEST'
        : isAssignedToMe
            ? 'ASSIGNED TO YOU'
            : 'ALREADY ASSIGNED';

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('SOS REQUEST'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.request.userNote.isNotEmpty ? widget.request.userNote : 'Emergency assistance',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type: ${type.isNotEmpty ? type.toUpperCase() : '—'}'
                  '${cat != null && cat.isNotEmpty ? ' · $cat' : ''}',
                  style: TextStyle(color: BoostDriveTheme.textDim),
                ),
                const SizedBox(height: 8),
                Text(
                  'Location: ${widget.request.lat.toStringAsFixed(5)}, ${widget.request.lng.toStringAsFixed(5)}',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildRequesterMap())),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'The customer can see that a provider is reviewing this request while you stay on this screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: !canAccept
                      ? null
                      : () async {
                          try {
                            await ref.read(sosServiceProvider).acceptRequest(widget.request.id, userId);
                            _refreshSosState(userId);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Request accepted. Customer will see you as assigned.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to accept: $e')),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: BoostDriveTheme.primaryColor,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                if (_hasValidRequesterLocation) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final destination =
                          '${widget.request.lat.toStringAsFixed(6)},${widget.request.lng.toStringAsFixed(6)}';
                      final uri = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$destination',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open navigation app.')),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text(
                      'NAVIGATE TO CLIENT',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
                if (canComplete) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isCompleting
                        ? null
                        : () async {
                            final noteController = TextEditingController();
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: BoostDriveTheme.surfaceDark,
                                title: const Text('Complete assignment?', style: TextStyle(color: Colors.white)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'You must be near the customer location to complete this SOS.',
                                      style: TextStyle(color: BoostDriveTheme.textDim),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: noteController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Completion note (optional)',
                                        hintStyle: TextStyle(color: BoostDriveTheme.textDim),
                                        filled: true,
                                        fillColor: Colors.white.withValues(alpha: 0.06),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('CANCEL'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('ASSIGNMENT DONE'),
                                  ),
                                ],
                              ),
                            );
                            final note = noteController.text.trim();
                            noteController.dispose();
                            if (confirm != true) return;
                            if (!mounted) return;
                            setState(() => _isCompleting = true);
                            try {
                              await ref.read(sosServiceProvider).completeAssignment(
                                    requestId: widget.request.id,
                                    completionNote: note.isEmpty ? null : note,
                                  );
                              _refreshSosState(userId);
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Assignment completed. Customer can now leave a review.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not complete: $e')),
                              );
                            } finally {
                              if (mounted) setState(() => _isCompleting = false);
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: Colors.green.shade300),
                    ),
                    child: _isCompleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'ASSIGNMENT DONE',
                            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.greenAccent),
                          ),
                  ),
                ],
                if (canCancelAssignment) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _isCompleting
                        ? null
                        : () async {
                            final reasonController = TextEditingController();
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: BoostDriveTheme.surfaceDark,
                                title: const Text('Cancel assignment?', style: TextStyle(color: Colors.white)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'This returns the SOS to pending so another provider can accept it.',
                                      style: TextStyle(color: BoostDriveTheme.textDim),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: reasonController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Reason (optional)',
                                        hintStyle: TextStyle(color: BoostDriveTheme.textDim),
                                        filled: true,
                                        fillColor: Colors.white.withValues(alpha: 0.06),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('KEEP ASSIGNMENT'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                    child: const Text('CANCEL ASSIGNMENT'),
                                  ),
                                ],
                              ),
                            );
                            final reason = reasonController.text.trim();
                            reasonController.dispose();
                            if (confirm != true) return;
                            if (!mounted) return;
                            setState(() => _isCompleting = true);
                            try {
                              await ref.read(sosServiceProvider).cancelAssignmentByProvider(
                                    requestId: widget.request.id,
                                    reason: reason.isEmpty ? null : reason,
                                  );
                              _refreshSosState(userId);
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Assignment cancelled. SOS returned to pending queue.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not cancel assignment: $e')),
                              );
                            } finally {
                              if (mounted) setState(() => _isCompleting = false);
                            }
                          },
                    child: const Text(
                      'CANCEL ASSIGNMENT',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequesterMap() {
    if (!_hasValidRequesterLocation) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No map — request has no valid GPS coordinates yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ),
      );
    }

    final target = LatLng(widget.request.lat, widget.request.lng);
    final markerId = MarkerId('sos_requester_${widget.request.id}');
    final markers = <Marker>{
      Marker(
        markerId: markerId,
        position: target,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Motorist location',
          snippet: '${widget.request.lat.toStringAsFixed(5)}, ${widget.request.lng.toStringAsFixed(5)}',
        ),
      ),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 240.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: BoostdriveGoogleMapGate(
              height: h,
              fallbackLat: widget.request.lat,
              fallbackLng: widget.request.lng,
              map: GoogleMap(
                initialCameraPosition: CameraPosition(target: target, zoom: 15.5),
                markers: markers,
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
                myLocationEnabled: !kIsWeb,
                myLocationButtonEnabled: false,
                liteModeEnabled: false,
                onMapCreated: (c) => _mapController = c,
              ),
            ),
          ),
        );
      },
    );
  }
}
