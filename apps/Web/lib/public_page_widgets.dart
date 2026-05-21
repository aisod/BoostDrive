import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

class PublicPagePalette {
  final bool isDark;
  final Color pageBackground;
  final Color sectionBackground;
  final Color cardBackground;
  final Color elevatedCardBackground;
  final Color borderColor;
  final Color titleColor;
  final Color bodyColor;
  final Color mutedColor;
  final Color fieldBackground;

  const PublicPagePalette({
    required this.isDark,
    required this.pageBackground,
    required this.sectionBackground,
    required this.cardBackground,
    required this.elevatedCardBackground,
    required this.borderColor,
    required this.titleColor,
    required this.bodyColor,
    required this.mutedColor,
    required this.fieldBackground,
  });

  Color get primary => isDark ? const Color(0xFFF95E14) : const Color(0xFFCD4700);
  Color get primaryText => isDark ? const Color(0xFFFFB59A) : const Color(0xFFA43700);
  Color get onPrimaryContainer => isDark ? const Color(0xFF4F1700) : const Color(0xFFFFFBFF);

  factory PublicPagePalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PublicPagePalette(
      isDark: isDark,
      pageBackground: isDark ? const Color(0xFF09151B) : const Color(0xFFF9F9F9),
      sectionBackground: isDark ? const Color(0xFF121D24) : const Color(0xFFF3F3F3),
      cardBackground: isDark ? const Color(0xFF162128) : Colors.white,
      elevatedCardBackground: isDark ? const Color(0xFF202B33) : const Color(0xFFEEEEEE),
      borderColor: isDark ? const Color(0xFF5A4138) : const Color(0xFFE3BFB2),
      titleColor: isDark ? const Color(0xFFD8E4EE) : const Color(0xFF1A1C1C),
      bodyColor: isDark ? const Color(0xFFE3BFB2) : const Color(0xFF5A4138),
      mutedColor: isDark ? const Color(0xFFAA8A7E) : const Color(0xFF8F7066),
      fieldBackground: isDark ? const Color(0xFF2B363E) : const Color(0xFFE2E2E2),
    );
  }
}

class PublicPageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const PublicPageContainer({
    super.key,
    required this.child,
    this.maxWidth = 1180,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32, vertical: isMobile ? 28 : 48),
          child: child,
        ),
      ),
    );
  }
}

class PublicBackLink extends StatelessWidget {
  final VoidCallback? onPressed;

  const PublicBackLink({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed ?? () => Navigator.maybePop(context),
        icon: Icon(Icons.arrow_back, color: palette.titleColor, size: 18),
        label: Text(
          'Back',
          style: GoogleFonts.montserrat(
            color: palette.titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class PublicPageTitle extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PublicPageTitle({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: palette.primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 32 : 48,
                  fontWeight: FontWeight.w800,
                  color: palette.titleColor,
                  letterSpacing: -1.2,
                  height: 1.05,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 15 : 18,
              color: palette.bodyColor,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }
}

class PublicSplitSection extends StatelessWidget {
  final Widget leading;
  final Widget trailing;
  final bool imageFirstOnMobile;

  const PublicSplitSection({
    super.key,
    required this.leading,
    required this.trailing,
    this.imageFirstOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: imageFirstOnMobile
            ? [trailing, const SizedBox(height: 24), leading]
            : [leading, const SizedBox(height: 24), trailing],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: leading),
        const SizedBox(width: 32),
        Expanded(child: trailing),
      ],
    );
  }
}

class PublicNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double aspectRatio;
  final double borderRadius;

  const PublicNetworkImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 4 / 3,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: palette.elevatedCardBackground,
            child: Icon(Icons.image_outlined, color: palette.mutedColor, size: 48),
          ),
        ),
      ),
    );
  }
}

class PublicPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final IconData? icon;

  const PublicPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expanded = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimaryContainer,
        elevation: palette.isDark ? 4 : 2,
        shadowColor: palette.primary.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
        ],
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class PublicOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PublicOutlinedButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.titleColor,
        side: BorderSide(color: palette.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
    );
  }
}

class PublicOrangeBand extends StatelessWidget {
  final String title;
  final String body;
  final Widget? child;

  const PublicOrangeBand({
    super.key,
    required this.title,
    required this.body,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: palette.onPrimaryContainer,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.montserrat(
              color: palette.onPrimaryContainer.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.55,
            ),
          ),
          if (child != null) ...[const SizedBox(height: 20), child!],
        ],
      ),
    );
  }
}

class PublicFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool highlighted;

  const PublicFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: highlighted ? palette.primary : palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: highlighted ? palette.primary : palette.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlighted
                  ? palette.onPrimaryContainer.withValues(alpha: 0.12)
                  : palette.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: highlighted ? palette.onPrimaryContainer : palette.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: highlighted ? palette.onPrimaryContainer : palette.titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              height: 1.55,
              color: highlighted
                  ? palette.onPrimaryContainer.withValues(alpha: 0.88)
                  : palette.bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}

class PublicFaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const PublicFaqTile({super.key, required this.question, required this.answer});

  @override
  State<PublicFaqTile> createState() => _PublicFaqTileState();
}

class _PublicFaqTileState extends State<PublicFaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return PublicPageSection(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          iconColor: palette.primaryText,
          collapsedIconColor: palette.mutedColor,
          title: Text(
            widget.question,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.titleColor,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.answer,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  height: 1.6,
                  color: palette.bodyColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PublicLegalSection extends StatelessWidget {
  final String title;
  final String body;
  final int? index;

  const PublicLegalSection({
    super.key,
    required this.title,
    required this.body,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index != null ? '$index. $title' : title,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              height: 1.7,
              color: palette.bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}

class PublicPageSection extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;

  const PublicPageSection({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: elevated ? palette.elevatedCardBackground : palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.borderColor),
        boxShadow: [
          BoxShadow(
            color: palette.isDark
                ? Colors.black.withValues(alpha: 0.16)
                : const Color(0xFFD7C8BF).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PublicHeroBanner extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String imageUrl;
  final Widget? child;

  const PublicHeroBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: palette.cardBackground,
          border: Border.all(color: palette.borderColor),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BoostDriveTheme.primaryColor.withValues(alpha: 0.95),
                        const Color(0xFF241C18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.62),
                      Colors.black.withValues(alpha: 0.24),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 24 : 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      eyebrow,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      title,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: isMobile ? 34 : 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.4,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: isMobile ? 15 : 17,
                        height: 1.6,
                      ),
                    ),
                  ),
                  if (child != null) ...[
                    const SizedBox(height: 28),
                    child!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PublicSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final IconData icon;
  final bool filledLight;

  const PublicSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.icon = Icons.search,
    this.filledLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: palette.titleColor, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: palette.mutedColor),
        prefixIcon: Icon(icon, color: BoostDriveTheme.primaryColor),
        filled: true,
        fillColor: filledLight ? Colors.white : palette.fieldBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: BoostDriveTheme.primaryColor, width: 1.2),
        ),
      ),
    );
  }
}

class PublicDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final String hintText;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const PublicDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.hintText,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.mutedColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: palette.fieldBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: palette.cardBackground,
              icon: Icon(Icons.keyboard_arrow_down, color: palette.mutedColor),
              style: TextStyle(
                color: palette.titleColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              hint: Text(
                hintText,
                style: TextStyle(color: palette.mutedColor, fontSize: 13),
              ),
              items: options
                  .map((option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(_humanize(option)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  String _humanize(String raw) {
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class PublicStatCard extends StatelessWidget {
  final String label;
  final String value;

  const PublicStatCard({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.fieldBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: BoostDriveTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: palette.bodyColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class PublicSectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const PublicSectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: palette.titleColor,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            color: palette.bodyColor,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class PublicFeedbackState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const PublicFeedbackState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return PublicPageSection(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: BoostDriveTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: palette.titleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: palette.bodyColor,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
