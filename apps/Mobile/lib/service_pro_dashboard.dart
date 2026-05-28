// ignore_for_file: use_build_context_synchronously

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

    final palette = DashboardPalette.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MobileProviderUi.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(context, ref, user.id, palette),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, String uid, DashboardPalette palette) {
    final liveAlerts = ref.watch(globalActiveSosRequestsProvider).valueOrNull ?? [];
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: MobileProviderUi.premiumCard(palette),
          child: Row(
          children: [
            MobileProviderUi.profileAvatar(
              palette: palette,
              imageUrl: profile.profileImg,
              radius: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BoostDrive Pro: ${profile.displayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: palette.title,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'PRO ID: @${profile.uid.length >= 8 ? profile.uid.substring(0, 8).toUpperCase() : profile.uid.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardTypography.bodySm(palette),
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
                                border: Border.all(color: palette.background, width: 2),
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
        ),
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
    final palette = DashboardPalette.of(context);
    return MobileCustomerUi.iconActionButton(
      palette: palette,
      icon: icon,
      onTap: () {},
    );
  }

  Widget _buildStatusToggle(WidgetRef ref, String uid) {
    final palette = DashboardPalette.of(context);
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
        return MobileProviderUi.availabilityToggle(
          palette: palette,
          isOnline: isOnline,
          updating: _updatingAvailability,
          onChanged: setAvailability,
          statusHint: isOnline ? '• Live location visible to SOS dispatch' : null,
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildActiveJobMap() {
    final palette = DashboardPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileProviderUi.sectionTitle(palette, 'Active job map'),
        const SizedBox(height: 12),
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MobileProviderUi.radiusCard),
            border: Border.all(
              color: palette.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
            ),
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
                  backgroundColor: palette.primaryContainer,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: palette.surfaceContainerLow.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.navigation, color: palette.tertiary, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'ONE-TAP NAV READY',
                        style: DashboardTypography.labelMd(palette).copyWith(fontWeight: FontWeight.w800),
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
    final palette = DashboardPalette.of(context);
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
            Expanded(
              child: MobileProviderUi.compactStatCard(
                palette: palette,
                label: 'Earnings',
                value: '\$${profile.totalEarnings.toStringAsFixed(0)}',
                subtext: 'Lifetime',
                subtextColor: palette.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MobileProviderUi.compactStatCard(
                palette: palette,
                label: 'Jobs',
                value: jobsLabel,
                subtext: 'Completed',
                subtextColor: palette.primaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MobileProviderUi.compactStatCard(
                palette: palette,
                label: 'Rating',
                value: '—',
                subtext: 'No reviews yet',
                subtextColor: palette.muted,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildLiveRequests(WidgetRef ref) {
    final palette = DashboardPalette.of(context);
    final uid = ref.watch(currentUserProvider)?.id;
    final providerTypes = uid != null
        ? (ref.watch(userProfileProvider(uid)).valueOrNull?.providerServiceTypes ?? const <String>[])
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileProviderUi.sectionHeader(
          palette: palette,
          title: 'Live SOS alerts',
          trailing: TextButton(
            onPressed: () {},
            child: Text(
              'HISTORY',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.primaryContainer,
              ),
            ),
          ),
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
              return MobileProviderUi.emptyStateCard(
                palette: palette,
                message:
                    'Add service types in Account → Profile so you only see SOS requests you can fulfill.',
                icon: Icons.tune,
              );
            }

            if (filtered.isEmpty) {
              return MobileProviderUi.emptyStateCard(
                palette: palette,
                message:
                    'No pending SOS requests match your services (${providerTypes.join(", ")}).',
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
    final palette = DashboardPalette.of(context);
    final tag = 'SOS — ${request.type.toUpperCase()}';
    final title = request.userNote.isNotEmpty ? request.userNote : 'No notes provided';
    final userLine = 'Customer ID: ${request.userId.length >= 8 ? request.userId.substring(0, 8) : request.userId}';
    final critical = request.type.toLowerCase() == 'towing';
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

    return MobileProviderUi.glassOrderCard(
      palette: palette,
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
                      MobileProviderUi.urgencyBadge(
                        palette: palette,
                        label: tag,
                        critical: critical,
                      ),
                      Text(
                        distanceLabel,
                        style: GoogleFonts.manrope(
                          color: palette.primaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: palette.title,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(userLine, style: DashboardTypography.bodySm(palette)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.touch_app, size: 16, color: palette.primaryContainer),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tap to open — customer sees you are responding (before you accept).',
                          style: DashboardTypography.bodySm(palette).copyWith(height: 1.25),
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
                child: MobileProviderUi.outlineButton(
                  palette: palette,
                  label: 'OPEN REQUEST',
                  onPressed: requestId.isEmpty ? null : openDetail,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MobileProviderUi.primaryButton(
                  palette: palette,
                  label: 'ACCEPT',
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressJobs(WidgetRef ref, String uid) {
    final palette = DashboardPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileProviderUi.sectionHeader(palette: palette, title: 'Ongoing fulfillment'),
        const SizedBox(height: 16),
        ref.watch(providerAssignedRequestsProvider(uid)).when(
              data: (list) {
                if (list.isEmpty) {
                  return MobileProviderUi.emptyStateCard(
                    palette: palette,
                    message: 'No ongoing jobs',
                    icon: Icons.assignment_outlined,
                  );
                }
                return Column(
                  children: list.map((r) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(MobileProviderUi.radiusCard),
                          onTap: r.id.isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(builder: (_) => SosRequestDetailPage(request: r)),
                                  );
                                },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: MobileProviderUi.premiumCard(palette),
                            child: Row(
                              children: [
                                Icon(Icons.local_shipping, color: palette.primaryContainer, size: 28),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.userNote.isNotEmpty ? r.userNote : 'SOS — ${r.type.toUpperCase()}',
                                        style: GoogleFonts.manrope(
                                          color: palette.title,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Status: ${r.status}',
                                        style: DashboardTypography.bodySm(palette),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: palette.muted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: palette.primaryContainer),
                ),
              ),
              error: (e, _) => Text('Could not load jobs: $e', style: TextStyle(color: palette.error)),
            ),
      ],
    );
  }

  Widget _buildActiveServicesSection(WidgetRef ref, String uid) {
    final palette = DashboardPalette.of(context);
    final catalogAsync = ref.watch(_dashboardProviderServicesFamily(uid));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileProviderUi.sectionHeader(palette: palette, title: 'Active services'),
        const SizedBox(height: 16),
        catalogAsync.when(
              data: (rows) {
                final activeRows = rows.where((r) => r['is_active'] != false).toList();
                if (activeRows.isEmpty) {
                  return MobileProviderUi.emptyStateCard(
                    palette: palette,
                    message: 'No services listed. Add services in the Services tab to show them here.',
                    icon: Icons.settings_outlined,
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
                        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: palette.primaryContainer.withValues(alpha: 0.12),
                      side: BorderSide(color: palette.primaryContainer.withValues(alpha: 0.35)),
                      labelStyle: TextStyle(color: palette.title),
                    );
                  }).toList(),
                );
              },
              loading: () => Center(child: CircularProgressIndicator(color: palette.primaryContainer, strokeWidth: 2)),
              error: (e, _) => Text(
                'Could not load services: $e',
                style: TextStyle(color: palette.error, fontSize: 12),
              ),
            ),
      ],
    );
  }

  Widget _buildIncomingJobCardRequests(WidgetRef ref, String providerId) {
    final palette = DashboardPalette.of(context);
    final asyncCards = ref.watch(_incomingProviderJobCardsFamily(providerId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileProviderUi.sectionHeader(palette: palette, title: 'Customer job card requests'),
        const SizedBox(height: 12),
        asyncCards.when(
          data: (rows) {
            if (rows.isEmpty) {
              return MobileProviderUi.emptyStateCard(
                palette: palette,
                message: 'No new job card requests yet.',
              );
            }
            final visible = rows.take(3).toList();
            return Column(
              children: visible.map((row) {
                final status = (row['status']?.toString() ?? 'submitted').toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MobileJobCardUi.providerTile(
                    palette: palette,
                    row: row,
                    onRespond: status == 'submitted'
                        ? () async {
                            final amount = await _promptProviderQuote(context);
                            if (amount == null) return;
                            try {
                              await ref.read(jobCardServiceProvider).providerQuoteJobCard(
                                    jobCardId: row['id'].toString(),
                                    providerId: providerId,
                                    quotedLaborAmount: amount,
                                  );
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
                          }
                        : null,
                    onOpen: () {},
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
    final palette = DashboardPalette.of(context);
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => MobileJobCardUi.dialogShell(
        palette: palette,
        title: 'Respond with labor quote',
        subtitle: 'Enter your labor amount for this job card.',
        children: [
          MobileJobCardUi.themedTextField(
            palette: palette,
            controller: c,
            label: 'Labor amount (N\$)',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        actions: [
          MobileJobCardUi.cancelTextButton(palette: palette, onPressed: () => Navigator.pop(ctx, false)),
          MobileJobCardUi.primaryDialogButton(label: 'SEND QUOTE', onPressed: () => Navigator.pop(ctx, true)),
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
