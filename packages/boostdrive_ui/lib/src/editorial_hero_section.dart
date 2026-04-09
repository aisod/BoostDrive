import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme.dart';

class EditorialHeroSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String hashtag;
  final String backgroundImage;
  final VoidCallback onReadMore;
  final Widget? navBar;

  const EditorialHeroSection({
    super.key,
    required this.title,
    required this.subtitle,
    this.hashtag = "#BoostDrive",
    required this.backgroundImage,
    required this.onReadMore,
    this.navBar,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Container(
      width: double.infinity,
      height: isMobile ? 800 : 900,
      color: Colors.white,
      child: Stack(
        children: [
          // 1. Right Image Section
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: isMobile ? size.width : size.width * 0.7,
            child: Opacity(
              opacity: isMobile ? 0.3 : 1.0,
              child: Image.asset(
                backgroundImage,
                package: 'boostdrive_ui',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Left White Content Column
          if (!isMobile)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: size.width * 0.45,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Redundant Logo Removed - Now in Nav Bar
                    const SizedBox(height: 20),
                    const Spacer(),
                    
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
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Subtitle
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black45,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // READ MORE (BoostDrive Orange button)
                    _buildReadMoreButton(),
                    
                    const Spacer(),
                  ],
                ),
              ),
            ),

          // 3. Mobile Content (Overlay)
          if (isMobile)
             Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      hashtag,
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
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
                height: 80,
                color: BoostDriveTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 40),
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
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
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
}
