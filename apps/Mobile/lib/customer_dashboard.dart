import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'providers.dart';
import 'chat_page.dart';

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return PremiumPageLayout(
      showBackground: true,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Customer Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(ref, user.id),
              const SizedBox(height: 24),
              _buildManageRoles(),
              const SizedBox(height: 32),
              _buildMyGarage(ref, user.id),
              const SizedBox(height: 32),
              _buildActiveOrders(ref, user.id),
              const SizedBox(height: 32),
              _buildServiceHistory(ref, user.id),
              const SizedBox(height: 32),
              _buildPromoBanner(),
              const SizedBox(height: 100),
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
                  'Welcome back,',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                ),
                Text(
                  profile.fullName,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO: Implement notifications overlay
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications coming soon')),
                    );
                  },
                  child: _buildHeaderIcon(Icons.notifications_none_rounded),
                ),
                ref.watch(unreadConversationsProvider(uid)).when(
                  data: (unreadIds) {
                    if (unreadIds.isEmpty) return const SizedBox();
                    return Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: BoostDriveTheme.surfaceDark,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${unreadIds.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
            const SizedBox(width: 12),
            _buildHeaderIcon(Icons.settings_outlined),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text('Error loading header'),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildManageRoles() {
    final activeRole = ref.watch(activeRoleProvider);
    
    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Roles',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Switch your primary dashboard view',
                    style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: BoostDriveTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PARTNER PORTAL',
                  style: TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRoleItem('Customer', 'Currently Active', Icons.directions_car, isActive: activeRole == 'customer'),
          const SizedBox(height: 12),
          _buildRoleItem('Service Provider', 'Manage mechanics & shops', Icons.build_outlined, isActive: activeRole == 'service_pro'),
          const SizedBox(height: 12),
          _buildRoleItem('Seller', 'Marketplace inventory', Icons.sell_outlined, isActive: activeRole == 'seller'),
          const SizedBox(height: 12),
          _buildRoleItem('Super Admin', 'System-wide management', Icons.admin_panel_settings, isActive: activeRole == 'super_admin'),
          const SizedBox(height: 12),
          _buildRoleItem('BaTLorriH Logistics', 'Fleet & dispatch operations', Icons.local_shipping, isActive: activeRole == 'logistics'),
          const SizedBox(height: 12),
          _buildRoleItem('Host', 'Rent out your vehicles', Icons.vpn_key_outlined, isLocked: true),
        ],
      ),
    );
  }

  Widget _buildRoleItem(String title, String subtitle, IconData icon, {bool isActive = false, bool isLocked = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? BoostDriveTheme.primaryColor.withOpacity(0.05) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? BoostDriveTheme.primaryColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isActive ? BoostDriveTheme.primaryColor : Colors.white38, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: BoostDriveTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Current', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else if (isLocked)
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Host role activated!')));
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 40),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Activate', style: TextStyle(fontSize: 12)),
            )
          else
            OutlinedButton(
              onPressed: () {
                String? targetRole;
                if (title == 'Service Provider') targetRole = 'service_pro';
                if (title == 'Seller') targetRole = 'seller';
                if (title == 'Customer') targetRole = 'customer';
                if (title == 'Super Admin') targetRole = 'super_admin';
                if (title == 'BaTLorriH Logistics') targetRole = 'logistics';
                
                if (targetRole != null) {
                  ref.read(activeRoleProvider.notifier).state = targetRole;
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 40),
                side: BorderSide(color: BoostDriveTheme.primaryColor.withOpacity(0.5)),
                foregroundColor: BoostDriveTheme.primaryColor,
              ),
              child: const Text('Switch to...', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ... (Rest of the methods: _buildMyGarage, _buildVehicleCard, _buildStat, _buildActiveOrders, _buildServiceHistory, _buildHistoryItem, _buildPromoBanner)
  // I will include them in the full write_to_file call.
  
  Widget _buildMyGarage(WidgetRef ref, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Garage',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle, size: 18),
              label: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ref.watch(userVehiclesProvider(uid)).when(
          data: (vehicles) {
            if (vehicles.isEmpty) return Text('No vehicles in your garage.', style: TextStyle(color: BoostDriveTheme.textDim));
            return SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final v = vehicles[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildVehicleCard(
                      '${v.year} ${v.make} ${v.model}',
                      v.plateNumber,
                      v.healthStatus,
                      v.fuelLevel,
                      'N/A',
                      '',
                      isBattery: v.fuelLevel.contains('%'),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Error loading garage'),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(String name, String plate, String status, String fuel, String mileage, String imagePath, {bool isBattery = false}) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.white.withOpacity(0.05),
              child: const Center(child: Icon(Icons.directions_car_filled_outlined, size: 40, color: Colors.white10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('HEALTHY', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                Text('Plate: $plate', style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat(isBattery ? 'BATTERY' : 'FUEL', fuel),
                    _buildStat('MILEAGE', mileage),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 9, fontWeight: FontWeight.w900)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActiveOrders(WidgetRef ref, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Orders',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        ref.watch(activeDeliveriesProvider(uid)).when(
          data: (orders) {
            if (orders.isEmpty) return Text('No active orders.', style: TextStyle(color: BoostDriveTheme.textDim));
            return Column(
              children: orders.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOrderCardWidget(o),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Error loading orders'),
        ),
      ],
    );
  }

  Widget _buildOrderCardWidget(DeliveryOrder o) {
    return Container(
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
                  const Icon(Icons.local_shipping, color: BoostDriveTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    o.status.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
              Text('ID: #${o.id.substring(0, 8).toUpperCase()}', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            o.items['title'] ?? 'Generic Parts Delivery',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            o.items['description'] ?? 'Automotive Parts',
            style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    Container(
                      height: 6,
                      width: o.status == 'delivered' ? 400 : 150, // Dummy width for progress
                      decoration: BoxDecoration(
                        color: BoostDriveTheme.primaryColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                o.eta.isNotEmpty ? o.eta : 'N/A',
                style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.map_outlined), label: const Text('Track Live'))),
              const SizedBox(width: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.phone_outlined, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceHistory(WidgetRef ref, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Service History',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ref.watch(userVehiclesProvider(uid)).when(
          data: (vehicles) {
            if (vehicles.isEmpty) return const SizedBox();
            return ref.watch(vehicleHistoryProvider(vehicles.first.id)).when(
              data: (history) {
                if (history.isEmpty) return const SizedBox();
                return Column(
                  children: history.take(2).map((item) => _buildHistoryItem(
                    item.serviceName,
                    '${item.completedAt.day}/${item.completedAt.month}/${item.completedAt.year}',
                    '\$${item.price.toStringAsFixed(2)}',
                    Icons.build,
                  )).toList(),
                );
              },
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            );
          },
          loading: () => const SizedBox(),
          error: (_, _) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(String title, String subtitle, String price, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BoostDriveTheme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: BoostDriveTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Icon(icon, color: BoostDriveTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BOOSTDRIVE.SHOP',
                  style: TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upgrade your BMW\'s air filter for 15% better flow.',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(120, 44),
                  ),
                  child: const Text('Shop Now'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.air, color: Colors.white24, size: 40),
          ),
        ],
      ),
    );
  }
}
