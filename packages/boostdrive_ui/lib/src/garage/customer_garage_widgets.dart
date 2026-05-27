import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';

import '../dashboard_palette.dart';
import '../dashboard_typography.dart';
import '../mobile_customer_ui.dart';
import 'customer_garage_ui.dart';

/// Service history row (Kinetic Precision).
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

  static IconData _serviceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('oil')) return Icons.oil_barrel_outlined;
    if (n.contains('brake')) return Icons.safety_check_outlined;
    return Icons.build;
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr =
        '${months[item.completedAt.month - 1]} ${item.completedAt.day}, ${item.completedAt.year}';
    final mileageStr = item.mileageAtService != null ? ' • ${item.mileageAtService} km' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MobileCustomerUi.surfaceCard(palette),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Icon(_serviceIcon(item.serviceName), color: palette.primaryContainer, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.serviceName,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.title,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr$mileageStr',
                      style: GoogleFonts.montserrat(fontSize: 12, color: palette.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                'N\$ ${item.price.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: palette.primaryContainer,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: palette.muted),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Record')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Record')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionChip(
                  palette: palette,
                  label: 'Details',
                  icon: Icons.summarize_outlined,
                  onTap: onDetails,
                ),
              ),
              if (item.receiptUrls.isNotEmpty && onViewReceipts != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _actionChip(
                    palette: palette,
                    label: item.receiptUrls.length > 1 ? 'Proofs' : 'Proof',
                    icon: Icons.verified_outlined,
                    onTap: onViewReceipts!,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Widget _actionChip({
    required DashboardPalette palette,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: palette.surfaceContainer,
      borderRadius: BorderRadius.circular(CustomerGarageUi.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CustomerGarageUi.radiusControl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CustomerGarageUi.radiusControl),
            border: Border.all(
              color: palette.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: palette.title),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section title row for garage blocks.
class CustomerGarageSectionHeader extends StatelessWidget {
  const CustomerGarageSectionHeader({super.key, required this.title, required this.icon, this.trailing});

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Row(
      children: [
        Icon(icon, color: palette.primaryContainer, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: palette.title,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Compact vehicle tile (secondary vehicles below featured hero).
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: MobileCustomerUi.surfaceCard(palette),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(CustomerGarageUi.radiusControl),
            child: SizedBox(
              width: 72,
              height: 72,
              child: vehicle.imageUrls.isNotEmpty
                  ? Image.network(vehicle.imageUrls.first, fit: BoxFit.cover)
                  : ColoredBox(
                      color: palette.surfaceContainer,
                      child: Icon(Icons.directions_car, color: palette.muted, size: 32),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.title,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${vehicle.plateNumber} • ${vehicle.mileage} KM',
                  style: DashboardTypography.bodySm(palette),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, size: 20, color: palette.onSurfaceVariant),
            tooltip: 'Edit Vehicle',
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: 20, color: palette.error),
            tooltip: 'Delete Vehicle',
          ),
          TextButton(
            onPressed: onDetails,
            child: Text(
              'DETAILS',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.primaryContainer,
              ),
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
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: palette.primaryContainer,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
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
      padding: const EdgeInsets.all(20),
      decoration: MobileCustomerUi.surfaceCard(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.montserrat(
                    color: palette.primaryContainer,
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
            style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: palette.title),
          ),
          const SizedBox(height: 4),
          Text(description, style: DashboardTypography.bodySm(palette)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: palette.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(palette.primaryContainer),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            eta,
            style: GoogleFonts.montserrat(
              color: palette.primaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
