import 'package:flutter/material.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'theme.dart';

class BoostProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool compact;

  const BoostProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompact = compact || constraints.maxWidth < 220 || constraints.maxHeight < 340;
        return _BoostProductCardBody(
          product: product,
          onTap: onTap,
          compact: useCompact,
        );
      },
    );
  }
}

class _BoostProductCardBody extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool compact;

  const _BoostProductCardBody({
    required this.product,
    this.onTap,
    required this.compact,
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
      'part' => compact ? 'VIEW' : 'View Part',
      'rental' => compact ? 'VIEW' : 'View Rental',
      _ => compact ? 'VIEW' : 'View Vehicle',
    };
    final categoryTagLabel = _getCategoryLabel(product.category);
    final displayCategoryTag = compact ? categoryTagLabel.toUpperCase() : categoryTagLabel;

    final edgePadding = compact ? 12.0 : 18.0;
    final titleSize = compact ? 13.0 : 18.0;
    final bodySize = compact ? 10.0 : 14.0;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(compact ? 24 : 28),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: compact ? 12 : 24,
              offset: Offset(0, compact ? 6 : 12),
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
            borderRadius: BorderRadius.circular(compact ? 24 : 28),
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
                        top: compact ? 8 : 16,
                        left: compact ? 8 : 16,
                        right: compact ? 8 : 16,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Badge(
                              label: displayCategoryTag,
                              backgroundColor: compact
                                  ? (isDark
                                      ? BoostDriveTheme.primaryColor
                                      : const Color(0xFFFFDBCF))
                                  : Colors.white.withValues(alpha: 0.92),
                              foregroundColor: compact
                                  ? (isDark
                                      ? const Color(0xFF1A1A1A)
                                      : BoostDriveTheme.primaryColor)
                                  : const Color(0xFF221C20),
                              fontSize: compact ? 8 : 11,
                              letterSpacing: compact ? 0.6 : 0,
                            ),
                            if (product.isFeatured && !compact)
                              const _Badge(
                                label: 'Featured',
                                backgroundColor: BoostDriveTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                          ],
                        ),
                      ),
                      if (!compact)
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
                  padding: EdgeInsets.all(edgePadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.15,
                        ),
                        maxLines: compact ? 2 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: compact ? 4 : 8),
                      Text(
                        product.subtitle.isNotEmpty ? product.subtitle : _fitmentSummary(),
                        style: TextStyle(
                          fontSize: bodySize,
                          color: bodyColor,
                          height: 1.25,
                        ),
                        maxLines: compact ? 2 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: compact ? 6 : 12),
                      if (compact)
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 12, color: bodyColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.location.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  color: bodyColor,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
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
                      SizedBox(height: compact ? 8 : 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!compact)
                                  Text(
                                    product.category == 'rental' ? 'RATE' : 'PRICE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: bodyColor,
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                  ),
                                if (!compact) const SizedBox(height: 4),
                                Text(
                                  _formatPrice(),
                                  style: TextStyle(
                                    fontSize: compact ? 14 : 24,
                                    fontWeight: FontWeight.w800,
                                    color: compact ? titleColor : BoostDriveTheme.primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 12 : 14,
                              vertical: compact ? 7 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: compact
                                  ? (isDark
                                      ? BoostDriveTheme.primaryColor
                                      : const Color(0xFFFFDBCF))
                                  : (isDark ? Colors.white : const Color(0xFF221C20)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ctaLabel,
                                  style: TextStyle(
                                    color: compact
                                        ? (isDark
                                            ? const Color(0xFF1A1A1A)
                                            : BoostDriveTheme.primaryColor)
                                        : (isDark ? const Color(0xFF1C1A19) : Colors.white),
                                    fontSize: compact ? 9 : 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: compact ? 0.4 : 0,
                                  ),
                                  maxLines: 1,
                                ),
                                if (!compact) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 15,
                                    color: isDark ? const Color(0xFF1C1A19) : Colors.white,
                                  ),
                                ],
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
        size: compact ? 32 : 40,
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
  final double fontSize;
  final double letterSpacing;

  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.fontSize = 11,
    this.letterSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize, vertical: fontSize * 0.55),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: letterSpacing,
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
  final double fontSize;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: fontSize, vertical: fontSize * 0.7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: fontSize + 3, color: foregroundColor),
          SizedBox(width: fontSize * 0.5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
