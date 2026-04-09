import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class GeometricHeroSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final String backgroundImage;
  final String badgeText;
  final Widget? navBar;

  const GeometricHeroSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.backgroundImage,
    this.badgeText = "NAMIBIA'S #1 AUTOMOTIVE HUB",
    this.navBar,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      height: isMobile ? 700 : 850,
      clipBehavior: Clip.none,
      child: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              package: 'boostdrive_ui',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.1),
            ),
          ),
          
          // 2. Base Geometric Layers (The intricate paths from template image_2)
          Positioned.fill(
            child: CustomPaint(
              painter: BoostDriveHeroPainter(),
            ),
          ),

          // 3. Dark Top Navigation Bar Strip
          if (!isMobile && navBar != null)
            Positioned(
              top: 0,
              left: 400, // Matching the template's right-aligned nav strip
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF232323).withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(50)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40),
                alignment: Alignment.centerRight,
                child: navBar,
              ),
            ),

          // 4. Content Layer
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24.0 : 80.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60), // Space for nav bar
                
                // Headline (Aggressive bold as seen in template)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 600),
                  child: Text(
                    title.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 42 : 88,
                      fontWeight: FontWeight.w900,
                      height: 0.9,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Subtitle
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 500),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 14 : 18,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Actions (White Pill buttons as seen in template)
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: actions,
                ),
              ],
            ),
          ),

          // 5. Social Icons (Bottom Left)
          if (!isMobile)
            Positioned(
              left: 50,
              bottom: 40,
              child: Row(
                children: [
                  _SocialIcon(icon: Icons.facebook),
                  const SizedBox(width: 14),
                  _SocialIcon(icon: Icons.camera_alt),
                  const SizedBox(width: 14),
                  _SocialIcon(icon: Icons.alternate_email),
                  const SizedBox(width: 14),
                  _SocialIcon(icon: Icons.share),
                ],
              ),
            ),

          // 6. "YOUR LOGO" matching text (Bottom Right)
          if (!isMobile)
             Positioned(
              right: 60,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'BOOST',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'DRIVE',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      fontSize: 18,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  const _SocialIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: Colors.white,
      size: 18,
    );
  }
}

class BoostDriveHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final orange = const Color(0xFFFF5F00); // Official Orange
    final orangeLighter = const Color(0xFFFF5F00).withValues(alpha: 0.7);
    final dark = const Color(0xFFFFFFFF);
    final darkGrey = const Color(0xFF2C2C2C);

    final paintOrange = Paint()..color = orange..style = PaintingStyle.fill;
    final paintOrangeLighter = Paint()..color = orangeLighter..style = PaintingStyle.fill;
    final paintDark = Paint()..color = dark..style = PaintingStyle.fill;
    final paintDarkGrey = Paint()..color = darkGrey..style = PaintingStyle.fill;

    // 1. Far Left Dark Background triangle
    var path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(size.width * 0.2, 0);
    path1.lineTo(size.width * 0.1, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paintDark);

    // 2. Main Large Left Wedge (As seen in image_2)
    var path2 = Path();
    path2.moveTo(0, size.height * 0.1);
    path2.lineTo(size.width * 0.45, size.height * 0.3);
    path2.lineTo(size.width * 0.25, size.height * 0.9);
    path2.lineTo(0, size.height * 0.7);
    path2.close();
    canvas.drawPath(path2, paintOrange);

    // 3. Bottom Left Small Triangle
    var path3 = Path();
    path3.moveTo(0, size.height * 0.7);
    path3.lineTo(size.width * 0.15, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paintOrangeLighter);

    // 4. Overlapping center-bottom triangle
    var path4 = Path();
    path4.moveTo(size.width * 0.25, size.height);
    path4.lineTo(size.width * 0.5, size.height);
    path4.lineTo(size.width * 0.4, size.height * 0.7);
    path4.close();
    canvas.drawPath(path4, paintDarkGrey);

    // 5. Large Right Triangle (Bottom right accent)
    var path5 = Path();
    path5.moveTo(size.width, size.height * 0.5);
    path5.lineTo(size.width, size.height);
    path5.lineTo(size.width * 0.7, size.height);
    path5.close();
    canvas.drawPath(path5, paintOrange);

    // 6. Top Right Strip (Dark)
    var path6 = Path();
    path6.moveTo(size.width * 0.5, 0);
    path6.lineTo(size.width, 0);
    path6.lineTo(size.width, size.height * 0.15);
    path6.lineTo(size.width * 0.7, size.height * 0.1);
    path6.close();
    canvas.drawPath(path6, paintDark);

    // 7. Diagonal Decoration Patterns
    _drawPattern(canvas, Offset(size.width * 0.85, 100), 10);
    _drawPattern(canvas, Offset(size.width * 0.1, size.height * 0.85), 12);
    _drawPattern(canvas, Offset(size.width * 0.45, size.height * 0.92), 8);
  }

  void _drawPattern(Canvas canvas, Offset origin, int lines) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.2;
    
    for (int i = 0; i < lines; i++) {
       canvas.drawLine(
         Offset(origin.dx + (i * 10), origin.dy),
         Offset(origin.dx + (i * 10) + 40, origin.dy + 40),
         p
       );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
