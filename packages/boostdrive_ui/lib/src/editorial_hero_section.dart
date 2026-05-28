import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

/// Crossfading hero images confined to the editorial hero image panel.
class HeroImageSlideshow extends StatefulWidget {
  final List<String> images;
  final Duration interval;
  final Duration fadeDuration;
  /// When null, images load from the host app asset bundle (recommended for Web).
  final String? package;

  const HeroImageSlideshow({
    super.key,
    required this.images,
    this.interval = const Duration(seconds: 5),
    this.fadeDuration = const Duration(milliseconds: 900),
    this.package,
  });

  @override
  State<HeroImageSlideshow> createState() => _HeroImageSlideshowState();
}

class _HeroImageSlideshowState extends State<HeroImageSlideshow> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.images.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: widget.fadeDuration,
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: Image.asset(
            widget.images[_index],
            key: ValueKey<String>(widget.images[_index]),
            package: widget.package,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class EditorialHeroSection extends StatelessWidget {
  static const double navBarHeight = 65;

  final String title;
  final String subtitle;
  final String hashtag;
  final List<String> backgroundImages;
  final VoidCallback onReadMore;
  final Widget? navBar;
  final String? attributionText;
  final String? attributionUrl;
  final VoidCallback? onAttributionTap;
  final Duration slideshowInterval;
  final String? imagePackage;
  /// Height of chrome above the hero (e.g. mobile [AppBar]). Desktop uses 0.
  final double topChromeHeight;

  const EditorialHeroSection({
    super.key,
    required this.title,
    required this.subtitle,
    this.hashtag = "#BoostDrive",
    required this.backgroundImages,
    required this.onReadMore,
    this.navBar,
    this.attributionText,
    this.attributionUrl,
    this.onAttributionTap,
    this.slideshowInterval = const Duration(seconds: 5),
    this.imagePackage,
    this.topChromeHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;
    // Fill the viewport from the nav/task bar down to the bottom of the screen.
    final heroHeight = size.height - topChromeHeight;

    return Container(
      width: double.infinity,
      height: heroHeight,
      color: Colors.white,
      child: Stack(
        children: [
          // 1. Right Image Section
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: isMobile ? size.width : size.width * 0.7,
            child: ClipRect(
              child: Opacity(
                opacity: isMobile ? 0.3 : 1.0,
                child: HeroImageSlideshow(
                  images: backgroundImages,
                  interval: slideshowInterval,
                  package: imagePackage,
                ),
              ),
            ),
          ),

          // 2. Left White Content Column
          if (!isMobile)
            Positioned(
              left: 0,
              top: navBarHeight,
              bottom: 0,
              width: size.width * 0.45,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(56, 32, 56, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    
                    // Hashtag
                    Text(
                      hashtag,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Headline
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Subtitle
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black45,
                        height: 1.5,
                      ),
                    ),
                    if (_hasAttribution) ...[
                      const SizedBox(height: 12),
                      _buildAttributionLink(fontSize: 14),
                    ],
                    const SizedBox(height: 36),
                    
                    // READ MORE (BoostDrive Orange button)
                    _buildReadMoreButton(),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),

          // 3. Mobile Content (Overlay)
          if (isMobile)
             Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hashtag,
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: Colors.black,
                      ),
                    ),
                    if (_hasAttribution) ...[
                      const SizedBox(height: 10),
                      _buildAttributionLink(fontSize: 13),
                    ],
                    const SizedBox(height: 16),
                    _buildReadMoreButton(),
                  ],
                ),
              ),
            ),

          // 4. CHARCOAL NAVIGATION BAR
          if (!isMobile)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: navBarHeight,
                color: BoostDriveTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: navBar ?? const Row(
                  children: [
                    Spacer(),
                    Icon(Icons.menu, color: Colors.white),
                  ],
                ),
              ),
            ),


        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "BoostDrive",
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: Colors.black,
          ),
        ),
        Text(
          "TAGLINE HERE",
          style: GoogleFonts.poppins(
            fontSize: 10,
            letterSpacing: 2,
            color: BoostDriveTheme.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildReadMoreButton() {
    return ElevatedButton(
      onPressed: onReadMore,
      style: ElevatedButton.styleFrom(
        backgroundColor: BoostDriveTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: const RoundedRectangleBorder(),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow, size: 16),
          const SizedBox(width: 12),
          Text(
            "EXPLORE NOW",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasAttribution =>
      attributionText != null &&
      attributionText!.trim().isNotEmpty &&
      attributionUrl != null &&
      attributionUrl!.trim().isNotEmpty &&
      onAttributionTap != null;

  Widget _buildAttributionLink({required double fontSize}) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          attributionText!,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        InkWell(
          onTap: onAttributionTap,
          child: Text(
            attributionUrl!,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: BoostDriveTheme.primaryColor,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: BoostDriveTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
