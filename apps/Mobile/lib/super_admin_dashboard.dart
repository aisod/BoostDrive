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

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
              _buildLogisticsSummary(),
              const SizedBox(height: 32),
              _buildSystemHealthMap(ref),
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
                color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.3)),
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
                color: Colors.green.withValues(alpha: 0.1),
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
            StreamBuilder<List<SosRequest>>(
              stream: ref.watch(sosServiceProvider).getGlobalActiveRequests(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                final isUrgent = count > 0;
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final color = isUrgent ? Colors.red : Colors.green;
                    final shadowColor = isUrgent 
                        ? Colors.red.withOpacity(0.3 + (_pulseController.value * 0.4))
                        : Colors.transparent;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (isUrgent) BoxShadow(color: shadowColor, blurRadius: 15 * _pulseController.value, spreadRadius: 2),
                        ],
                      ),
                      child: _buildKPICard('Active SOS', count.toString(), 'LIVE', color, isUrgent ? 1.0 : 0.0, isUrgent: isUrgent),
                    );
                  },
                );
              },
            ),
            StreamBuilder<List<Product>>(
              stream: ref.watch(productServiceProvider).streamPendingListings(),
              builder: (context, snapshot) => _buildKPICard('Pending Listings', snapshot.hasData ? snapshot.data!.length.toString() : 'Loading...', 'AWAITING', BoostDriveTheme.primaryColor, 0.4),
            ),
            StreamBuilder<double>(
              stream: ref.watch(deliveryServiceProvider).getGlobalVolume(),
              builder: (context, snapshot) => _buildKPICard('Marketplace Vol', snapshot.hasData ? '\$${snapshot.data!.toStringAsFixed(0)}' : 'Loading...', 'TOTAL', BoostDriveTheme.primaryColor, 0.55),
            ),
            StreamBuilder<int>(
              stream: ref.watch(userServiceProvider).getUserCount(),
              builder: (context, snapshot) => _buildKPICard('Active Users', snapshot.hasData ? snapshot.data!.toString() : 'Loading...', 'TOTAL', Colors.indigo, 0.85),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(String label, String value, String trend, Color color, double progress, {bool isUrgent = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUrgent ? color.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
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
                  color: Colors.white.withValues(alpha: 0.05),
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, BoostDriveTheme.backgroundDark.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: StreamBuilder<List<SosRequest>>(
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

  Widget _buildLogisticsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2)),
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
