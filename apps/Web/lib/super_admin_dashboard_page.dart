import 'package:flutter/foundation.dart' show kIsWeb; // summary-fix-touch
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:google_fonts/google_fonts.dart';

// Import shop home if needed to log out
import 'package:boost_drive_web/shop_home_page.dart';
import 'package:boost_drive_web/verification_queue_view.dart';
import 'package:boost_drive_web/service_monitoring_view.dart';
import 'package:boost_drive_web/user_management_view.dart';
import 'package:boost_drive_web/admin_profile_view.dart';
import 'package:boost_drive_web/financials_view.dart';
import 'admin_states.dart';

class SuperAdminDashboardPage extends ConsumerStatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  ConsumerState<SuperAdminDashboardPage> createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends ConsumerState<SuperAdminDashboardPage> {
  int _selectedIndex = 0;

  static List<_AdminAlert> _buildDynamicAlerts({
    required int pendingVerifications,
    required int activeSos,
    required int userBase,
    required double marketplaceVol,
  }) {
    final alerts = <_AdminAlert>[];

    if (pendingVerifications > 0) {
      alerts.add(_AdminAlert(
        tag: 'URGENT',
        color: Colors.orange,
        message: '$pendingVerifications provider${pendingVerifications == 1 ? '' : 's'} pending verification.',
      ));
    }

    if (activeSos > 0) {
      alerts.add(_AdminAlert(
        tag: 'URGENT',
        color: Colors.redAccent,
        message: '$activeSos active SOS request${activeSos == 1 ? '' : 's'} in progress.',
      ));
    }

    if (userBase == 0) {
      alerts.add(_AdminAlert(
        tag: 'INFO',
        color: BoostDriveTheme.primaryColor,
        message: 'User base is currently 0. Verify auth + profiles sync.',
      ));
    }

    if (marketplaceVol <= 0) {
      alerts.add(_AdminAlert(
        tag: 'INFO',
        color: BoostDriveTheme.primaryColor,
        message: 'Marketplace volume is 0. Verify orders/payments pipeline.',
      ));
    }

    if (alerts.isEmpty) {
      alerts.add(_AdminAlert(
        tag: 'OK',
        color: Colors.green,
        message: 'No critical alerts at the moment.',
      ));
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;
          return Row(
            children: [
              // Sidebar (only if not too narrow)
              if (!isNarrow) _buildSidebar(context),
              // Main Content
              Expanded(
                child: _buildMainContent(ref, user.id, isNarrow: isNarrow),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Brand Header
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.centerLeft,
            child: Text(
              'BoostDrive Admin',
              style: TextStyle(fontFamily: 'Manrope', 
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: BoostDriveTheme.primaryColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 16),
          _buildNavItem(0, Icons.dashboard_outlined, 'Dashboard'),
          _buildNavItem(1, Icons.verified_user_outlined, 'Verification Queue'),
          _buildNavItem(2, Icons.map_outlined, 'Service Monitoring'),
          _buildNavItem(3, Icons.people_outline, 'User Management'),
          _buildNavItem(4, Icons.attach_money_outlined, 'Financials'),
          _buildNavItem(5, Icons.account_circle_outlined, 'Admin Profile'),
          const Spacer(),
          const Divider(height: 1, color: Colors.black12),
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? BoostDriveTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: isSelected ? BoostDriveTheme.primaryColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? BoostDriveTheme.primaryColor : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? BoostDriveTheme.primaryColor : Colors.black87,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return InkWell(
      onTap: () {
        ref.read(authServiceProvider).signOut();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ShopHomePage()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            const SizedBox(width: 16),
            const Text(
              'Log Out',
              style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(WidgetRef ref, String uid, {required bool isNarrow}) {
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = _buildDashboardContent(ref, uid, isNarrow: isNarrow);
        break;
      case 1:
        content = const VerificationQueueView();
        break;
      case 2:
        content = const ServiceMonitoringView();
        break;
      case 3:
        content = const UserManagementView();
        break;
      case 4:
        content = const FinancialsView();
        break;
      case 5:
        content = AdminProfileView(uid: uid);
        break;
      default:
        content = const Center(child: Text('Select a module'));
    }

    final selectedGroup = ref.watch(adminUserGroupProvider);

    return Column(
      children: [
        // Top Bar
        Container(
          height: 70,
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 32),
          child: Row(
            children: [
              if (_selectedIndex == 3 && selectedGroup != null) ...[
                IconButton(
                  onPressed: () => ref.read(adminUserGroupProvider.notifier).state = null,
                  icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                  tooltip: 'Go back to Selection',
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  _getSectionTitle(selectedGroup),
                  style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: isNarrow ? 16 : 20, 
                    fontWeight: FontWeight.w800, 
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              _buildAdminHeader(ref, uid, isNarrow: isNarrow),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.black12),
        // Main Content Region
        Expanded(
          child: _selectedIndex == 4
              ? content // FinancialsView handles its own padding & scrolling
              : Padding(
                  padding: EdgeInsets.all(isNarrow ? 16 : 32),
                  child: content,
                ),
        ),
      ],
    );
  }

  String _getSectionTitle(AdminUserGroup? selectedGroup) {
    switch (_selectedIndex) {
      case 0: return 'System Health & Overview';
      case 1: return 'Verification Queue (Priority #1)';
      case 2: return 'Service Monitoring';
      case 3: 
        if (selectedGroup == AdminUserGroup.provider) return 'Service Providers';
        if (selectedGroup == AdminUserGroup.customerSeller) return 'Customers & Sellers';
        if (selectedGroup == AdminUserGroup.admin) return 'Admins';
        return 'User Management';
      case 4:
        return 'Financials';
      case 5:
        return 'Admin Profile';
      default:
        return 'Admin';
    }
  }

  // ==== Dashboard Modules from previous design, updated for light mode ====
  Widget _buildDashboardContent(WidgetRef ref, String uid, {required bool isNarrow}) {
    final pendingAsync = ref.watch(pendingVerificationsProvider);
    final sosAsync = ref.watch(globalActiveSosRequestsProvider);
    final volumeAsync = ref.watch(globalVolumeProvider);
    final userCountAsync = ref.watch(userCountProvider);

    // Scrollable to avoid bottom overflow on shorter viewports.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPIGrid(
            pendingAsync: pendingAsync,
            sosAsync: sosAsync,
            volumeAsync: volumeAsync,
            userCountAsync: userCountAsync,
            isNarrow: isNarrow,
          ),
          const SizedBox(height: 32),
          if (isNarrow) ...[
            _buildSystemHealthMap(pendingAsync: pendingAsync, sosAsync: sosAsync),
            const SizedBox(height: 24),
            _buildManagementPanel(
              pendingAsync: pendingAsync,
              sosAsync: sosAsync,
              volumeAsync: volumeAsync,
              userCountAsync: userCountAsync,
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildSystemHealthMap(
                    pendingAsync: pendingAsync,
                    sosAsync: sosAsync,
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: _buildManagementPanel(
                    pendingAsync: pendingAsync,
                    sosAsync: sosAsync,
                    volumeAsync: volumeAsync,
                    userCountAsync: userCountAsync,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAdminHeader(WidgetRef ref, String uid, {required bool isNarrow}) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = 5;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (!isNarrow) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.fullName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        'Staff ID: ${profile.uid.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],
                CircleAvatar(
                  backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                  backgroundImage: (profile.profileImg != null && profile.profileImg!.isNotEmpty) 
                      ? NetworkImage(profile.profileImg!) 
                      : null,
                  child: (profile.profileImg == null || profile.profileImg!.isEmpty)
                      ? const Icon(Icons.person, color: BoostDriveTheme.primaryColor)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text('Error loading profile'),
    );
  }

  Widget _buildKPIGrid({
    required AsyncValue<List<UserProfile>> pendingAsync,
    required AsyncValue<List<SosRequest>> sosAsync,
    required AsyncValue<double> volumeAsync,
    required AsyncValue<int> userCountAsync,
    required bool isNarrow,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        double childAspectRatio = 2.5;

        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
          childAspectRatio = 3.5;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
          childAspectRatio = 2.8;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            pendingAsync.when(
              data: (pending) => _buildKPICard(
                'PENDING VERIFICATIONS',
                pending.length.toString(),
                '',
                Colors.orange,
              ),
              loading: () => _buildKPICard('PENDING VERIFICATIONS', '…', '', Colors.orange),
              error: (_, __) => _buildKPICard('PENDING VERIFICATIONS', 'ERR', '', Colors.orange),
            ),
            sosAsync.when(
              data: (data) => _buildKPICard('ACTIVE SOS', data.length.toString(), '', Colors.redAccent),
              loading: () => _buildKPICard('ACTIVE SOS', '…', '', Colors.redAccent),
              error: (_, __) => _buildKPICard('ACTIVE SOS', 'ERR', '', Colors.redAccent),
            ),
            volumeAsync.when(
              data: (data) => _buildKPICard('MARKETPLACE VOL', '\$${data.toStringAsFixed(0)}', 'TOTAL', BoostDriveTheme.primaryColor),
              loading: () => _buildKPICard('MARKETPLACE VOL', '…', 'TOTAL', BoostDriveTheme.primaryColor),
              error: (_, __) => _buildKPICard('MARKETPLACE VOL', 'ERR', 'TOTAL', BoostDriveTheme.primaryColor),
            ),
            userCountAsync.when(
              data: (data) => _buildKPICard('USER BASE', data.toString(), '', Colors.purpleAccent),
              loading: () => _buildKPICard('USER BASE', '…', '', Colors.purpleAccent),
              error: (_, __) => _buildKPICard('USER BASE', 'ERR', '', Colors.purpleAccent),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(String label, String value, String trend, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value, style: const TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (trend.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trend.startsWith('+') ? Colors.green.withValues(alpha: 0.1) : BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(trend, style: TextStyle(color: trend.startsWith('+') ? Colors.green : BoostDriveTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthMap({
    required AsyncValue<List<UserProfile>> pendingAsync,
    required AsyncValue<List<SosRequest>> sosAsync,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operational Overview',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: sosAsync.when(
                data: (requests) {
                  final active = requests.length;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public, color: BoostDriveTheme.primaryColor, size: 80),
                      const SizedBox(height: 16),
                      Text(
                        active == 0 ? 'No active SOS clusters' : '$active active SOS cluster${active == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      pendingAsync.when(
                        data: (pending) => Text(
                          '${pending.length} pending verification${pending.length == 1 ? '' : 's'}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        loading: () => const Text('Loading verifications…', style: TextStyle(color: Colors.black54)),
                        error: (_, __) => const Text('Could not load verifications', style: TextStyle(color: Colors.black54)),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Could not load SOS activity', style: TextStyle(color: Colors.black54)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementPanel({
    required AsyncValue<List<UserProfile>> pendingAsync,
    required AsyncValue<List<SosRequest>> sosAsync,
    required AsyncValue<double> volumeAsync,
    required AsyncValue<int> userCountAsync,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'System Alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  TextButton(onPressed: null, child: const Text('View All')),
                ],
              ),
              const SizedBox(height: 16),
              pendingAsync.when(
                data: (pending) {
                  return sosAsync.when(
                    data: (sos) {
                      return volumeAsync.when(
                        data: (vol) {
                          return userCountAsync.when(
                            data: (users) {
                              final alerts = _buildDynamicAlerts(
                                pendingVerifications: pending.length,
                                activeSos: sos.length,
                                userBase: users,
                                marketplaceVol: vol,
                              );
                              return Column(
                                children: [
                                  for (int i = 0; i < alerts.length; i++) ...[
                                    _buildAlertItem(alerts[i].message, alerts[i].tag, alerts[i].color),
                                    if (i != alerts.length - 1) const SizedBox(height: 12),
                                  ],
                                ],
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.black54)),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.black54)),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.black54)),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(String msg, String tag, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.black87, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildFinancials(WidgetRef ref) {
    // Keep this view dynamic by only showing live provider-backed values.
    final volumeAsync = ref.watch(globalVolumeProvider);
    final userCountAsync = ref.watch(userCountProvider);
    final pendingAsync = ref.watch(pendingVerificationsProvider);
    final sosAsync = ref.watch(globalActiveSosRequestsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Financial Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('Live operational signals (marketplace volume + platform load).', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              volumeAsync.when(
                data: (v) => _buildKPICard('MARKETPLACE VOL', '\$${v.toStringAsFixed(0)}', 'TOTAL', BoostDriveTheme.primaryColor),
                loading: () => _buildKPICard('MARKETPLACE VOL', '…', 'TOTAL', BoostDriveTheme.primaryColor),
                error: (_, __) => _buildKPICard('MARKETPLACE VOL', 'ERR', 'TOTAL', BoostDriveTheme.primaryColor),
              ),
              userCountAsync.when(
                data: (v) => _buildKPICard('USER BASE', v.toString(), '', Colors.purpleAccent),
                loading: () => _buildKPICard('USER BASE', '…', '', Colors.purpleAccent),
                error: (_, __) => _buildKPICard('USER BASE', 'ERR', '', Colors.purpleAccent),
              ),
              pendingAsync.when(
                data: (v) => _buildKPICard('PENDING VERIFICATIONS', v.length.toString(), '', Colors.orange),
                loading: () => _buildKPICard('PENDING VERIFICATIONS', '…', '', Colors.orange),
                error: (_, __) => _buildKPICard('PENDING VERIFICATIONS', 'ERR', '', Colors.orange),
              ),
              sosAsync.when(
                data: (v) => _buildKPICard('ACTIVE SOS', v.length.toString(), '', Colors.redAccent),
                loading: () => _buildKPICard('ACTIVE SOS', '…', '', Colors.redAccent),
                error: (_, __) => _buildKPICard('ACTIVE SOS', 'ERR', '', Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAlert {
  final String message;
  final String tag;
  final Color color;
  const _AdminAlert({required this.message, required this.tag, required this.color});
}
