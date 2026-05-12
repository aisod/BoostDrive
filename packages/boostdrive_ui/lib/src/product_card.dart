import 'package:flutter/material.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'theme.dart';

class BoostProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const BoostProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF18242C) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE8DED7);
    final titleColor = isDark ? Colors.white : const Color(0xFF1C1A19);
    final bodyColor = isDark ? BoostDriveTheme.textDim : const Color(0xFF6A625D);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.24)
        : const Color(0xFFD9CEC7).withValues(alpha: 0.45);
    final imagePlaceholderColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF8F1EC);
    final ctaLabel = switch (product.category) {
      'part' => 'View Part',
      'rental' => 'View Rental',
      _ => 'View Vehicle',
    };

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            hoverColor: BoostDriveTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
            splashColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: imagePlaceholderColor,
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder(bodyColor);
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                      color: BoostDriveTheme.primaryColor.withValues(alpha: 0.4),
                                    ),
                                  );
                                },
                              )
                            : _buildImagePlaceholder(bodyColor),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.02),
                              Colors.black.withValues(alpha: 0.24),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Badge(
                              label: _getCategoryLabel(product.category),
                              backgroundColor: Colors.white.withValues(alpha: 0.92),
                              foregroundColor: const Color(0xFF221C20),
                            ),
                            if (product.isFeatured)
                              const _Badge(
                                label: 'Featured',
                                backgroundColor: BoostDriveTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Row(
                          children: [
                            Expanded(
                              child: _Badge(
                                label: _formatCondition(product.condition),
                                backgroundColor: Colors.black.withValues(alpha: 0.56),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            if ((product.clickCount ?? 0) > 0) ...[
                              const SizedBox(width: 8),
                              _Badge(
                                label: '${product.clickCount} views',
                                backgroundColor: Colors.black.withValues(alpha: 0.56),
                                foregroundColor: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.subtitle.isNotEmpty ? product.subtitle : _fitmentSummary(),
                        style: TextStyle(
                          fontSize: 14,
                          color: bodyColor,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _MetaPill(
                            icon: Icons.location_on_outlined,
                            label: product.location,
                            foregroundColor: bodyColor,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF8F1EC),
                          ),
                          _MetaPill(
                            icon: Icons.tune,
                            label: _fitmentSummary(),
                            foregroundColor: bodyColor,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF8F1EC),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.category == 'rental' ? 'RATE' : 'PRICE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: bodyColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPrice(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: BoostDriveTheme.primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : const Color(0xFF221C20),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ctaLabel,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF1C1A19) : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 15,
                                  color: isDark ? const Color(0xFF1C1A19) : Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(Color iconColor) {
    return Center(
      child: Icon(
        product.category == 'car'
            ? Icons.directions_car_outlined
            : Icons.settings_outlined,
        color: iconColor,
        size: 40,
      ),
    );
  }

  String _fitmentSummary() {
    final make = product.fitment?['make']?.toString();
    final model = product.fitment?['model']?.toString();
    final year = product.fitment?['year']?.toString();
    final values = [make, model, year].whereType<String>().where((e) => e.isNotEmpty).toList();
    if (values.isNotEmpty) return values.join(' ');
    return 'Multi-fit';
  }

  String _formatPrice() {
    final amount = product.price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
    return product.category == 'rental' ? 'N\$ $amount / day' : 'N\$ $amount';
  }

  String _formatCondition(String condition) {
    if (condition.isEmpty) return 'Available';
    return '${condition[0].toUpperCase()}${condition.substring(1)}';
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'car':
        return 'Vehicle';
      case 'part':
        return 'Part';
      case 'rental':
        return 'Rental';
      default:
        return 'Automotive';
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
