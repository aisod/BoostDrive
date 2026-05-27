import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_palette.dart';
import 'mobile_customer_ui.dart';

/// Kinetic Precision UI for mobile cart, checkout dialog, and new listing form.
class ShopCommerceUi {
  ShopCommerceUi._();

  static const double marginMobile = MobileCustomerUi.marginMobile;
  static const double radiusCard = MobileCustomerUi.radiusCard;
  static const double radiusControl = MobileCustomerUi.radiusControl;
  static const double radiusSheetTop = 32;

  static Color _primaryButtonFg(DashboardPalette palette) =>
      palette.isDark ? const Color(0xFF1A1A1A) : Colors.white;

  /// Frosted top bar: back + title + theme toggle.
  static PreferredSizeWidget glassAppBar({
    required BuildContext context,
    required DashboardPalette palette,
    required String title,
    List<Widget>? trailing,
    bool onColoredHeader = false,
  }) {
    final barBg = palette.isDark
        ? palette.surfaceContainerLow.withValues(alpha: 0.92)
        : palette.surfaceContainerLowest.withValues(alpha: 0.85);

    // Light mode: theme AppBar icon defaults can wash out on white — pin leading color.
    final leadingColor = palette.isDark ? palette.primary : palette.primaryContainer;

    return AppBar(
      backgroundColor: barBg,
      foregroundColor: leadingColor,
      iconTheme: IconThemeData(color: leadingColor),
      actionsIconTheme: IconThemeData(color: leadingColor),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: leadingColor),
              onPressed: () => Navigator.maybePop(context),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          : null,
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: leadingColor,
          letterSpacing: -0.3,
        ),
      ),
      actions: MobileCustomerUi.appBarActions(
        onColoredHeader: onColoredHeader,
        trailing: trailing,
      ),
    );
  }

  static Widget sectionLabel(DashboardPalette palette, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: palette.secondary,
        ),
      ),
    );
  }

  static Widget sectionCard({
    required DashboardPalette palette,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(
          color: palette.outlineVariant.withValues(alpha: palette.isDark ? 0.12 : 0.25),
        ),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  static Widget labeledFieldHeader(DashboardPalette palette, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: palette.onSurfaceVariant,
        ),
      ),
    );
  }

  static InputDecoration formDecoration(
    DashboardPalette palette, {
    String? label,
    String? hint,
    Widget? prefix,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefix: prefix,
      prefixText: prefixText,
      labelStyle: TextStyle(color: palette.onSurfaceVariant, fontSize: 12),
      hintStyle: TextStyle(color: palette.muted, fontSize: 14),
      filled: true,
      fillColor: palette.isDark ? palette.surfaceContainerLow : palette.surfaceDim,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.primaryContainer, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.error),
      ),
    );
  }

  // ——— Cart ———

  static Widget cartSectionHeading(DashboardPalette palette, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: palette.secondary,
        ),
      ),
    );
  }

  static Widget cartEmptyState(DashboardPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(marginMobile, 48, marginMobile, 24),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.isDark ? palette.surfaceContainerHigh : palette.surfaceContainer,
              boxShadow: palette.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: palette.muted.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Looks like you haven't added any high-performance parts or vehicles yet.",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 15,
              height: 1.45,
              color: palette.body,
            ),
          ),
        ],
      ),
    );
  }

  static Widget cartLineItem({
    required DashboardPalette palette,
    required String title,
    required String subtitle,
    required String unitPriceLabel,
    required String lineTotalLabel,
    required String metaLabel,
    required bool isRental,
    required String? imageUrl,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(
          color: palette.outlineVariant.withValues(alpha: palette.isDark ? 0.1 : 0.2),
        ),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radiusControl),
            child: Container(
              width: 96,
              height: 96,
              color: palette.surfaceContainer,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Icon(Icons.image_outlined, color: palette.muted, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: palette.title,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.manrope(fontSize: 13, color: palette.secondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: Icon(Icons.close, color: palette.muted.withValues(alpha: 0.6), size: 20),
                      tooltip: 'Remove item',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: palette.surfaceContainer,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: palette.outlineVariant.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isRental) ...[
                            Icon(Icons.calendar_month, size: 14, color: palette.secondary),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            metaLabel,
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: palette.title,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          unitPriceLabel,
                          style: GoogleFonts.manrope(fontSize: 11, color: palette.muted),
                        ),
                        Text(
                          lineTotalLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: palette.title,
                          ),
                        ),
                      ],
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

  static Widget cartFooter({
    required DashboardPalette palette,
    required String totalLabel,
    required bool checkoutEnabled,
    required bool loading,
    required VoidCallback onCheckout,
  }) {
    final fg = _primaryButtonFg(palette);
    return Container(
      padding: const EdgeInsets.fromLTRB(marginMobile, 20, marginMobile, 12),
      decoration: BoxDecoration(
        color: palette.isDark
            ? palette.surfaceContainerLow.withValues(alpha: 0.95)
            : palette.surfaceContainerLowest.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.12)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.manrope(fontSize: 16, color: palette.secondary),
                ),
                Text(
                  totalLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: palette.title,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: checkoutEnabled && !loading ? onCheckout : null,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryContainer,
                  disabledBackgroundColor: palette.surfaceContainerHighest,
                  foregroundColor: fg,
                  disabledForegroundColor: palette.muted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
                  elevation: checkoutEnabled ? 4 : 0,
                  shadowColor: palette.primaryContainer.withValues(alpha: 0.35),
                ),
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Checkout',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            checkoutEnabled ? Icons.arrow_forward : Icons.lock_outline,
                            size: 20,
                            color: checkoutEnabled ? fg : palette.muted,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget providerRecommendationCard({
    required DashboardPalette palette,
    required String vehicleLabel,
    required String notes,
    required Widget summaryLine,
    required bool isProcessing,
    required VoidCallback onViewDetails,
    required VoidCallback onDismiss,
    required VoidCallback onAddToCart,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(
          color: palette.outlineVariant.withValues(alpha: palette.isDark ? 0.1 : 0.15),
        ),
        boxShadow: palette.cardShadowLow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                color: palette.surfaceContainer,
                child: Icon(Icons.directions_car_filled, size: 48, color: palette.muted.withValues(alpha: 0.4)),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'VERIFIED PROVIDER',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: _primaryButtonFg(palette),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicleLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: palette.title,
                            ),
                          ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(notes, style: GoogleFonts.manrope(fontSize: 13, color: palette.secondary)),
                          ],
                          const SizedBox(height: 6),
                          summaryLine,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isProcessing ? null : onAddToCart,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primaryContainer,
                      foregroundColor: _primaryButtonFg(palette),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
                    ),
                    child: Text(
                      isProcessing ? 'ADDING...' : 'ADD TO CART',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing ? null : onViewDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.title,
                          side: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.25)),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radiusControl),
                          ),
                        ),
                        child: Text(
                          'VIEW DETAILS',
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: isProcessing ? null : onDismiss,
                      child: Text(
                        'DISMISS',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: palette.secondary,
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

  /// Checkout options — kinetic bottom sheet (same return values as legacy dialog).
  static Future<String?> showCheckoutOptionsDialog(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final fg = _primaryButtonFg(palette);

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: palette.isDark
          ? Colors.black.withValues(alpha: 0.65)
          : Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: marginMobile,
            right: marginMobile,
            bottom: MediaQuery.paddingOf(ctx).bottom + 16,
          ),
          child: Material(
            color: palette.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(radiusCard),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.onSurfaceVariant.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Checkout Options',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: palette.title,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'message_seller'),
                      icon: Icon(Icons.chat_bubble_outline, color: palette.primaryContainer),
                      label: Text(
                        'Message Seller Directly',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: palette.primaryContainer,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        side: BorderSide(color: palette.primaryContainer, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radiusControl),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'online_coming_soon'),
                      icon: Icon(Icons.payments_outlined, color: fg),
                      label: Text(
                        'Online Payments (Coming Soon)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: fg,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primaryContainer.withValues(alpha: palette.isDark ? 1 : 0.85),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radiusControl),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<String?> showSelectSellerDialog(
    BuildContext context, {
    required List<({String sellerId, String title, int itemCount})> sellers,
  }) {
    final palette = DashboardPalette.of(context);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(marginMobile),
          decoration: BoxDecoration(
            color: palette.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(radiusCard),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.onSurfaceVariant.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select Seller',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: palette.title,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: sellers.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: palette.outlineVariant.withValues(alpha: 0.15),
                  ),
                  itemBuilder: (_, i) {
                    final s = sellers[i];
                    return ListTile(
                      title: Text(s.title, style: GoogleFonts.manrope(color: palette.title)),
                      subtitle: Text(
                        '${s.itemCount} item(s)',
                        style: GoogleFonts.manrope(fontSize: 13, color: palette.secondary),
                      ),
                      onTap: () => Navigator.pop(ctx, s.sellerId),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: palette.muted)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Select quantity overlay — returns parsed int 1–999, or null if cancelled.
  static Future<int?> showSelectQuantityDialog(
    BuildContext context, {
    String? productTitle,
  }) {
    final palette = DashboardPalette.of(context);
    final controller = TextEditingController(text: '1');
    final focusNode = FocusNode();

    Future<int?> dialogFuture = showDialog<int>(
      context: context,
      barrierColor: palette.isDark
          ? palette.background.withValues(alpha: 0.82)
          : Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ctx.mounted) focusNode.requestFocus();
        });

        final attemptedSubmit = <bool>[false];

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            String? validateQty() {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed < 1) return 'Enter a valid quantity (1+)';
              if (parsed > 999) return 'Quantity is too high';
              return null;
            }

            void submit() {
              attemptedSubmit[0] = true;
              final error = validateQty();
              if (error != null) {
                setStateDialog(() {});
                return;
              }
              Navigator.pop(ctx, int.parse(controller.text.trim()));
            }

            void adjustQty(int delta) {
              final current = int.tryParse(controller.text.trim()) ?? 1;
              final next = (current + delta).clamp(1, 999);
              controller.text = '$next';
              controller.selection = TextSelection.collapsed(offset: controller.text.length);
              attemptedSubmit[0] = false;
              setStateDialog(() {});
            }

            final errorText = attemptedSubmit[0] ? validateQty() : null;

            final fg = _primaryButtonFg(palette);
            final dialogBg = palette.isDark ? palette.surfaceContainerLow : Colors.white;
            final titleColor = palette.isDark ? palette.title : const Color(0xFF0F172A);
            final fieldBg = palette.isDark ? palette.surfaceContainerLowest : const Color(0xFFF8FAFC);
            final fieldBorder = palette.isDark
                ? palette.surfaceVariant.withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: marginMobile),
              child: Material(
                color: dialogBg,
                borderRadius: BorderRadius.circular(radiusCard),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radiusCard),
                    border: palette.isDark
                        ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: palette.isDark ? 0.45 : 0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (palette.isDark) ...[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: palette.primaryContainer.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.shopping_cart, color: palette.primaryContainer, size: 28),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Select Quantity',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (palette.isDark)
                        Text(
                          productTitle != null && productTitle.trim().isNotEmpty
                              ? 'How many units of $productTitle would you like to add?'
                              : 'How many units would you like to add?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            height: 1.45,
                            color: palette.onSurfaceVariant,
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Total Units',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          TextField(
                            controller: controller,
                            focusNode: focusNode,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: palette.isDark ? 32 : 28,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                            onSubmitted: (_) => submit(),
                            decoration: InputDecoration(
                              hintText: '1',
                              hintStyle: TextStyle(color: palette.muted.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: fieldBg,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: palette.isDark ? 52 : 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(radiusControl),
                                borderSide: BorderSide(color: fieldBorder, width: palette.isDark ? 1 : 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(radiusControl),
                                borderSide: BorderSide(color: fieldBorder, width: palette.isDark ? 1 : 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(radiusControl),
                                borderSide: BorderSide(color: palette.primaryContainer, width: 2),
                              ),
                              errorText: errorText,
                              errorMaxLines: 2,
                            ),
                          ),
                          Positioned(
                            left: 8,
                            child: _qtyStepButton(
                              palette: palette,
                              icon: Icons.remove,
                              onTap: () => adjustQty(-1),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            child: _qtyStepButton(
                              palette: palette,
                              icon: Icons.add,
                              onTap: () => adjustQty(1),
                            ),
                          ),
                        ],
                      ),
                      if (!palette.isDark) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Estimated shipping calculated at checkout',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                      SizedBox(height: palette.isDark ? 24 : 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.primaryContainer,
                            foregroundColor: fg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(palette.isDark ? 999 : radiusControl),
                            ),
                            elevation: 6,
                            shadowColor: palette.primaryContainer.withValues(alpha: 0.35),
                          ),
                          child: Text(
                            palette.isDark ? 'ADD TO CART' : 'Add to Cart',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: palette.isDark ? 0.5 : 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: palette.isDark ? palette.onSurfaceVariant : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return dialogFuture.whenComplete(() {
      focusNode.dispose();
      controller.dispose();
    });
  }

  static Widget _qtyStepButton({
    required DashboardPalette palette,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: palette.isDark ? palette.onSurfaceVariant : palette.primaryContainer,
          ),
        ),
      ),
    );
  }

  static Widget listingStickyFooter({
    required BuildContext context,
    required DashboardPalette palette,
    required VoidCallback onPublish,
    bool loading = false,
  }) {
    final fg = _primaryButtonFg(palette);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(marginMobile, 16, marginMobile, bottom + 16),
      decoration: BoxDecoration(
        color: palette.isDark
            ? palette.surfaceContainerLow.withValues(alpha: 0.92)
            : palette.surfaceContainerLowest.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.1))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: loading ? null : onPublish,
          style: FilledButton.styleFrom(
            backgroundColor: palette.primaryContainer,
            foregroundColor: fg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
            elevation: 4,
            shadowColor: palette.primaryContainer.withValues(alpha: 0.3),
          ),
          child: loading
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
              : Text(
                  'Publish Listing',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
                ),
        ),
      ),
    );
  }

  static Widget infoHint(DashboardPalette palette, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: palette.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(fontSize: 12, color: palette.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
