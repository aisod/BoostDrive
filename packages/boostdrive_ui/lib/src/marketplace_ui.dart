import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_palette.dart';
import 'mobile_customer_ui.dart';

/// Kinetic Precision UI for mobile Shop / marketplace (Stitch exports).
class MarketplaceUi {
  MarketplaceUi._();

  static const double marginMobile = MobileCustomerUi.marginMobile;
  static const double radiusCard = MobileCustomerUi.radiusCard;
  static const double radiusControl = MobileCustomerUi.radiusControl;
  static const double radiusSheetTop = 32;

  static Color _primaryButtonFg(DashboardPalette palette) =>
      palette.isDark ? const Color(0xFF1A1A1A) : Colors.white;

  static PreferredSizeWidget shopAppBar({
    required BuildContext context,
    required DashboardPalette palette,
    required VoidCallback onSearch,
    required VoidCallback onCart,
    int cartItemCount = 0,
  }) {
    final titleColor = palette.isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return AppBar(
      backgroundColor: palette.primaryContainer,
      foregroundColor: titleColor,
      elevation: palette.isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      automaticallyImplyLeading: false,
      title: Text(
        palette.isDark ? 'BOOSTDRIVE SHOP' : 'SHOP',
        style: GoogleFonts.manrope(
          fontSize: palette.isDark ? 15 : 22,
          fontWeight: FontWeight.w800,
          color: titleColor,
          letterSpacing: palette.isDark ? -0.3 : -0.5,
        ),
      ),
      actions: [
        ...MobileCustomerUi.appBarActions(
          onColoredHeader: true,
          trailing: [
            IconButton(
              onPressed: onSearch,
              icon: Icon(Icons.search, color: titleColor),
              tooltip: 'Search',
            ),
            IconButton(
              onPressed: onCart,
              tooltip: 'Cart',
              icon: Badge(
                isLabelVisible: cartItemCount > 0,
                label: Text(
                  cartItemCount > 99 ? '99+' : '$cartItemCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: palette.isDark ? Colors.white : palette.error,
                textColor: palette.isDark ? palette.primaryContainer : Colors.white,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Category pill styled for Shop (dark: orange selected + dark text).
  static Widget categoryPill({
    required DashboardPalette palette,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final selectedBg = palette.primaryContainer;
    final selectedFg = _primaryButtonFg(palette);
    final unselectedBg = palette.isDark ? palette.surfaceContainerHigh : palette.surfaceContainerLowest;
    final unselectedFg = palette.isDark ? palette.onSurfaceVariant : palette.title;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? selectedBg : unselectedBg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: selected
                  ? null
                  : Border.all(color: palette.outlineVariant.withValues(alpha: palette.isDark ? 0.2 : 0.4)),
            ),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.02,
                color: selected ? selectedFg : unselectedFg,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget sectionHeader(
    DashboardPalette palette, {
    VoidCallback? onFiltersTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Available Items',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: palette.title,
            ),
          ),
        ),
        if (onFiltersTap != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFiltersTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      palette.isDark ? 'FILTERS' : 'Filter',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: palette.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.tune,
                      size: 16,
                      color: palette.primaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget sellFab({required VoidCallback onPressed, required DashboardPalette palette}) {
    final fg = _primaryButtonFg(palette);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: palette.primaryContainer.withValues(alpha: palette.isDark ? 0.45 : 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: palette.primaryContainer,
        foregroundColor: fg,
        elevation: 0,
        icon: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fg.withValues(alpha: 0.15),
            border: Border.all(color: fg.withValues(alpha: 0.35)),
          ),
          child: Icon(Icons.add, color: fg, size: 18),
        ),
        label: Text(
          'SELL ITEM',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
            color: fg,
          ),
        ),
      ),
    );
  }

  /// Search listings bottom sheet — keywords only.
  static Future<void> showSearchListingsSheet({
    required BuildContext context,
    required String initialQuery,
    required ValueChanged<String> onApply,
    required VoidCallback onClear,
  }) {
    final palette = DashboardPalette.of(context);
    final controller = TextEditingController(text: initialQuery);
    final focusNode = FocusNode();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: palette.isDark
          ? Colors.black.withValues(alpha: 0.65)
          : Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ctx.mounted) focusNode.requestFocus();
        });

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusSheetTop)),
              border: Border(
                top: BorderSide(
                  color: palette.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(marginMobile, 12, marginMobile, marginMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.onSurfaceVariant.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Search listings',
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: palette.title,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: IconButton.styleFrom(
                            backgroundColor: palette.surfaceContainerHighest.withValues(alpha: 0.5),
                          ),
                          icon: Icon(Icons.close, color: palette.onSurfaceVariant, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'KEYWORDS',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: GoogleFonts.manrope(fontSize: 15, color: palette.title),
                      onSubmitted: (_) {
                        onApply(controller.text);
                        Navigator.pop(ctx);
                      },
                      decoration: InputDecoration(
                        hintText: 'Title, description, location...',
                        hintStyle: TextStyle(color: palette.muted),
                        prefixIcon: Icon(Icons.search, color: palette.muted, size: 22),
                        filled: true,
                        fillColor: palette.isDark ? palette.surfaceContainerLow : palette.surfaceDim,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusControl),
                          borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.25)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusControl),
                          borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.25)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusControl),
                          borderSide: BorderSide(color: palette.primaryContainer, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              controller.clear();
                              onClear();
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: palette.onSurfaceVariant,
                              side: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.4)),
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(radiusControl),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'CLEAR',
                                maxLines: 1,
                                softWrap: false,
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              onApply(controller.text);
                              Navigator.pop(ctx);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.primaryContainer,
                              foregroundColor: _primaryButtonFg(palette),
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(radiusControl),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'APPLY',
                                maxLines: 1,
                                softWrap: false,
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      focusNode.dispose();
      controller.dispose();
    });
  }
}
