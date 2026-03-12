import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'theme.dart';
import 'package:intl/intl.dart';

class ServiceTrackingPage extends ConsumerWidget {
  final String orderId;
  const ServiceTrackingPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(singleDeliveryProvider(orderId)).when(
      data: (order) {
        if (order == null) return const Scaffold(body: Center(child: Text('Order not found')));
        
        return Scaffold(
          backgroundColor: BoostDriveTheme.backgroundDark,
          appBar: PremiumHeader(
            title: 'Order Tracking',
            actions: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('CONTACT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BoostDriveTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressStepper(order.status),
                const SizedBox(height: 48),
                _buildStatusHeader(order),
                const SizedBox(height: 32),
                _buildVehicleSection(order),
                const SizedBox(height: 24),
                _buildProviderSection(order),
                const SizedBox(height: 48),
                _buildLiveFeed(order),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildProgressStepper(String status) {
    final steps = ['pending', 'picking_up', 'in_transit', 'delivered'];
    final currentIndex = steps.indexOf(status);
    
    return Row(
      children: [
        _stepperItem('PENDING', currentIndex >= 0, currentIndex > 0),
        _stepperItem('PICKUP', currentIndex >= 1, currentIndex > 1),
        _stepperItem('IN TRANSIT', currentIndex >= 2, currentIndex > 2),
        _stepperItem('DELIVERED', currentIndex >= 3, currentIndex >= 3, isLast: true),
      ],
    );
  }

  Widget _stepperItem(String label, bool isDone, bool showCheck, {bool isLast = false}) {
    final color = isDone ? BoostDriveTheme.primaryColor : Colors.white24;
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Container(height: 2, color: isDone ? color : Colors.white12)),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                  shape: BoxShape.circle,
                ),
                child: showCheck ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
              ),
              Expanded(child: Container(height: 2, color: isLast ? Colors.transparent : (isDone ? color : Colors.white12))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: isDone ? Colors.white : Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(DeliveryOrder order) {
    String statusTitle = 'Order in Progress';
    if (order.status == 'delivered') statusTitle = 'Delivery Complete';
    if (order.status == 'pending') statusTitle = 'Order Confirmed';
    if (order.status == 'picking_up') statusTitle = 'Picking Up Order';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          statusTitle,
          style: GoogleFonts.manrope(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          order.status == 'delivered' ? 'Order delivered successfully.' : 'Estimated completion by ${order.eta.isNotEmpty ? order.eta : "Calculating..."}.',
          style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildVehicleSection(DeliveryOrder order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131D25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.directions_car, color: BoostDriveTheme.primaryColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Destination: ${order.dropoffLocation['address'] ?? "Unknown Location"}',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSection(DeliveryOrder order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131D25).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1486006920555-c77dcf18193c?auto=format&fit=crop&q=80&w=300'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Logistics Partner',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  order.driverId != null ? 'Driver Assigned: ${order.driverId}' : 'Waiting for Driver',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Message'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveFeed(DeliveryOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Status Log'),
        const SizedBox(height: 24),
        if (order.status == 'delivered' || order.status == 'in_transit' || order.status == 'picking_up' || order.status == 'pending')
          _feedItem(DateFormat('HH:mm').format(order.createdAt), 'Order created and confirmed.', isActive: order.status == 'pending'),
        if (order.status == 'picking_up' || order.status == 'in_transit' || order.status == 'delivered')
          _feedItem('Update', 'Driver assigned and heading to pickup.', isActive: order.status == 'picking_up'),
        if (order.status == 'in_transit' || order.status == 'delivered')
          _feedItem('Update', 'Package picked up. In transit to destination.', isActive: order.status == 'in_transit'),
        if (order.status == 'delivered')
          _feedItem('Final', 'Order delivered successfully.', isActive: true),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: BoostDriveTheme.textDim,
        letterSpacing: 1,
      ),
    );
  }

  Widget _feedItem(String time, String message, {required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive ? BoostDriveTheme.primaryColor : Colors.white12,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 40, color: Colors.white.withValues(alpha: 0.05)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: TextStyle(color: isActive ? BoostDriveTheme.primaryColor : BoostDriveTheme.textDim, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: isActive ? Colors.white : Colors.white38, fontSize: 15, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const PremiumHeader({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
