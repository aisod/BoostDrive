import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boost_drive_web/public_page_widgets.dart';
import 'package:boostdrive_core/boostdrive_core.dart';

/// Theme-aware tokens for listing detail pages (buyer, guest, owner).
class ListingDetailPalette {
  final PublicPagePalette base;

  const ListingDetailPalette(this.base);

  factory ListingDetailPalette.of(BuildContext context) =>
      ListingDetailPalette(PublicPagePalette.of(context));

  bool get isDark => base.isDark;

  Color get pageBackground => base.pageBackground;
  Color get cardBackground => base.cardBackground;
  Color get sectionBackground => base.sectionBackground;
  Color get elevatedBackground => base.elevatedCardBackground;
  Color get borderColor => base.borderColor;
  Color get titleColor => base.titleColor;
  Color get bodyColor => base.bodyColor;
  Color get mutedColor => base.mutedColor;
  Color get primary => base.primary;
  Color get primaryText => base.primaryText;
  Color get navBarTint => isDark ? const Color(0xFF515F78) : const Color(0xFFD2E0FE);
  Color get secondaryFixed => isDark ? const Color(0xFF627882) : const Color(0xFFCFE6F2);
  Color get errorContainer => isDark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6);
  Color get onErrorContainer => isDark ? const Color(0xFFFFDAD6) : const Color(0xFF93000A);

  List<BoxShadow> get ambientLow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  List<BoxShadow> get ambientHigh => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Horizontal gallery with arrows, dots, and optional thumbnail strip — uses listing [imageUrls] only.
class ListingImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final bool showThumbnails;
  final BorderRadius borderRadius;

  const ListingImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 400,
    this.showThumbnails = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<ListingImageGallery> createState() => _ListingImageGalleryState();
}

class _ListingImageGalleryState extends State<ListingImageGallery> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _urls => widget.imageUrls.where((u) => u.trim().isNotEmpty).toList();

  void _goTo(int index) {
    if (index < 0 || index >= _urls.length) return;
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ListingDetailPalette.of(context);
    final hasMultiple = _urls.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: widget.borderRadius,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: palette.elevatedBackground,
              boxShadow: palette.ambientLow,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_urls.isEmpty)
                  Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 72,
                      color: palette.mutedColor.withValues(alpha: 0.5),
                    ),
                  )
                else
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemCount: _urls.length,
                    itemBuilder: (_, i) => Image.network(
                      _urls[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: palette.elevatedBackground,
                        child: Icon(Icons.broken_image_outlined, size: 64, color: palette.mutedColor),
                      ),
                    ),
                  ),
                if (hasMultiple) ...[
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _GalleryArrow(
                        icon: Icons.chevron_left,
                        onTap: () => _goTo((_index - 1 + _urls.length) % _urls.length),
                        palette: palette,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _GalleryArrow(
                        icon: Icons.chevron_right,
                        onTap: () => _goTo((_index + 1) % _urls.length),
                        palette: palette,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _urls.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _index ? 10 : 8,
                          height: i == _index ? 10 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: i == _index ? 1 : 0.4),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.showThumbnails && _urls.length > 1) ...[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const thumbCount = 4;
              final visible = _urls.length > thumbCount ? thumbCount - 1 : _urls.length;
              final extra = _urls.length - visible;
              return Row(
                children: [
                  for (var i = 0; i < visible; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < visible - 1 || extra > 0 ? 12 : 0),
                        child: _ThumbnailTile(
                          url: _urls[i],
                          selected: _index == i,
                          onTap: () => _goTo(i),
                          palette: palette,
                        ),
                      ),
                    ),
                  if (extra > 0)
                    Expanded(
                      child: _ThumbnailTile(
                        url: _urls[visible],
                        selected: _index >= visible,
                        overlayText: '+$extra',
                        onTap: () => _goTo(visible),
                        palette: palette,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _GalleryArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ListingDetailPalette palette;

  const _GalleryArrow({
    required this.icon,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.cardBackground.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: palette.titleColor),
        ),
      ),
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  final String url;
  final bool selected;
  final String? overlayText;
  final VoidCallback onTap;
  final ListingDetailPalette palette;

  const _ThumbnailTile({
    required this.url,
    required this.selected,
    required this.onTap,
    required this.palette,
    this.overlayText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? palette.primary : palette.borderColor.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
            boxShadow: palette.ambientLow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: palette.elevatedBackground,
                  child: Icon(Icons.broken_image, color: palette.mutedColor, size: 28),
                ),
              ),
              if (overlayText != null)
                Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  alignment: Alignment.center,
                  child: Text(
                    overlayText!,
                    style: GoogleFonts.montserrat(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListingSpecCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ListingSpecCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ListingDetailPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderColor.withValues(alpha: 0.35)),
        boxShadow: palette.ambientLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.primary, size: 28),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.bodyColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: palette.titleColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class ListingDetailBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const ListingDetailBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ListingDetailPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.sectionBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? palette.bodyColor,
        ),
      ),
    );
  }
}

class ListingSectionTitle extends StatelessWidget {
  final String title;

  const ListingSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final palette = ListingDetailPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: palette.primaryText,
          letterSpacing: -0.01,
        ),
      ),
    );
  }
}

class ListingDescriptionPanel extends StatelessWidget {
  final String title;
  final String body;

  const ListingDescriptionPanel({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ListingDetailPalette.of(context);
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingSectionTitle(title: title),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.borderColor.withValues(alpha: 0.25)),
          ),
          child: Text(
            body,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              height: 1.6,
              color: palette.bodyColor,
            ),
          ),
        ),
      ],
    );
  }
}

class ListingFitmentGrid extends StatelessWidget {
  final Map<String, dynamic> fitment;
  final Product product;

  const ListingFitmentGrid({
    super.key,
    required this.fitment,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ListingDetailPalette.of(context);
    final entries = <(String, String)>[
      if (fitment['make'] != null) ('Make', '${fitment['make']}'),
      if (fitment['model'] != null) ('Model', '${fitment['model']}'),
      if (fitment['year'] != null) ('Year', '${fitment['year']}'),
      ('Condition', product.condition.toUpperCase()),
      ('Location', product.location),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingSectionTitle(
          title: product.category == 'part' ? 'Vehicle Fitment' : 'Vehicle Fitment Details',
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: entries
              .map(
                (e) => SizedBox(
                  width: 160,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.sectionBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.$1,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: palette.mutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.$2,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class ListingOwnerAnalyticsBar extends StatelessWidget {
  final Product product;

  const ListingOwnerAnalyticsBar({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final palette = ListingDetailPalette.of(context);
    final clicks = product.clickCount ?? 0;
    final saves = product.saveCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.sectionBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.visibility_outlined, color: palette.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listing Performance',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: palette.mutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Clicks: $clicks',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: palette.titleColor,
                  ),
                ),
              ],
            ),
          ),
          _MiniStat(label: 'Saved', value: '$saves', palette: palette),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final ListingDetailPalette palette;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 12, color: palette.mutedColor)),
          Text(value, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: palette.titleColor)),
        ],
      ),
    );
  }
}

String listingBackLabel(String category) {
  switch (category) {
    case 'part':
      return 'Back to Parts Marketplace';
    case 'rental':
      return 'Back to Rental Marketplace';
    default:
      return 'Back to Marketplace';
  }
}

List<ListingSpecCard> listingSpecCardsForProduct(Product product) {
  final condition = product.condition.isNotEmpty ? product.condition.toUpperCase() : '—';
  switch (product.category) {
    case 'rental':
      return [
        ListingSpecCard(icon: Icons.event_seat_outlined, label: 'Capacity', value: product.subtitle.isNotEmpty ? product.subtitle : 'See description'),
        ListingSpecCard(icon: Icons.settings_outlined, label: 'Transmission', value: condition),
        ListingSpecCard(icon: Icons.location_on_outlined, label: 'Pickup', value: product.location),
      ];
    case 'part':
      return [
        ListingSpecCard(icon: Icons.verified_outlined, label: 'Condition', value: condition),
        ListingSpecCard(icon: Icons.location_on_outlined, label: 'Location', value: product.location),
        ListingSpecCard(
          icon: Icons.build_outlined,
          label: 'Compatibility',
          value: product.fitment != null
              ? '${product.fitment!['make'] ?? ''} ${product.fitment!['model'] ?? ''}'.trim()
              : (product.subtitle.isNotEmpty ? product.subtitle : 'See fitment'),
        ),
      ];
    default:
      return [
        ListingSpecCard(
          icon: Icons.speed_outlined,
          label: 'Highlights',
          value: product.subtitle.isNotEmpty ? product.subtitle : 'See description',
        ),
        ListingSpecCard(icon: Icons.fact_check_outlined, label: 'Condition', value: condition),
        ListingSpecCard(icon: Icons.location_on_outlined, label: 'Location', value: product.location),
      ];
  }
}
