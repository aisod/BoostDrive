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
  SosService? _sosService;

  bool get _hasValidRequesterLocation => SosProviderUiRules.hasValidRequesterLocation(widget.request);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sosService = ref.read(sosServiceProvider);
      _startHeartbeat();
    });
  }

  Future<void> _startHeartbeat() async {
    _sosService ??= ref.read(sosServiceProvider);
    final sos = _sosService!;
    try {
      await sos.upsertProviderResponding(widget.request.id);
    } catch (_) {}
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 12), (_) async {
      final active = _sosService;
      if (active == null) return;
      try {
        await active.upsertProviderResponding(widget.request.id);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _mapController?.dispose();
    final id = widget.request.id;
    final sos = _sosService;
    if (id.isNotEmpty && sos != null) {
      unawaited(sos.deleteMyProviderResponding(id));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;
    final cat = widget.request.emergencyCategory;
    final type = widget.request.type;
    final canAccept = SosProviderUiRules.canAccept(request: widget.request, userId: userId);
    final isAssignedToMe = SosProviderUiRules.isAssignedToMe(request: widget.request, userId: userId);
    final canComplete = SosProviderUiRules.canComplete(request: widget.request, userId: userId);
    final canCancelAssignment =
        SosProviderUiRules.canCancelAssignment(request: widget.request, userId: userId);
    final actionLabel = SosProviderUiRules.actionLabel(request: widget.request, userId: userId);

    final palette = DashboardPalette.of(context);
    final profile = userId != null ? ref.watch(userProfileProvider(userId)).valueOrNull : null;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: MobileProviderUi.glassAppBar(
        context: context,
        palette: palette,
        title: 'SOS Detail',
        showBack: true,
        avatar: profile != null
            ? MobileProviderUi.profileAvatar(palette: palette, imageUrl: profile.profileImg, radius: 16, orangeRing: true)
            : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildRequesterMap()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: MobileProviderUi.marginMobile, bottom: 12),
                  child: MobileProviderUi.floatingEtaBadge(
                    palette: palette,
                    etaLabel: 'En route',
                    distanceLabel: '${widget.request.lat.toStringAsFixed(1)} km',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MobileProviderUi.marginMobile,
                  0,
                  MobileProviderUi.marginMobile,
                  20,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: MobileProviderUi.glassCard(palette),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          MobileProviderUi.urgencyBadge(palette: palette, label: 'Critical Alert', critical: true),
                          const SizedBox(width: 8),
                          if (type.isNotEmpty)
                            MobileProviderUi.urgencyBadge(palette: palette, label: type),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.request.userNote.isNotEmpty ? widget.request.userNote : 'Emergency assistance',
                        style: DashboardTypography.headlineMd(palette).copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: ${type.isNotEmpty ? type.toUpperCase() : '—'}'
                        '${cat != null && cat.isNotEmpty ? ' · $cat' : ''}',
                        style: DashboardTypography.bodySm(palette),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Location: ${widget.request.lat.toStringAsFixed(5)}, ${widget.request.lng.toStringAsFixed(5)}',
                        style: DashboardTypography.bodySm(palette),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The customer can see that a provider is reviewing this request while you stay on this screen.',
                        textAlign: TextAlign.center,
                        style: DashboardTypography.bodySm(palette),
                      ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: !canAccept
                      ? null
                      : () async {
                          try {
                            await ref.read(sosServiceProvider).acceptRequest(widget.request.id, userId!);
                            _refreshSosState(userId);
                            if (!context.mounted) return;
                            Navigator.of(context).maybePop();
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
                    backgroundColor: palette.primaryContainer,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MobileProviderUi.radiusControl),
                    ),
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
                              builder: (ctx) => MobileProviderUi.kineticAlertDialog(
                                palette: palette,
                                title: const Text('Complete assignment?'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'You must be near the customer location to complete this SOS.',
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: noteController,
                                      style: TextStyle(color: palette.title),
                                      decoration: MobileProviderUi.fieldDecoration(
                                        palette,
                                        hint: 'Completion note (optional)',
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
                                    style: FilledButton.styleFrom(
                                      backgroundColor: palette.primaryContainer,
                                    ),
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
                              Navigator.of(context).maybePop();
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
                              builder: (ctx) => MobileProviderUi.kineticAlertDialog(
                                palette: palette,
                                title: const Text('Cancel assignment?'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'This returns the SOS to pending so another provider can accept it.',
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: reasonController,
                                      style: TextStyle(color: palette.title),
                                      decoration: MobileProviderUi.fieldDecoration(
                                        palette,
                                        hint: 'Reason (optional)',
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
                                    style: FilledButton.styleFrom(backgroundColor: palette.error),
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
                              Navigator.of(context).maybePop();
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
              ),
            ],
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
