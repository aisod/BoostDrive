import 'package:flutter/material.dart';
import 'theme.dart';

class HeroSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final String? backgroundImage;

  const HeroSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 600),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundImage != null ? BoostDriveTheme.backgroundDark : Colors.transparent,
      ),
      child: Stack(
        children: [
          // Background Image
          if (backgroundImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.6,
                child: backgroundImage!.startsWith('http')
                    ? Image.network(
                        backgroundImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Color(0x22FF6600)),
                      )
                    : Image.asset(
                        backgroundImage!,
                        package: 'boostdrive_ui',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: BoostDriveTheme.backgroundDark),
                      ),
              ),
            ),
          
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    BoostDriveTheme.backgroundDark.withValues(alpha: 0.95),
                    BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
                    BoostDriveTheme.backgroundDark.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 600 ? 16.0 : 48.0, 
              vertical: MediaQuery.of(context).size.width < 600 ? 40.0 : 80.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'NAMIBIA\'S #1 AUTOMOTIVE HUB',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 32 : 64,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 20,
                          color: BoostDriveTheme.textDim,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: actions,
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
}
