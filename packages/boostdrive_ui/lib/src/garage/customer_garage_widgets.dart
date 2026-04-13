import 'package:flutter/material.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import '../theme.dart';

/// Service history row (matches web customer dashboard).
class CustomerGarageHistoryItem extends StatelessWidget {
  const CustomerGarageHistoryItem({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
    required this.onDetails,
    required this.onViewReceipts,
  });

  final ServiceRecord item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onDetails;
  final VoidCallback? onViewReceipts;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.build_outlined, color: BoostDriveTheme.primaryColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.serviceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      '${item.completedAt.day}/${item.completedAt.month}/${item.completedAt.year}${item.mileageAtService != null ? ' @ ${item.mileageAtService} KM' : ''}',
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text('N\$ ${item.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x22FF6600)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      tooltip: 'Delete Record',
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16, color: BoostDriveTheme.primaryColor),
                      tooltip: 'Edit Record',
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.summarize_outlined, size: 14),
                      label: const Text('Details', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (item.receiptUrls.isNotEmpty && onViewReceipts != null)
                TextButton.icon(
                  onPressed: onViewReceipts,
                  icon: const Icon(Icons.receipt_long, size: 14),
                  label: Text(item.receiptUrls.length > 1 ? 'Proofs' : 'Proof', style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: BoostDriveTheme.primaryColor),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section title row (matches web customer dashboard garage blocks).
class CustomerGarageSectionHeader extends StatelessWidget {
  const CustomerGarageSectionHeader({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
}

/// Vehicle tile used on web My Garage grid (padding, image, actions).
class CustomerGarageVehicleCard extends StatelessWidget {
  const CustomerGarageVehicleCard({
    super.key,
    required this.vehicle,
    required this.onDelete,
    required this.onEdit,
    required this.onDetails,
  });

  final Vehicle vehicle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final healthy = vehicle.healthStatus.toLowerCase().contains('healthy') || vehicle.healthStatus.toLowerCase().contains('good');
    final statusColor = healthy ? Colors.green : Colors.orange;

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
          if (vehicle.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.05),
                  child: Image.network(
                    vehicle.imageUrls.first,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.black.withValues(alpha: 0.02),
                      child: Icon(Icons.directions_car, color: Colors.white.withValues(alpha: 0.05), size: 40),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vehicle.healthStatus.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  vehicle.plateNumber,
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.speed, color: Color(0x22FF6600), size: 14),
              const SizedBox(width: 4),
              Text('${vehicle.mileage} KM', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    tooltip: 'Delete Vehicle',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.05),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20, color: BoostDriveTheme.primaryColor),
                    tooltip: 'Edit Vehicle',
                    style: IconButton.styleFrom(
                      backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.05),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: TextButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white38),
                  label: const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Outlined add button (matches web).
class CustomerGarageAddButton extends StatelessWidget {
  const CustomerGarageAddButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x22FF6600)),
        ),
      ),
    );
  }
}

/// Active order card (matches web styling and progress bar).
class CustomerGarageOrderCard extends StatelessWidget {
  const CustomerGarageOrderCard({
    super.key,
    required this.title,
    required this.id,
    required this.status,
    required this.description,
    required this.eta,
    required this.progress,
  });

  final String title;
  final String id;
  final String status;
  final String description;
  final String eta;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: BoostDriveTheme.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    color: BoostDriveTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(id, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(description, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16)),
          const SizedBox(height: 32),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: const AlwaysStoppedAnimation(BoostDriveTheme.primaryColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(eta, style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
