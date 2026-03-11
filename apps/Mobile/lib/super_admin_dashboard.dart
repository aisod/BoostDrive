import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return PremiumPageLayout(
      showBackground: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(ref, user.id),
              const SizedBox(height: 32),
              _buildKPISection(ref),
              const SizedBox(height: 32),
              _buildSystemHealthMap(ref),
              const SizedBox(height: 32),
              _buildManagementTabs(),
              const SizedBox(height: 32),
              _buildVerificationList(ref),
              const SizedBox(height: 32),
              _buildLogisticsSummary(),
              const SizedBox(height: 120),
            ],
          ),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BoostDriveTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: BoostDriveTheme.primaryColor.withOpacity(0.3)),
              ),
              child: const Icon(Icons.admin_panel_settings, color: BoostDriveTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'BOOSTDRIVE SUPER ADMIN',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text('Error loading header'),
    );
  }

  Widget _buildKPISection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LIVE ECOSYSTEM PERFORMANCE',
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            StreamBuilder<double>(
              stream: ref.watch(deliveryServiceProvider).getGlobalVolume(),
              builder: (context, snapshot) => _buildKPICard('Marketplace Vol', snapshot.hasData ? '\$${snapshot.data!.toStringAsFixed(0)}' : 'Loading...', 'TOTAL', BoostDriveTheme.primaryColor, 0.55),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.watch(sosServiceProvider).getGlobalActiveRequests(),
              builder: (context, snapshot) => _buildKPICard('Active SOS', snapshot.hasData ? snapshot.data!.length.toString() : 'Loading...', 'LIVE', Colors.red, 0.4),
            ),
            StreamBuilder<int>(
              stream: ref.watch(userServiceProvider).getUserCount(),
              builder: (context, snapshot) => _buildKPICard('Active Users', snapshot.hasData ? snapshot.data!.toString() : 'Loading...', 'TOTAL', Colors.indigo, 0.85),
            ),
            _buildKPICard('Platform Health', '99.9%', 'STABLE', Colors.green, 0.95),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(String label, String value, String trend, Color color, double progress) {
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
          Text(label, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(trend, style: TextStyle(color: trend.startsWith('+') ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthMap(WidgetRef ref) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'System Health: Network Live',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBmoIr6BNhyne0XHfn3L2EvhS-V9bsoFgFlGNJMtKLZKjMGTfR_McAS2dcIAl3M3dtfm40uzT2zyyj-H4QD3G2WSNQgcWoFgEcGMzQ-01ad_Quuky5HzJP5bnqbeuhWHVOPwzvgZ8ctG8i779MeULOmRxgGxEbSXs2kzFQA_p2bOnC3fGSka5eI8hBpkZGE1ShSpNasZftXZa21yReRcqOEyKgeHPLx-_JNj-gN_NA8cbhIXTXnQiDox5RT2giEQjYNUg3347VVXO4'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, BoostDriveTheme.backgroundDark.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ref.watch(sosServiceProvider).getGlobalActiveRequests(),
                  builder: (context, snapshot) => Row(
                    children: [
                      _buildMapBadge('SOS ACTIVE: ${snapshot.data?.length ?? 0}', Colors.red),
                      const SizedBox(width: 8),
                      _buildMapBadge('DRIVERS: ONLINE', BoostDriveTheme.primaryColor),
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

  Widget _buildMapBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildManagementTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTabItem('Verification', isActive: true),
          _buildTabItem('Disputes'),
          _buildTabItem('Logistics'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, {bool isActive = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? BoostDriveTheme.surfaceDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? BoostDriveTheme.primaryColor : BoostDriveTheme.textDim,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationList(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PENDING VERIFICATIONS',
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Review All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<UserProfile>>(
          stream: ref.watch(userServiceProvider).getPendingVerifications(),
          builder: (context, snapshot) {
            final pendings = snapshot.data ?? [];
            if (pendings.isEmpty) return Text('No pending verifications.', style: TextStyle(color: BoostDriveTheme.textDim));
            return Column(
              children: pendings.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildVerificationCard(p),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVerificationCard(UserProfile profile) {
    final title = profile.fullName;
    final subtitle = 'Applied: recently • ${profile.role.toUpperCase()}';
    final icon = profile.role == 'service_pro' ? Icons.build : Icons.store;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white24, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(userServiceProvider).updateProfile(
                profile.copyWith(verificationStatus: 'approved', role: 'service_provider'),
              );
            },
            child: _buildActionButton(Icons.check, Colors.green),
          ),
          const SizedBox(width: 8),
          _buildActionButton(Icons.close, Colors.red),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildLogisticsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BoostDriveTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BoostDriveTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: BoostDriveTheme.primaryColor, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BaTLorriH Performance', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('82 trucks active. Efficiency at 94% today.', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
              ],
            ),
          ),
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(color: BoostDriveTheme.surfaceDark, shape: BoxShape.circle),
            child: Icon(Icons.chevron_right, color: BoostDriveTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}
