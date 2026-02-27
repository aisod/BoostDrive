import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'providers.dart';

class ServiceProDashboard extends ConsumerStatefulWidget {
  const ServiceProDashboard({super.key});

  @override
  ConsumerState<ServiceProDashboard> createState() => _ServiceProDashboardState();
}

class _ServiceProDashboardState extends ConsumerState<ServiceProDashboard> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initLocation();
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(ref, user.id),
            const SizedBox(height: 24),
            _buildStatusToggle(ref, user.id),
            const SizedBox(height: 24),
            _buildActiveJobMap(),
            const SizedBox(height: 24),
            _buildStatsRow(ref, user.id),
            const SizedBox(height: 32),
            _buildLiveRequests(ref),
            const SizedBox(height: 32),
            _buildInProgressJobs(),
            const SizedBox(height: 32),
            _buildJobCardTool(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, String uid) {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'PRO ID: @${profile.uid.substring(0, 8).toUpperCase()}',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            _buildHeaderIcon(Icons.notifications_none_rounded, hasNotification: true),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text('Error loading header'),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {bool hasNotification = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        if (hasNotification)
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
  }

  Widget _buildStatusToggle(WidgetRef ref, String uid) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        final isOnline = profile.isOnline;
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
                color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(userServiceProvider).updateProfile(profile.copyWith(isOnline: true));
                      },
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
                      onTap: () {
                        ref.read(userServiceProvider).updateProfile(profile.copyWith(isOnline: false));
                      },
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
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? const LatLng(-22.5609, 17.0658),
                  zoom: 14,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                style: _mapStyle,
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
                    color: BoostDriveTheme.backgroundDark.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
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
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return Row(
          children: [
            Expanded(child: _buildStatCard('Earnings', '\$${profile.totalEarnings.toStringAsFixed(0)}', 'LIFETIME', true)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Jobs', '42', 'COMPLETED', false)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Rating', '4.9', 'EXPERT', false)),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildStatCard(String label, String value, String subtext, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
              color: isPositive ? Colors.green : BoostDriveTheme.primaryColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRequests(WidgetRef ref) {
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
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: ref.watch(sosServiceProvider).getGlobalActiveRequests(),
          builder: (context, snapshot) {
            final requests = snapshot.data ?? [];
            if (requests.isEmpty) return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Center(
                child: Text('Scanning for nearby requests...', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13, fontStyle: FontStyle.italic)),
              ),
            );
            return Column(
              children: requests.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRequestCard(
                  tag: 'SOS - ${req['type']?.toString().toUpperCase() ?? 'EMERGENCY'}',
                  distance: '2.4 KM AWAY',
                  title: req['user_note'] ?? 'No notes provided',
                  user: 'Customer ID: ${req['user_id']?.toString().substring(0, 8)}',
                  tagColor: req['type'] == 'emergency' ? Colors.redAccent : Colors.blueAccent,
                  requestId: req['id'],
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequestCard({
    required String tag,
    required String distance,
    required String title,
    required String user,
    required Color tagColor,
    required String requestId,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tagColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              Text(distance, style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(user, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Accept logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoostDriveTheme.primaryColor,
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('ACCEPT REQUEST', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Center(child: Text('15s', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressJobs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ONGOING FULFILLMENT',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.navigation, color: Colors.blueAccent, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'EN ROUTE',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const Text('ETA: 6 MIN', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Transmission Diagnostic',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Marcus Wright • Ford F-150',
                style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.directions),
                      label: const Text('NAVIGATE'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildHeaderIcon(Icons.phone),
                  const SizedBox(width: 12),
                  _buildHeaderIcon(Icons.chat_bubble_outline),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobCardTool() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BoostDriveTheme.primaryColor, Colors.orange.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: BoostDriveTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Job Card & Diagnostics',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Icon(Icons.assignment, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Create digital job cards and push required parts directly to the customer\'s cart.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: BoostDriveTheme.primaryColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('OPEN JOB CARD TOOL', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
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
}
