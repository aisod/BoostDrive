import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

/// Dedicated Garage tab: My Garage, Active Orders, Service History, and Shop promo.
class GaragePage extends ConsumerWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in', style: TextStyle(color: Colors.white))),
      );
    }

    return PremiumPageLayout(
      showBackground: true,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Garage',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_circle, size: 20, color: Colors.white),
            label: const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _MyGarageSection(uid: user.id),
              const SizedBox(height: 32),
              _ActiveOrdersSection(uid: user.id),
              const SizedBox(height: 32),
              _ServiceHistorySection(uid: user.id),
              const SizedBox(height: 32),
              _PromoBanner(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyGarageSection extends ConsumerWidget {
  const _MyGarageSection({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(userVehiclesProvider(uid)).when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Text('No vehicles in your garage.', style: TextStyle(color: BoostDriveTheme.textDim));
            }
            return SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final v = vehicles[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _VehicleCard(
                      name: '${v.year} ${v.make} ${v.model}',
                      plate: v.plateNumber,
                      status: v.healthStatus,
                      fuel: v.fuelLevel,
                      mileage: 'N/A',
                      isBattery: v.fuelLevel.contains('%'),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text('Error loading garage', style: TextStyle(color: BoostDriveTheme.textDim)),
        );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.name,
    required this.plate,
    required this.status,
    required this.fuel,
    required this.mileage,
    this.isBattery = false,
  });

  final String name;
  final String plate;
  final String status;
  final String fuel;
  final String mileage;
  final bool isBattery;

  @override
  Widget build(BuildContext context) {
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
                    Flexible(
                      child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
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
                const SizedBox(height: 4),
                Text('Plate: $plate', style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Stat(label: isBattery ? 'BATTERY' : 'FUEL', value: fuel),
                    _Stat(label: 'MILEAGE', value: mileage),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 9, fontWeight: FontWeight.w900)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ActiveOrdersSection extends ConsumerWidget {
  const _ActiveOrdersSection({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            if (orders.isEmpty) {
              return Text('No active orders.', style: TextStyle(color: BoostDriveTheme.textDim));
            }
            return Column(
              children: orders.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderCard(order: o),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text('Error loading orders', style: TextStyle(color: BoostDriveTheme.textDim)),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
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
                    order.status.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
              Text('ID: #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            order.items['title'] ?? 'Generic Parts Delivery',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            order.items['description'] ?? 'Automotive Parts',
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
                      width: order.status == 'delivered' ? 400 : 150,
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
                order.eta.isNotEmpty ? order.eta : 'N/A',
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
}

class _ServiceHistorySection extends ConsumerWidget {
  const _ServiceHistorySection({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  children: history.take(2).map((item) => _HistoryItem(
                    title: item.serviceName,
                    subtitle: '${item.completedAt.day}/${item.completedAt.month}/${item.completedAt.year}',
                    price: '\$${item.price.toStringAsFixed(2)}',
                    icon: Icons.build,
                  )).toList(),
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.title, required this.subtitle, required this.price, required this.icon});

  final String title;
  final String subtitle;
  final String price;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
