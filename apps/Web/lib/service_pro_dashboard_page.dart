import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'suspension_overlay.dart';
import 'add_staff_page.dart';
import 'user_support_view.dart';
import 'boostdrive_banner.dart';
import 'boostdrive_banner.dart';

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

    final profileAsync = ref.watch(userProfileProvider(user.id));
    final isSuspended = profileAsync.when(
      data: (p) => p != null && (p.status == 'suspended' || p.status == 'banned'),
      loading: () => false,
      error: (_, __) => false,
    );

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final alertsAsync = ref.watch(activeDashboardAlertsStreamProvider(user.id));
                    return alertsAsync.when(
                      data: (alerts) {
                        if (alerts.isEmpty) return const SizedBox.shrink();
                        return BoostDriveBanner(
                          alert: alerts.first,
                          onAction: (ticketId) {
                            ref.read(pendingSupportTicketIdProvider.notifier).state = ticketId;
                            setState(() => _currentSection = 'SUPPORT');
                          },
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
                _buildProHeader(ref, user.id),
                const SizedBox(height: 32),
                _buildTopNavBar(),
                const SizedBox(height: 48),
                _buildSectionContent(user.id),
              ],
            ),
          ),
          if (isSuspended)
            Positioned.fill(
              child: SuspensionOverlay(
                reason: profileAsync.valueOrNull?.suspensionReason,
              ),
            ),
        ],
      ),
    );
  }

  /// Helper to get a human-readable specialization label for the dashboard header.
  String _getCategoryLabel(UserProfile profile) {
    final cat = profile.primaryServiceCategory?.toLowerCase();
    if (cat == 'mechanic') return 'Mechanic';
    if (cat == 'towing') return 'Towing Service';
    if (cat == 'parts') return 'Parts Supplier';
    
    // Fallback to role or capitalization
    if (cat != null && cat.isNotEmpty) {
      return cat[0].toUpperCase() + cat.substring(1).replaceAll('_', ' ');
    }
    return profile.role == 'service_provider' ? 'Service Provider' : profile.role;
  }

  static String _navLabel(String section) {
    if (section == 'REQUESTS') return 'SERVICES REQUESTED';
    return section;
  }

  Widget _buildTopNavBar() {
    // Services requested (REQUESTS/SOS) only on mobile; hidden on web
    final sections = kIsWeb
        ? ['HOME', 'ROUTES', 'FLEET', 'SUPPORT']
        : ['HOME', 'REQUESTS', 'ROUTES', 'FLEET', 'FINANCE', 'SUPPORT'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF000000), // Darker shade for the nav bar
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: sections.map((section) {
            final isActive = _currentSection == section;
            IconData icon;
            switch (section) {
              case 'HOME': icon = Icons.grid_view_rounded; break;
              case 'REQUESTS': icon = Icons.emergency_outlined; break;
              case 'ROUTES': icon = Icons.map_outlined; break;
              case 'FLEET': icon = Icons.local_shipping_outlined; break;
              case 'FINANCE': icon = Icons.account_balance_wallet_outlined; break;
              case 'SUPPORT': icon = Icons.support_agent; break;
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
                    Icon(icon, color: isActive ? BoostDriveTheme.primaryColor : Color(0x22FF6600), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _navLabel(section),
                      style: TextStyle(
                        color: isActive ? Colors.white : Color(0x22FF6600),
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
    if (_currentSection == 'REQUESTS') {
      if (kIsWeb) return _buildSosMobileOnlyMessage();
      return _buildIncomingRequestsSection(userId);
    }
    if (_currentSection == 'ROUTES') {
      return _buildRoutesSection();
    }
    if (_currentSection == 'FLEET') {
      return _buildFleetSection(userId);
    }
    if (_currentSection == 'SUPPORT') {
      return UserSupportView(userId: userId, userType: 'service_provider');
    }

    if (_currentSection != 'HOME') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(80.0),
          child: Column(
            children: [
              Icon(Icons.construction, size: 64, color: BoostDriveTheme.primaryColor.withValues(alpha: 0.5)),
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

  /// Shown on web when SOS is requested; SOS is mobile-only.
  Widget _buildSosMobileOnlyMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android, size: 64, color: BoostDriveTheme.primaryColor.withValues(alpha: 0.6)),
            const SizedBox(height: 24),
            Text(
              'SOS requests are managed on the BoostDrive mobile app',
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Use the mobile app to view and accept incoming roadside and mechanic requests.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequestsSection(String userId) {
    final pendingAsync = ref.watch(globalActiveSosRequestsProvider);
    final myAssignedAsync = ref.watch(providerAssignedRequestsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Incoming SOS requests', Icons.emergency),
        const SizedBox(height: 8),
        Text(
          'Accept pending requests from customers needing roadside or mechanic help. Requests you accept appear under My assignments.',
          style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 14),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final pendingSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending (awaiting provider)', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 12),
                pendingAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Center(
                          child: Text('No pending requests right now.', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 14)),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: list.map<Widget>((r) => _buildSosRequestCard(r, pending: true, userId: userId)).toList(),
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor))),
                  error: (e, _) => Text('Could not load: $e', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                ),
              ],
            );
            final assignedSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My assignments', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 12),
                myAssignedAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Center(
                          child: Text('No assignments yet. Accept a request above.', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 14)),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: list.map<Widget>((r) => _buildSosRequestCard(r, pending: false, userId: userId)).toList(),
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor))),
                  error: (e, _) => Text('Could not load: $e', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                ),
              ],
            );
            if (constraints.maxWidth < 700) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  pendingSection,
                  const SizedBox(height: 24),
                  assignedSection,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: pendingSection),
                const SizedBox(width: 24),
                Expanded(child: assignedSection),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSosRequestCard(SosRequest r, {required bool pending, required String userId}) {
    final id = r.id;
    final type = r.type;
    final status = r.status;
    final userNote = r.userNote;
    final lat = r.lat;
    final lng = r.lng;
    final createdAt = r.createdAt.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: BoostDriveTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(type.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              const Spacer(),
              if (pending)
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(sosServiceProvider).acceptRequest(id, userId);
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
                  icon: const Icon(Icons.check_circle, size: 18, color: BoostDriveTheme.primaryColor),
                  label: const Text('Accept'),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status.toUpperCase(), style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          if (userNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(userNote, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (lat != 0.0 && lng != 0.0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Location: $lat, $lng', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11)),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(createdAt.length > 16 ? createdAt.substring(0, 16) : createdAt, style: TextStyle(color: Colors.white54, fontSize: 11)),
          ),
        ],
      ),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                    color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DISPATCH OVERVIEW', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 12)),
                      const SizedBox(height: 16),
                      _buildMapStat('Active Mechanics', '0'),
                      if (!kIsWeb) ...[
                        const SizedBox(height: 12),
                        _buildMapStat('Pending SOS', '0'),
                      ],
                      const SizedBox(height: 12),
                      _buildMapStat('Avg Response', '—'),
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

  Widget _buildFleetSection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Staff & Fleet Management', Icons.people),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add Staff feature coming soon!'),
                    backgroundColor: BoostDriveTheme.primaryColor,
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('ADD STAFF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                 backgroundColor: BoostDriveTheme.primaryColor,
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildStaffList(userId),
      ],
    );
  }

  Widget _buildStaffList(String providerId) {
    final staffAsync = ref.watch(providerStaffProvider(providerId));
    return staffAsync.when(
      data: (staff) {
        if (staff.isEmpty) return _buildStaffEmpty();
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 180, 
              ),
              itemCount: staff.length,
              itemBuilder: (context, index) {
                 final s = staff[index];
                 return _buildStaffCard(s);
              },
            );
          }
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor))),
      error: (err, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Failed to load staff list. Please try again.', style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.8)))),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: BoostDriveTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['full_name'] ?? 'Unknown Staff',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff['staff_role'] ?? 'Role not assigned',
                      style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEditStaffDialog(staff),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _handleDeleteStaff(staff['staff_user_id']),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Divider(color: Color(0x22FF6600)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: Colors.white54),
              const SizedBox(width: 8),
              Text(staff['phone_number'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.email, size: 14, color: Colors.white54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  staff['email'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: BoostDriveTheme.textDim),
            const SizedBox(height: 16),
            Text(
              'No staff added yet',
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Add staff to manage fleet and assignments',
              style: TextStyle(color: BoostDriveTheme.textDim.withValues(alpha: 0.8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStatusToggle(WidgetRef ref, String uid) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        final isOnline = profile.isOnline;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toggleItem(ref, profile, 'ONLINE', isOnline, Colors.green),
              _toggleItem(ref, profile, 'OFFLINE', !isOnline, Color(0x22FF6600)),
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
                color: active ? Colors.white : Color(0x22FF6600),
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
            _buildProfileIcon(ref, uid),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'BoostDrive Pro: ${profile.displayName}',
                          style: TextStyle(fontFamily: 'Manrope', 
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.verificationStatus.toLowerCase() == 'approved') ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: BoostDriveTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: BoostDriveTheme.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'VERIFIED',
                                style: TextStyle(
                                  color: BoostDriveTheme.primaryColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Expert ${_getCategoryLabel(profile)} • Primary Service Provider',
                    style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            _buildNotificationBell(ref, uid),
            const SizedBox(width: 32),
            _buildStatBox('TOTAL EARNINGS', '\$${profile.totalEarnings.toStringAsFixed(2)}', 'LIFETIME'),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text('Error loading profile'),
    );
  }

  Widget _buildProfileIcon(WidgetRef ref, String uid) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final hasImage = profile.profileImg.isNotEmpty;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsPage())),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white24,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: BoostDriveTheme.surfaceDark,
                backgroundImage: hasImage ? NetworkImage(profile.profileImg) : null,
                child: !hasImage
                    ? const Icon(Icons.person, color: Colors.white, size: 32)
                    : null,
              ),
            ),
          ),
        );
      },
      loading: () => const CircleAvatar(radius: 36, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const CircleAvatar(radius: 36, child: Icon(Icons.error_outline, color: Colors.red)),
    );
  }

  Widget _buildStatBox(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
        _buildOngoingJobsEmpty(),
        const SizedBox(height: 40),
        _buildSectionHeader('Active Services', Icons.settings_outlined),
        const SizedBox(height: 24),
        _buildActiveServicesEmpty(),
      ],
    );
  }

  Widget _buildActiveServicesEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_outlined, size: 48, color: BoostDriveTheme.textDim),
            const SizedBox(height: 16),
            Text(
              'No active services',
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Services you offer will appear here when added.',
              style: TextStyle(color: BoostDriveTheme.textDim.withValues(alpha: 0.8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingJobsEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: BoostDriveTheme.textDim),
            const SizedBox(height: 16),
            Text(
              'No ongoing jobs',
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
            ),
          ],
        ),
      ),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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

  // ignore: unused_element
  Widget _buildOngoingJobCard(String title, String car, String status, double progress) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(car, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16)),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
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

  Widget _buildNotificationBell(WidgetRef ref, String uid) {
    final notificationsAsync = ref.watch(userNotificationsStreamProvider(uid));
    
    return notificationsAsync.when(
      data: (list) {
        final unreadCount = list.where((n) => n['is_read'] == false).length;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => NotificationsOverlay(
                    onNotificationTap: (type, id) {
                      if (type == 'support') {
                        ref.read(pendingSupportTicketIdProvider.notifier).state = id;
                        setState(() => _currentSection = 'SUPPORT');
                      }
                    },
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => IconButton(
        icon: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        onPressed: () => _showNotificationsOverlay(uid),
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.notifications_off, color: Colors.white70),
        onPressed: () => _showNotificationsOverlay(uid),
      ),
    );
  }

  void _showNotificationsOverlay(String uid) {
    showDialog(
      context: context,
      builder: (context) => NotificationsOverlay(
        onNotificationTap: (type, id) {
          if (type == 'support') {
            ref.read(pendingSupportTicketIdProvider.notifier).state = id;
            setState(() => _currentSection = 'SUPPORT');
          }
        },
      ),
    );
  }



  Future<void> _handleDeleteStaff(String staffUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Delete Staff Member?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove the employee from your fleet. This action cannot be undone.',
          style: TextStyle(color: BoostDriveTheme.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('provider_staff')
            .delete()
            .eq('staff_user_id', staffUserId);
        
        // Force immediate refresh of the stream
        final providerId = ref.read(currentUserProvider)?.id;
        if (providerId != null) {
          ref.invalidate(providerStaffProvider(providerId));
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff member removed successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  Future<void> _showEditStaffDialog(Map<String, dynamic> staff) async {
    final nameController = TextEditingController(text: staff['full_name']);
    final staffIdController = TextEditingController(text: staff['staff_internal_id'] ?? '');
    final phoneController = TextEditingController(text: staff['phone_number'] ?? '');
    
    String selectedRole = staff['staff_role'] ?? 'Mechanic';
    final List<String> roleOptions = ['Mechanic', 'Lead Mechanic', 'Technician', 'Driver', 'Dispatcher'];

    bool canViewFleet = staff['can_view_fleet'] ?? false;
    bool canAcceptSos = staff['can_accept_sos'] ?? false;
    bool canViewFinance = staff['can_view_finance'] ?? false;
    
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161A23),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Edit Staff Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('PROFILE DETAILS', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12)),
                    const SizedBox(height: 16),
                    _buildEditField(nameController, 'Full Legal Name', Icons.person_outline),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: BoostDriveTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          dropdownColor: BoostDriveTheme.surfaceDark,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          onChanged: (String? newValue) {
                            if (newValue != null) setDialogState(() => selectedRole = newValue);
                          },
                          items: roleOptions.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEditField(staffIdController, 'Staff ID (Optional)', Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _buildEditField(phoneController, 'Phone Number', Icons.phone_outlined),
                    
                    const SizedBox(height: 24),
                    const Text('PERMISSIONS', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12)),
                    const SizedBox(height: 12),
                    _buildEditToggleRow('View Fleet', canViewFleet, (val) => setDialogState(() => canViewFleet = val)),
                    _buildEditToggleRow('Accept SOS', canAcceptSos, (val) => setDialogState(() => canAcceptSos = val)),
                    _buildEditToggleRow('Financial Access', canViewFinance, (val) => setDialogState(() => canViewFinance = val)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setDialogState(() => isSaving = true);
                    try {
                      await Supabase.instance.client
                          .from('provider_staff')
                          .update({
                            'full_name': nameController.text.trim(),
                            'staff_role': selectedRole,
                            'staff_internal_id': staffIdController.text.trim().isEmpty ? null : staffIdController.text.trim(),
                            'phone_number': phoneController.text.trim(),
                            'can_view_fleet': canViewFleet,
                            'can_accept_sos': canAcceptSos,
                            'can_view_finance': canViewFinance,
                          })
                          .eq('staff_user_id', staff['staff_user_id']);
                      
                      // Force immediate refresh of the stream
                      final providerId = ref.read(currentUserProvider)?.id;
                      if (providerId != null) {
                        ref.invalidate(providerStaffProvider(providerId));
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Staff updated successfully'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoostDriveTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEditField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x22FF6600), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: BoostDriveTheme.surfaceDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildEditToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: BoostDriveTheme.primaryColor,
        ),
      ],
    );
  }
}
