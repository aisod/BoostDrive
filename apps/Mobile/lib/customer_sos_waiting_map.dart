import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

import 'boostdrive_google_map_gate.dart';

/// Interactive map while the customer waits for assignment: nearby providers + responding indicators.
class CustomerSosWaitingMap extends ConsumerStatefulWidget {
  const CustomerSosWaitingMap({super.key, required this.request, this.height = 220});

  final SosRequest request;
  final double height;

  @override
  ConsumerState<CustomerSosWaitingMap> createState() => _CustomerSosWaitingMapState();
}

class _CustomerSosWaitingMapState extends ConsumerState<CustomerSosWaitingMap>
    with SingleTickerProviderStateMixin {
  static const _heartbeatTtl = Duration(seconds: 45);

  List<UserProfile> _nearby = [];
  bool _loadingNearby = true;
  late final AnimationController _dotsController;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _loadNearby();
  }

  @override
  void didUpdateWidget(covariant CustomerSosWaitingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id ||
        oldWidget.request.lat != widget.request.lat ||
        oldWidget.request.lng != widget.request.lng) {
      _loadNearby();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _loadNearby() async {
    setState(() => _loadingNearby = true);
    final type = widget.request.type.trim().isNotEmpty ? widget.request.type : null;
    final list = await ref.read(userServiceProvider).getNearbyVerifiedProviders(
          customerLat: widget.request.lat,
          customerLng: widget.request.lng,
          serviceType: type,
        );
    if (mounted) {
      setState(() {
        _nearby = list;
        _loadingNearby = false;
      });
      await _fitCameraToMarkers();
    }
  }

  Future<void> _fitCameraToMarkers() async {
    final c = _mapController;
    if (c == null || !mounted) return;

    final center = LatLng(widget.request.lat, widget.request.lng);
    final pts = <LatLng>[center];
    for (final p in _nearby) {
      final lat = p.workshopLat;
      final lng = p.workshopLng;
      if (lat != null && lng != null) pts.add(LatLng(lat, lng));
    }

    try {
      if (pts.length == 1) {
        await c.animateCamera(CameraUpdate.newLatLngZoom(center, 11));
        return;
      }
      double minLat = pts.first.latitude;
      double maxLat = pts.first.latitude;
      double minLng = pts.first.longitude;
      double maxLng = pts.first.longitude;
      for (final p in pts.skip(1)) {
        minLat = minLat < p.latitude ? minLat : p.latitude;
        maxLat = maxLat > p.latitude ? maxLat : p.latitude;
        minLng = minLng < p.longitude ? minLng : p.longitude;
        maxLng = maxLng > p.longitude ? maxLng : p.longitude;
      }
      const pad = 0.02;
      if ((maxLat - minLat).abs() < 1e-6) {
        minLat -= pad;
        maxLat += pad;
      }
      if ((maxLng - minLng).abs() < 1e-6) {
        minLng -= pad;
        maxLng += pad;
      }
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
          56,
        ),
      );
    } catch (_) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(center, 11));
    }
  }

  Set<String> _freshRespondingIds(List<SosRespondingHeartbeat> beats) {
    final now = DateTime.now().toUtc();
    return beats
        .where((b) => now.difference(b.lastSeenAt.toUtc()) <= _heartbeatTtl)
        .map((b) => b.providerId)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final beatsAsync = ref.watch(sosRespondingForRequestProvider(widget.request.id));
    final respondingIds = beatsAsync.maybeWhen(
      data: _freshRespondingIds,
      orElse: () => <String>{},
    );
    final hasResponding = respondingIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: _buildGoogleMap(respondingIds),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                hasResponding
                    ? 'A provider is reviewing your request'
                    : 'Searching for a nearby provider…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hasResponding ? BoostDriveTheme.primaryColor : BoostDriveTheme.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _ThreeMovingDots(animation: _dotsController),
          ],
        ),
        if (_loadingNearby)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Updating provider pins…',
              textAlign: TextAlign.center,
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11),
            ),
          )
        else if (_nearby.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'No workshop pins in range — providers are still alerted on the network.',
              textAlign: TextAlign.center,
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11, height: 1.3),
            ),
          ),
      ],
    );
  }

  Widget _buildGoogleMap(Set<String> respondingIds) {
    final center = LatLng(widget.request.lat, widget.request.lng);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('sos_customer_wait'),
        position: center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You', snippet: 'Waiting for a provider'),
      ),
    };

    for (var i = 0; i < _nearby.length; i++) {
      final p = _nearby[i];
      final lat = p.workshopLat;
      final lng = p.workshopLng;
      if (lat == null || lng == null) continue;
      final isResp = respondingIds.contains(p.uid);
      final name = p.tradingName?.trim().isNotEmpty == true
          ? p.tradingName!
          : (p.fullName.isNotEmpty ? p.fullName : 'Provider');
      markers.add(
        Marker(
          markerId: MarkerId('nearby_${p.uid}'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isResp ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: name,
            snippet: isResp ? 'Responding…' : 'Nearby',
          ),
        ),
      );
    }

    return BoostdriveGoogleMapGate(
      height: widget.height,
      fallbackLat: widget.request.lat,
      fallbackLng: widget.request.lng,
      map: GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: 11),
        markers: markers,
        zoomControlsEnabled: true,
        myLocationButtonEnabled: false,
        liteModeEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (controller) {
          _mapController = controller;
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitCameraToMarkers());
        },
      ),
    );
  }
}

/// Typing-style three dots synced to [animation] 0..1.
class _ThreeMovingDots extends StatelessWidget {
  const _ThreeMovingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final wave = math.sin((animation.value * 2 * math.pi) + (i * 1.1));
            final o = (0.45 + 0.55 * ((wave + 1) / 2)).clamp(0.35, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: BoostDriveTheme.primaryColor.withValues(alpha: o),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
