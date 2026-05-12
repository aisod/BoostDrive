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

  factory PublicPagePalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PublicPagePalette(
      isDark: isDark,
      pageBackground: isDark ? const Color(0xFF101B22) : const Color(0xFFF8F3F0),
      sectionBackground: isDark ? const Color(0xFF132028) : const Color(0xFFFFFBF8),
      cardBackground: isDark ? const Color(0xFF18242C) : Colors.white,
      elevatedCardBackground: isDark ? const Color(0xFF1D2B34) : const Color(0xFFF3E7DE),
      borderColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE9DED8),
      titleColor: isDark ? Colors.white : const Color(0xFF1F1A17),
      bodyColor: isDark ? const Color(0xFFB9C6CF) : const Color(0xFF6D635D),
      mutedColor: isDark ? const Color(0xFF8CA0AD) : const Color(0xFF8F847C),
      fieldBackground: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF7EEE8),
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
