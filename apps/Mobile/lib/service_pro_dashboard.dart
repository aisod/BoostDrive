import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'boostdrive_google_map_gate.dart';
import 'job_card_tool_page.dart';
import 'messages_page.dart';
import 'provider_orders_page.dart';
import 'sos_request_detail_page.dart';

class ServiceProDashboard extends ConsumerStatefulWidget {
  const ServiceProDashboard({super.key});

  @override
  ConsumerState<ServiceProDashboard> createState() => _ServiceProDashboardState();
}

class _ServiceProDashboardState extends ConsumerState<ServiceProDashboard> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentPosition;
  Timer? _sosLocationTimer;
  Set<String> _trackedSosIds = {};
  bool? _optimisticOnline;
  bool _updatingAvailability = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = ref.read(currentUserProvider)?.id;
      if (uid == null) return;
      final list = ref.read(providerAssignedRequestsProvider(uid)).valueOrNull ?? [];
      if (list.isNotEmpty) {
        _trackedSosIds = list.map((e) => e.id).toSet();
        _syncSosLocationPulse(uid);
      }
    });
  }

  @override
  void dispose() {
    _sosLocationTimer?.cancel();
    super.dispose();
  }

  void _syncSosLocationPulse(String providerId) {
    _sosLocationTimer?.cancel();
    _sosLocationTimer = null;

    void tick() {
      final asyncList = ref.read(providerAssignedRequestsProvider(providerId));
      final list = asyncList.valueOrNull ?? [];
      if (list.isEmpty) return;
      unawaited(_pushProviderLocations(providerId, list));
    }

    tick();
    _sosLocationTimer = Timer.periodic(const Duration(seconds: 20), (_) => tick());
  }

  Future<void> _pushProviderLocations(String providerId, List<SosRequest> list) async {
    final pos = await ref.read(sosServiceProvider).getCurrentLocation();
    if (pos == null || !mounted) return;
    final sos = ref.read(sosServiceProvider);
    for (final r in list) {
      await sos.updateProviderTracking(
        requestId: r.id,
        providerId: providerId,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    }
  }

  Future<void> _initLocation() async {
    try {
      final position = await ref.read(sosServiceProvider).getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _markers.add(
            Marker(
              markerId: const MarkerId('me'),
              position: _currentPosition!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              infoWindow: const InfoWindow(title: 'My Location'),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: Text('Please log in'));

    ref.listen<AsyncValue<List<SosRequest>>>(providerAssignedRequestsProvider(user.id), (previous, next) {
      next.whenData((list) {
        if (list.isEmpty) {
          _sosLocationTimer?.cancel();
          _sosLocationTimer = null;
          _trackedSosIds = {};
          return;
        }
        final ids = list.map((e) => e.id).toSet();
        if (setEquals(ids, _trackedSosIds) && _sosLocationTimer != null) {
          return;
        }
        _trackedSosIds = ids;
        _syncSosLocationPulse(user.id);
      });
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(context, ref, user.id),
            const SizedBox(height: 24),
            _buildStatusToggle(ref, user.id),
            const SizedBox(height: 24),
            _buildActiveJobMap(),
            const SizedBox(height: 24),
            _buildStatsRow(ref, user.id),
            const SizedBox(height: 32),
            _buildLiveRequests(ref),
            const SizedBox(height: 32),
            _buildInProgressJobs(ref, user.id),
            const SizedBox(height: 32),
            _buildActiveServicesSection(ref, user.id),
            const SizedBox(height: 32),
            _buildIncomingJobCardRequests(ref, user.id),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String uid) {
    final liveAlerts = ref.watch(globalActiveSosRequestsProvider).valueOrNull ?? [];
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: BoostDriveTheme.surfaceDark,
              backgroundImage: profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null,
              child: profile.profileImg.isEmpty ? const Icon(Icons.person, color: BoostDriveTheme.primaryColor) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'PRO ID: @${profile.uid.length >= 8 ? profile.uid.substring(0, 8).toUpperCase() : profile.uid.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ref.watch(userNotificationsStreamProvider(uid)).when(
                  data: (list) {
                    final unreadCount = list.where((n) => n['is_read'] == false).length;
                    final hasLive = liveAlerts.isNotEmpty;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () => _showNotificationsOverlay(context, ref, uid),
                          child: _buildHeaderIcon(Icons.notifications_none_rounded),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else if (hasLive)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: BoostDriveTheme.backgroundDark, width: 2),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => GestureDetector(
                    onTap: () => _showNotificationsOverlay(context, ref, uid),
                    child: _buildHeaderIcon(Icons.notifications_none_rounded),
                  ),
                  error: (_, _) => GestureDetector(
                    onTap: () => _showNotificationsOverlay(context, ref, uid),
                    child: _buildHeaderIcon(Icons.notifications_off_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                ref.watch(unreadConversationsProvider(uid)).when(
                  data: (unreadConversationIds) {
                    final unreadCount = unreadConversationIds.length;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () => _openMessages(context),
                          child: _buildHeaderIcon(Icons.chat_bubble_outline_rounded),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => GestureDetector(
                    onTap: () => _openMessages(context),
                    child: _buildHeaderIcon(Icons.chat_bubble_outline_rounded),
                  ),
                  error: (_, _) => GestureDetector(
                    onTap: () => _openMessages(context),
                    child: _buildHeaderIcon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text('Error loading header'),
    );
  }

  void _openMessages(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MessagesPage()),
    );
  }

  void _showNotificationsOverlay(BuildContext context, WidgetRef ref, String uid) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => NotificationsOverlay(
        onNotificationTap: (type, id) {
          if (type == 'support') {
            ref.read(pendingSupportTicketIdProvider.notifier).state = id;
            return;
          }
          if (type == 'job_card_quote' ||
              type == 'job_card_status' ||
              type == 'job_card_completed' ||
              type == 'job_card_decision' ||
              type == 'job_card_cancelled' ||
              type == 'job_card_request') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => JobCardToolPage(initialJobCardId: id)),
            );
            return;
          }
          if (type == 'sos') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProviderOrdersPage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildStatusToggle(WidgetRef ref, String uid) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        final isOnline = _optimisticOnline ?? profile.isOnline;
        Future<void> setAvailability(bool nextOnline) async {
          if (_updatingAvailability || nextOnline == isOnline) return;
          setState(() {
            _optimisticOnline = nextOnline;
            _updatingAvailability = true;
          });
          try {
            await ref.read(userServiceProvider).updateProfile(profile.copyWith(isOnline: nextOnline));
            ref.invalidate(userProfileProvider(uid));
            await ref.read(userProfileProvider(uid).future);
          } catch (e) {
            if (mounted) {
              setState(() => _optimisticOnline = profile.isOnline);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not update availability: $e')),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _updatingAvailability = false);
            }
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AVAILABILITY STATUS',
              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _updatingAvailability ? null : () => setAvailability(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isOnline ? BoostDriveTheme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_tethering, color: isOnline ? Colors.white : Colors.white24, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'AVAILABLE',
                              style: TextStyle(
                                color: isOnline ? Colors.white : Colors.white24,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _updatingAvailability ? null : () => setAvailability(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isOnline ? Colors.white10 : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.power_settings_new, color: !isOnline ? Colors.white : Colors.white24, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'OFFLINE',
                              style: TextStyle(
                                color: !isOnline ? Colors.white : Colors.white24,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_updatingAvailability)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'Updating availability...',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            if (isOnline)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  '• Live location visible to SOS dispatch',
                  style: TextStyle(color: Colors.green.shade400, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildActiveJobMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIVE JOB MAP',
          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              BoostdriveGoogleMapGate(
                height: 220,
                fallbackLat: _currentPosition?.latitude ?? -22.5609,
                fallbackLng: _currentPosition?.longitude ?? 17.0658,
                map: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(-22.5609, 17.0658),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  myLocationEnabled: !kIsWeb,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  style: _mapStyle,
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: () {
                    if (_currentPosition != null) {
                      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
                    }
                  },
                  backgroundColor: BoostDriveTheme.primaryColor,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.navigation, color: Colors.blueAccent, size: 14),
                      const SizedBox(width: 8),
                      const Text(
                        'ONE-TAP NAV READY',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(WidgetRef ref, String uid) {
    final jobsAsync = ref.watch(providerCompletedSosCountProvider(uid));
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        final jobsLabel = jobsAsync.when(
          data: (n) => '$n',
          loading: () => '…',
          error: (_, _) => '—',
        );
        return Row(
          children: [
            Expanded(child: _buildStatCard('Earnings', '\$${profile.totalEarnings.toStringAsFixed(0)}', 'LIFETIME', true)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Jobs', jobsLabel, 'COMPLETED', false)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rating',
                '—',
                'NO REVIEWS YET',
                false,
                subtextMuted: true,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtext,
    bool isPositive, {
    bool subtextMuted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              color: subtextMuted
                  ? BoostDriveTheme.textDim
                  : (isPositive ? Colors.green : BoostDriveTheme.primaryColor),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRequests(WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.id;
    final providerTypes = uid != null
        ? (ref.watch(userProfileProvider(uid)).valueOrNull?.providerServiceTypes ?? const <String>[])
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LIVE SOS ALERTS',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<SosRequest>>(
          stream: ref.watch(sosServiceProvider).getGlobalActiveRequests(),
          builder: (context, snapshot) {
            final requests = snapshot.data ?? [];
            final filtered = providerTypes.isEmpty
                ? <SosRequest>[]
                : requests.where((r) => sosRequestMatchesProviderServiceTypes(r, providerTypes)).toList();

            if (providerTypes.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Center(
                  child: Text(
                    'Add service types in Account → Profile so you only see SOS requests you can fulfill.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13, height: 1.35),
                  ),
                ),
              );
            }

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Center(
                  child: Text(
                    'No pending SOS requests match your services (${providerTypes.join(", ")}).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13, height: 1.35),
                  ),
                ),
              );
            }

            final userId = ref.read(currentUserProvider)?.id;
            return Column(
              children: filtered.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRequestCard(
                  ref: ref,
                  request: req,
                  userId: userId,
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequestCard({
    required WidgetRef ref,
    required SosRequest request,
    required String? userId,
  }) {
    final tag = 'SOS — ${request.type.toUpperCase()}';
    final title = request.userNote.isNotEmpty ? request.userNote : 'No notes provided';
    final userLine = 'Customer ID: ${request.userId.length >= 8 ? request.userId.substring(0, 8) : request.userId}';
    final tagColor = request.type.toLowerCase() == 'towing' ? Colors.redAccent : Colors.blueAccent;
    final requestId = request.id;

    String distanceLabel = kIsWeb ? 'Allow location for distance' : 'Enable GPS for distance';
    final me = _currentPosition;
    if (me != null) {
      final km = GeoEta.haversineKm(me.latitude, me.longitude, request.lat, request.lng);
      distanceLabel = km < 1 ? '${(km * 1000).round()} m away' : '${km.toStringAsFixed(1)} km away';
    }

    Future<void> openDetail() async {
      if (!mounted || requestId.isEmpty) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => SosRequestDetailPage(request: request)),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tagColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: openDetail,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                        Text(distanceLabel, style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(userLine, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.touch_app, size: 16, color: BoostDriveTheme.primaryColor.withValues(alpha: 0.9)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tap to open — customer sees you are responding (before you accept).',
                            style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12, height: 1.25),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: requestId.isEmpty ? null : openDetail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('OPEN REQUEST', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (userId == null || requestId.isEmpty)
                        ? null
                        : () async {
                            final sos = ref.read(sosServiceProvider);
                            try {
                              await sos.upsertProviderResponding(requestId);
                              await sos.acceptRequest(requestId, userId);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Request accepted. Customer will see you as assigned.')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to accept: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BoostDriveTheme.primaryColor,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInProgressJobs(WidgetRef ref, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ONGOING FULFILLMENT',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),
        ref.watch(providerAssignedRequestsProvider(uid)).when(
              data: (list) {
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: BoostDriveTheme.textDim),
                          const SizedBox(height: 12),
                          Text(
                            'No ongoing jobs',
                            style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: list.map((r) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: r.id.isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(builder: (_) => SosRequestDetailPage(request: r)),
                                  );
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.local_shipping, color: BoostDriveTheme.primaryColor, size: 28),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.userNote.isNotEmpty ? r.userNote : 'SOS — ${r.type.toUpperCase()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Status: ${r.status}',
                                        style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.white54),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor),
                ),
              ),
              error: (e, _) => Text('Could not load jobs: $e', style: TextStyle(color: Colors.red.shade200)),
            ),
      ],
    );
  }

  Widget _buildActiveServicesSection(WidgetRef ref, String uid) {
    final catalogAsync = ref.watch(_dashboardProviderServicesFamily(uid));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIVE SERVICES',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),
        catalogAsync.when(
              data: (rows) {
                final activeRows = rows.where((r) => r['is_active'] != false).toList();
                if (activeRows.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.settings_outlined, size: 48, color: BoostDriveTheme.textDim),
                          const SizedBox(height: 12),
                          Text(
                            'No services listed',
                            style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add services in the Services tab to show them here.',
                            style: TextStyle(color: BoostDriveTheme.textDim.withValues(alpha: 0.8), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: activeRows.map((row) {
                    final name = row['name']?.toString().trim();
                    final label = (name == null || name.isEmpty) ? 'Unnamed service' : name;
                    return Chip(
                      label: Text(
                        label,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                      side: BorderSide(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.4)),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Text(
                'Could not load services: $e',
                style: TextStyle(color: Colors.red.shade200, fontSize: 12),
              ),
            ),
      ],
    );
  }

  Widget _buildIncomingJobCardRequests(WidgetRef ref, String providerId) {
    final asyncCards = ref.watch(_incomingProviderJobCardsFamily(providerId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CUSTOMER JOB CARD REQUESTS',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        asyncCards.when(
          data: (rows) {
            if (rows.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Text(
                  'No new job card requests yet.',
                  style: TextStyle(color: BoostDriveTheme.textDim),
                ),
              );
            }
            final visible = rows.take(3).toList();
            return Column(
              children: visible.map((row) {
                final status = (row['status']?.toString() ?? 'submitted').toLowerCase();
                final labor = (row['labor_amount'] as num?)?.toDouble() ?? 0;
                final statusLabel = status == 'quoted' ? 'AWAITING CLIENT RESPONSE' : status.toUpperCase();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row['vehicle_label']?.toString() ?? 'Vehicle not set',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row['concern_summary']?.toString() ?? '',
                        style: TextStyle(color: BoostDriveTheme.textDim),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Status: $statusLabel', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
                          const Spacer(),
                          Text('Labor: N\$${labor.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      if (status == 'submitted') ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final amount = await _promptProviderQuote(context);
                              if (amount == null) return;
                              try {
                                await ref.read(jobCardServiceProvider).providerQuoteJobCard(
                                      jobCardId: row['id'].toString(),
                                      providerId: providerId,
                                      quotedLaborAmount: amount,
                                    );
                                // Defer refresh until after the quote dialog is fully closed so Riverpod/layout stay stable.
                                if (!context.mounted) return;
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!context.mounted) return;
                                  ref.invalidate(_incomingProviderJobCardsFamily(providerId));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Quote sent. Awaiting client response.')),
                                    );
                                  }
                                });
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not send quote: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
                            child: const Text('RESPOND WITH PRICE'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, _) => Text('Could not load job card requests: $e', style: TextStyle(color: Colors.red.shade200)),
        ),
      ],
    );
  }

  Future<double?> _promptProviderQuote(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Enter labor quote', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Labor amount (N\$)',
            hintStyle: TextStyle(color: BoostDriveTheme.textDim),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SEND QUOTE')),
        ],
      ),
    );
    final v = double.tryParse(c.text.trim());
    c.dispose();
    if (ok != true || v == null || v < 0) return null;
    return v;
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
}

final _dashboardProviderServicesFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(providerOpsServiceProvider).listProviderServices(uid);
});

final _incomingProviderJobCardsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, providerId) async {
  return ref.read(jobCardServiceProvider).listIncomingJobCardsForProvider(providerId);
});
