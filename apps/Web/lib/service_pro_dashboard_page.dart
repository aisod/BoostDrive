import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceProDashboardPage extends ConsumerStatefulWidget {
  const ServiceProDashboardPage({super.key});

  @override
  ConsumerState<ServiceProDashboardPage> createState() => _ServiceProDashboardPageState();
}

class _ServiceProDashboardPageState extends ConsumerState<ServiceProDashboardPage> {
  String _currentSection = 'HOME';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: Text('Please log in'));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProHeader(ref, user.id),
          const SizedBox(height: 32),
          _buildTopNavBar(),
          const SizedBox(height: 48),
          _buildSectionContent(user.id),
        ],
      ),
    );
  }

  Widget _buildTopNavBar() {
    final sections = ['HOME', 'ROUTES', 'FLEET', 'FINANCE'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF101828), // Darker shade for the nav bar
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: sections.map((section) {
            final isActive = _currentSection == section;
            IconData icon;
            switch (section) {
              case 'HOME': icon = Icons.grid_view_rounded; break;
              case 'ROUTES': icon = Icons.map_outlined; break;
              case 'FLEET': icon = Icons.local_shipping_outlined; break;
              case 'FINANCE': icon = Icons.account_balance_wallet_outlined; break;
              default: icon = Icons.help_outline;
            }
            return InkWell(
              onTap: () => setState(() => _currentSection = section),
              borderRadius: BorderRadius.circular(12),
              mouseCursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? BoostDriveTheme.surfaceDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: isActive ? BoostDriveTheme.primaryColor : Colors.white24, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      section,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white24,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionContent(String userId) {
    if (_currentSection == 'ROUTES') {
      return _buildRoutesSection();
    }
    
    if (_currentSection == 'FLEET') {
      return _buildFleetSection();
    }

    if (_currentSection != 'HOME') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(80.0),
          child: Column(
            children: [
              Icon(Icons.construction, size: 64, color: BoostDriveTheme.primaryColor.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text(
                '$_currentSection feature coming soon',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1000;
        return Column(
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildMainContent()),
                  const SizedBox(width: 40),
                  Expanded(flex: 1, child: _buildSideContent()),
                ],
              )
            else
              Column(
                children: [
                  _buildMainContent(),
                  const SizedBox(height: 40),
                  _buildSideContent(),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildRoutesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Active Dispatch Map', Icons.map),
        const SizedBox(height: 24),
        Container(
          height: 600,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-22.5609, 17.0658),
                  zoom: 13,
                ),
                style: _mapStyle,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
              ),
              Positioned(
                top: 32,
                left: 32,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.backgroundDark.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DISPATCH OVERVIEW', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 12)),
                      const SizedBox(height: 16),
                      _buildMapStat('Active Mechanics', '12'),
                      const SizedBox(height: 12),
                      _buildMapStat('Pending SOS', '4'),
                      const SizedBox(height: 12),
                      _buildMapStat('Avg Response', '8m'),
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

  Widget _buildMapStat(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildFleetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Staff & Fleet Management', Icons.people),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('ADD STAFF'),
              style: ElevatedButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1.5,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => _buildStaffCard(index),
        ),
      ],
    );
  }

  Widget _buildStaffCard(int index) {
    final names = ['Klaus M.', 'Sarah J.', 'Petrus T.', 'David W.', 'Maria K.', 'John S.'];
    final status = index % 3 == 0 ? 'ON JOB' : (index % 2 == 0 ? 'AVAILABLE' : 'OFFLINE');
    final color = status == 'ON JOB' ? Colors.amber : (status == 'AVAILABLE' ? Colors.green : Colors.white24);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 20, backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white24)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(names[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Mobile Mechanic', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const Spacer(),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today\'s Jobs: 4', style: TextStyle(color: Colors.white70, fontSize: 12)),
              TextButton(onPressed: () {}, child: const Text('ASSIGN', style: TextStyle(fontSize: 12))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(WidgetRef ref, String uid) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        final isOnline = profile.isOnline;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toggleItem(ref, profile, 'ONLINE', isOnline, Colors.green),
              _toggleItem(ref, profile, 'OFFLINE', !isOnline, Colors.white24),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _toggleItem(WidgetRef ref, UserProfile profile, String label, bool active, Color color) {
    return GestureDetector(
      onTap: () {
        ref.read(userServiceProvider).updateProfile(
          profile.copyWith(isOnline: label == 'ONLINE'),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? BoostDriveTheme.surfaceDark : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: active ? color : Colors.transparent, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProHeader(WidgetRef ref, String uid) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BoostDrive Pro: ${profile.fullName}',
                  style: GoogleFonts.manrope(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Expert Mechanic • Primary Service Provider',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 18),
                ),
              ],
            ),
            const Spacer(),
            _buildStatBox('TOTAL EARNINGS', '\$${profile.totalEarnings.toStringAsFixed(2)}', 'LIFETIME'),
            const SizedBox(width: 24),
            _buildStatBox('LOYALTY POINTS', profile.loyaltyPoints.toString(), 'REDEEMABLE'),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text('Error loading profile'),
    );
  }

  Widget _buildStatBox(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Ongoing Jobs', Icons.assignment_ind),
        const SizedBox(height: 24),
        _buildOngoingJobCard(
          'Transmission Inspection',
          'Ford F-150 • #BTL-9021',
          'In Progress - Diagnostic Phase',
          0.4,
        ),
      ],
    );
  }

  Widget _buildSideContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Service Map', Icons.map),
        const SizedBox(height: 24),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-22.5609, 17.0658),
              zoom: 13,
            ),
            style: _mapStyle,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),
        const SizedBox(height: 40),
        _buildSectionHeader('Parts Link™', Icons.shopping_cart),
        const SizedBox(height: 24),
        _buildPartsLinkPromo(),
      ],
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: BoostDriveTheme.primaryColor, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildOngoingJobCard(String title, String car, String status, double progress) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(car, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16)),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: const AlwaysStoppedAnimation(BoostDriveTheme.primaryColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Text(status, style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPartsLinkPromo() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BoostDriveTheme.primaryColor.withOpacity(0.2), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: BoostDriveTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NEED PARTS?', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 12),
          const Text('Instantly link parts from our marketplace directly to your service ticket.', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () {}, child: const Text('Generate Parts Link')),
        ],
      ),
    );
  }
}
