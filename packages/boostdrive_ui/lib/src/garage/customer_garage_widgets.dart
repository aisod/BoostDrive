import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import '../dashboard_palette.dart';

/// Service history row (customer dashboard).
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
    final palette = DashboardPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
        boxShadow: palette.cardShadowLow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: palette.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.build_outlined, color: palette.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.serviceName,
                      style: GoogleFonts.montserrat(
                        color: palette.title,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${item.completedAt.day}/${item.completedAt.month}/${item.completedAt.year}${item.mileageAtService != null ? ' @ ${item.mileageAtService} KM' : ''}',
                      style: GoogleFonts.montserrat(color: palette.body, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'N\$ ${item.price.toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(
                  color: palette.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Divider(color: palette.cardBorder, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, size: 16, color: palette.error),
                      tooltip: 'Delete Record',
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit_outlined, size: 16, color: palette.primary),
                      tooltip: 'Edit Record',
                    ),
                    TextButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.summarize_outlined, size: 14),
                      label: const Text('Details', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: palette.body),
                    ),
                  ],
                ),
              ),
              if (item.receiptUrls.isNotEmpty && onViewReceipts != null)
                TextButton.icon(
                  onPressed: onViewReceipts,
                  icon: const Icon(Icons.receipt_long, size: 14),
                  label: Text(
                    item.receiptUrls.length > 1 ? 'Proofs' : 'Proof',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(foregroundColor: palette.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section title row for garage blocks.
class CustomerGarageSectionHeader extends StatelessWidget {
  const CustomerGarageSectionHeader({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Row(
      children: [
        Icon(icon, color: palette.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: palette.title,
          ),
        ),
      ],
    );
  }
}

/// Vehicle tile used on My Garage grid.
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
    final palette = DashboardPalette.of(context);
    final healthy = vehicle.healthStatus.toLowerCase().contains('healthy') ||
        vehicle.healthStatus.toLowerCase().contains('good');
    final statusColor = healthy ? Colors.green.shade700 : Colors.orange.shade800;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
        boxShadow: palette.cardShadowLow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 96,
              height: 96,
              child: vehicle.imageUrls.isNotEmpty
                  ? Image.network(
                      vehicle.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: palette.surface,
                        child: Icon(Icons.directions_car, color: palette.muted, size: 36),
                      ),
                    )
                  : ColoredBox(
                      color: palette.surface,
                      child: Icon(Icons.directions_car, color: palette.muted, size: 36),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                  style: GoogleFonts.montserrat(
                    color: palette.title,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${vehicle.plateNumber} • ${vehicle.mileage} KM',
                  style: GoogleFonts.montserrat(color: palette.body, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vehicle.healthStatus.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit_outlined, size: 20, color: palette.body),
                      tooltip: 'Edit Vehicle',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, size: 20, color: palette.error),
                      tooltip: 'Delete Vehicle',
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onDetails,
                      child: Text(
                        'DETAILS',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
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

/// Pill add button.
class CustomerGarageAddButton extends StatelessWidget {
  const CustomerGarageAddButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primaryBright,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
    );
  }
}

/// Active order card with progress bar.
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
    final palette = DashboardPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
        boxShadow: palette.cardShadowLow,
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
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.montserrat(
                    color: palette.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(id, style: GoogleFonts.montserrat(color: palette.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: palette.title,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(description, style: GoogleFonts.montserrat(color: palette.body, fontSize: 14)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: palette.surface,
              valueColor: AlwaysStoppedAnimation(palette.primaryBright),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            eta,
            style: GoogleFonts.montserrat(
              color: palette.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
