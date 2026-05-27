import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_palette.dart';
import 'mobile_customer_ui.dart';

/// Kinetic Precision UI for mobile Find a Provider list + customer provider profile.
class ProviderDirectoryUi {
  ProviderDirectoryUi._();

  static const double marginMobile = MobileCustomerUi.marginMobile;
  static const double radiusCard = MobileCustomerUi.radiusCard;
  static const double radiusControl = MobileCustomerUi.radiusControl;

  static Color _primaryButtonFg(DashboardPalette palette) =>
      palette.isDark ? const Color(0xFF1A1A1A) : Colors.white;

  static PreferredSizeWidget listAppBar({
    required BuildContext context,
    required String title,
  }) =>
      MobileCustomerUi.topAppBar(context: context, title: title);

  static Widget searchField({
    required DashboardPalette palette,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String hint = 'Search by name, role, or service area...',
  }) {
    final fill = palette.isDark ? palette.surfaceContainerLow : const Color(0xFFEEEEEE);
    final border = palette.isDark ? palette.surfaceContainerHighest : const Color(0xFFE3BFB2);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.manrope(fontSize: 16, color: palette.title),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
          fontSize: 15,
          color: palette.isDark ? palette.onSurfaceVariant : const Color(0xFF5A4138),
        ),
        prefixIcon: Icon(Icons.search, color: palette.onSurfaceVariant, size: 22),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: palette.primaryContainer, width: 2),
        ),
      ),
    );
  }

  static Widget filterChipRow({required List<Widget> children}) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: children,
      ),
    );
  }

  static Widget filterChip({
    required DashboardPalette palette,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final selectedBg = palette.primaryContainer;
    final selectedFg = _primaryButtonFg(palette);
    final unselectedBg =
        palette.isDark ? palette.surfaceContainerHigh : palette.surfaceContainerLowest;
    final unselectedFg = palette.isDark ? palette.onSurfaceVariant : palette.title;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: selected ? selectedBg : unselectedBg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: selected
                  ? null
                  : Border.all(
                      color: palette.outlineVariant.withValues(alpha: palette.isDark ? 0.2 : 0.4),
                    ),
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

  static Widget providerCard({
    required DashboardPalette palette,
    required String displayName,
    required String roleLabel,
    required String serviceArea,
    required String workingHours,
    required bool isVerified,
    required String initials,
    required String? profileImageUrl,
    required List<String> brandLabels,
    required String? quoteSnippet,
    required VoidCallback onOpenDetail,
    required VoidCallback? onCall,
  }) {
    final cardColor = palette.isDark ? palette.surfaceContainerLow : Colors.white;
    final borderColor = palette.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE3BFB2).withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(radiusCard),
          border: Border.all(color: borderColor),
          boxShadow: palette.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onOpenDetail,
                      borderRadius: BorderRadius.circular(radiusControl),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProviderAvatar(
                            palette: palette,
                            initials: initials,
                            imageUrl: profileImageUrl,
                            isVerified: isVerified,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.manrope(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: palette.title,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _roleChip(palette, roleLabel),
                                    if (serviceArea.isNotEmpty)
                                      Text(
                                        '• $serviceArea',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: palette.body,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: palette.onSurfaceVariant.withValues(alpha: 0.5),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onCall != null) ...[
                    const SizedBox(width: 8),
                    _CallButton(palette: palette, onPressed: onCall),
                  ],
                ],
              ),
              if (workingHours.isNotEmpty) ...[
                const SizedBox(height: 14),
                _infoRow(
                  palette: palette,
                  leftLabel: 'Availability',
                  leftValue: workingHours,
                ),
              ],
              if (quoteSnippet != null && quoteSnippet.isNotEmpty) ...[
                const SizedBox(height: 14),
                _quoteBox(palette, quoteSnippet),
              ],
              if (brandLabels.isNotEmpty) ...[
                const SizedBox(height: 14),
                _stockRow(palette, brandLabels),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _roleChip(DashboardPalette palette, String roleLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.primaryContainer.withValues(alpha: palette.isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        roleLabel,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: palette.primaryContainer,
        ),
      ),
    );
  }

  static Widget _infoRow({
    required DashboardPalette palette,
    required String leftLabel,
    required String leftValue,
    String? rightLabel,
    String? rightValue,
    IconData? rightIcon,
  }) {
    final tileBg = palette.isDark ? palette.surfaceContainer : const Color(0xFFF5F5F5);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(radiusControl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leftLabel,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color: palette.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  leftValue,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.title,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        if (rightLabel != null && rightValue != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(radiusControl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rightLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05,
                      color: palette.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (rightIcon != null) ...[
                        Icon(rightIcon, size: 14, color: palette.primaryContainer),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          rightValue,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.title,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Widget _quoteBox(DashboardPalette palette, String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceContainer : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(radiusControl),
        border: Border(
          left: BorderSide(color: palette.primaryContainer, width: 3),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: palette.body,
          height: 1.45,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static Widget _stockRow(DashboardPalette palette, List<String> brands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STOCK',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08,
            color: palette.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: brands.take(5).map((b) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: palette.isDark ? palette.surfaceContainerHigh : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                b,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.title,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Widget emptyState(DashboardPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search_outlined, size: 64, color: palette.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No providers match this filter yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.title,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try "All", adjust your search, or check back as we onboard more providers.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 14, color: palette.body, height: 1.4),
          ),
        ],
      ),
    );
  }

  static Widget loadingIndicator(DashboardPalette palette) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: CircularProgressIndicator(color: palette.primaryContainer),
      ),
    );
  }

  static Widget errorState({
    required DashboardPalette palette,
    required VoidCallback onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: palette.error),
          const SizedBox(height: 16),
          Text(
            'Could not load providers. Try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 15, color: palette.body),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                color: palette.primaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Provider detail ---

  static PreferredSizeWidget detailAppBar({
    required BuildContext context,
    required DashboardPalette palette,
    List<Widget>? trailing,
  }) {
    final barBg = palette.isDark
        ? palette.surface.withValues(alpha: 0.92)
        : const Color(0xFFF9F9F9).withValues(alpha: 0.92);
    final fg = palette.primaryContainer;

    return AppBar(
      backgroundColor: barBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: fg),
        onPressed: () => Navigator.maybePop(context),
      ),
      actions: trailing,
    );
  }

  static Widget detailHero({
    required DashboardPalette palette,
    required String? imageUrl,
    required bool isVerified,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radiusCard),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroPlaceholder(palette),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _heroPlaceholder(palette);
                    },
                  )
                : _heroPlaceholder(palette),
          ),
        ),
        if (isVerified)
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: palette.primaryContainer,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: _primaryButtonFg(palette)),
                  const SizedBox(width: 6),
                  Text(
                    'VERIFIED PROVIDER',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.06,
                      color: _primaryButtonFg(palette),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static Widget _heroPlaceholder(DashboardPalette palette) {
    return Container(
      color: palette.isDark ? palette.surfaceContainerHigh : const Color(0xFFE8E8E8),
      child: Center(
        child: Icon(
          Icons.garage_outlined,
          size: 64,
          color: palette.primaryContainer.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  static Widget detailTitleBlock({
    required DashboardPalette palette,
    required String displayName,
    required String? tradingName,
    required String roleLabel,
    required String locationLine,
    required bool isVerified,
  }) {
    return Column(
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
                    displayName,
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: palette.title,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (tradingName != null && tradingName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tradingName,
                      style: GoogleFonts.manrope(fontSize: 14, color: palette.body),
                    ),
                  ],
                ],
              ),
            ),
            if (isVerified)
              Icon(Icons.verified, color: palette.primaryContainer, size: 28),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _roleChip(palette, roleLabel),
          ],
        ),
        if (locationLine.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: palette.primaryContainer),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  locationLine,
                  style: GoogleFonts.manrope(fontSize: 14, color: palette.body, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static Widget specChipRow({
    required DashboardPalette palette,
    required List<String> labels,
  }) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: palette.primaryContainer.withValues(alpha: palette.isDark ? 0.12 : 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: palette.primaryContainer.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: palette.isDark ? palette.primary : palette.primaryContainer,
            ),
          ),
        );
      }).toList(),
    );
  }

  static Widget primaryCallButton({
    required DashboardPalette palette,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: palette.primaryContainer,
          foregroundColor: _primaryButtonFg(palette),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
          elevation: palette.isDark ? 0 : 2,
          shadowColor: palette.primaryContainer.withValues(alpha: 0.35),
        ),
        icon: const Icon(Icons.phone),
        label: Text(
          'CALL NOW',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.04,
          ),
        ),
      ),
    );
  }

  static Widget secondaryActionRow({
    required DashboardPalette palette,
    required String leftLabel,
    required IconData leftIcon,
    required VoidCallback? onLeft,
    required String rightLabel,
    required IconData rightIcon,
    required VoidCallback? onRight,
    bool rightLoading = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: _secondaryActionCard(
            palette: palette,
            label: leftLabel,
            icon: leftIcon,
            onTap: onLeft,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _secondaryActionCard(
            palette: palette,
            label: rightLabel,
            icon: rightIcon,
            onTap: onRight,
            loading: rightLoading,
          ),
        ),
      ],
    );
  }

  static Widget _secondaryActionCard({
    required DashboardPalette palette,
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return Material(
      color: palette.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radiusCard),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(radiusCard),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radiusCard),
            border: Border.all(
              color: palette.outlineVariant.withValues(alpha: palette.isDark ? 0.15 : 0.3),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.primaryContainer,
                    ),
                  )
                else
                  Icon(icon, color: palette.onSurfaceVariant, size: 26),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.title,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget sectionCard({
    required DashboardPalette palette,
    required String title,
    required Widget child,
    IconData? icon,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: palette.primaryContainer, size: 22),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.title,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.manrope(fontSize: 12, color: palette.body),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  static Widget aboutStatsRow({
    required DashboardPalette palette,
    required List<({String label, String value})> stats,
  }) {
    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.label,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.value,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: palette.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  static Widget trustTile({
    required DashboardPalette palette,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceContainer : palette.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radiusControl),
        border: Border.all(
          color: palette.primaryContainer.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: palette.primaryContainer),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: palette.title,
            ),
          ),
        ],
      ),
    );
  }

  static Widget specChip({
    required DashboardPalette palette,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusControl),
        border: Border.all(color: palette.primaryContainer.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: palette.primaryContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.title,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget galleryThumbnail({
    required DashboardPalette palette,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radiusControl),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: palette.surfaceContainerHigh,
              child: Icon(Icons.broken_image_outlined, color: palette.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }

  static Widget workshopMapPlaceholder({
    required DashboardPalette palette,
    required String address,
    VoidCallback? onDirections,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radiusCard),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette.isDark
                      ? [const Color(0xFF0D1A22), const Color(0xFF1A2830)]
                      : [const Color(0xFF2A3540), const Color(0xFF1A2228)],
                ),
              ),
              child: CustomPaint(painter: _MapGridPainter(palette.primaryContainer)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 32,
            child: Center(
              child: Icon(
                Icons.location_on,
                size: 48,
                color: palette.primaryContainer,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          if (address.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 52,
              child: Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          if (onDirections != null)
            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onDirections,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Get Directions',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget contactListTile({
    required DashboardPalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: palette.primaryContainer),
      title: Text(
        title,
        style: GoogleFonts.montserrat(fontSize: 11, color: palette.onSurfaceVariant),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: palette.primaryContainer,
        ),
      ),
      onTap: onTap,
    );
  }

  static Widget bodyText(DashboardPalette palette, String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 15,
        height: 1.55,
        color: palette.body,
      ),
    );
  }

  static Widget subsectionLabel(DashboardPalette palette, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: palette.onSurfaceVariant,
        ),
      ),
    );
  }

  static Widget businessDetailRow({
    required DashboardPalette palette,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.manrope(fontSize: 14, color: palette.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderAvatar extends StatelessWidget {
  const _ProviderAvatar({
    required this.palette,
    required this.initials,
    required this.imageUrl,
    required this.isVerified,
  });

  final DashboardPalette palette;
  final String initials;
  final String? imageUrl;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: palette.primaryContainer.withValues(alpha: 0.15),
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
          child: imageUrl == null || imageUrl!.isEmpty
              ? Text(
                  initials,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: palette.primaryContainer,
                  ),
                )
              : null,
        ),
        if (isVerified)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                border: Border.all(color: palette.surfaceContainerLowest, width: 2),
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.palette, required this.onPressed});

  final DashboardPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.primaryContainer,
      borderRadius: BorderRadius.circular(ProviderDirectoryUi.radiusControl),
      elevation: palette.isDark ? 0 : 3,
      shadowColor: palette.primaryContainer.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(ProviderDirectoryUi.radiusControl),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.phone,
            color: palette.isDark ? const Color(0xFF1A1A1A) : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
