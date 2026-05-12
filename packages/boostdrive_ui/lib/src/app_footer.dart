import 'package:flutter/material.dart';
import 'theme.dart';

class AppFooter extends StatelessWidget {
  final Function(String section, String title)? onLinkTap;

  const AppFooter({super.key, this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final footerBg = isDark ? BoostDriveTheme.backgroundDark.withValues(alpha: 0.92) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1D2939);
    final bodyColor = isDark ? BoostDriveTheme.textDim : const Color(0xFF667085);
    final dividerColor = isDark ? const Color(0x22FF6600) : const Color(0xFFE4E7EC);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEAECEF);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: footerBg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 80, 
        horizontal: isMobile ? 24 : 64,
      ),
      child: Column(
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAboutSection(
                  titleColor: titleColor,
                  bodyColor: bodyColor,
                ),
                // copied theme colors from parent section
                const SizedBox(height: 48),
                _FooterColumn(
                  title: 'Marketplace',
                  links: const ['Buy Parts', 'Rent a Car', 'Sell Your Vehicle', 'New Arrivals'],
                  onTap: (val) => onLinkTap?.call('Marketplace', val),
                  titleColor: titleColor,
                  linkColor: bodyColor,
                ),
                const SizedBox(height: 32),
                _FooterColumn(
                  title: 'Company',
                  links: const ['About Us', 'Contact', 'Careers', 'Partner Program'],
                  onTap: (val) => onLinkTap?.call('Company', val),
                  titleColor: titleColor,
                  linkColor: bodyColor,
                ),
                const SizedBox(height: 32),
                _FooterColumn(
                  title: 'Support',
                  links: const ['Safety Center', 'Terms of Service', 'Privacy Policy', 'FAQ'],
                  onTap: (val) => onLinkTap?.call('Support', val),
                  titleColor: titleColor,
                  linkColor: bodyColor,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & About
                Expanded(
                  flex: 3,
                  child: _buildAboutSection(
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                ),
                const Spacer(),
                Expanded(
                  flex: 2,
                  child: _FooterColumn(
                    title: 'Marketplace',
                    links: const ['Buy Parts', 'Rent a Car', 'Sell Your Vehicle', 'New Arrivals'],
                    onTap: (val) => onLinkTap?.call('Marketplace', val),
                    titleColor: titleColor,
                    linkColor: bodyColor,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _FooterColumn(
                    title: 'Company',
                    links: const ['About Us', 'Contact', 'Careers', 'Partner Program'],
                    onTap: (val) => onLinkTap?.call('Company', val),
                    titleColor: titleColor,
                    linkColor: bodyColor,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _FooterColumn(
                    title: 'Support',
                    links: const ['Safety Center', 'Terms of Service', 'Privacy Policy', 'FAQ'],
                    onTap: (val) => onLinkTap?.call('Support', val),
                    titleColor: titleColor,
                    linkColor: bodyColor,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 80),
          Divider(color: dividerColor),
          const SizedBox(height: 32),
          if (isMobile)
            Column(
              children: [
                Text(
                  '© 2026 BoostDrive Namibia. All rights reserved.',
                  style: TextStyle(color: bodyColor, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 14, color: titleColor),
                    const SizedBox(width: 4),
                    Text(
                      'Windhoek, Namibia',
                      style: TextStyle(color: bodyColor, fontSize: 13),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© 2026 BoostDrive Namibia. All rights reserved.',
                  style: TextStyle(color: bodyColor, fontSize: 13),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: titleColor),
                    const SizedBox(width: 4),
                    Text(
                      'Windhoek, Namibia',
                      style: TextStyle(color: bodyColor, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAboutSection({
    required Color titleColor,
    required Color bodyColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BoostDrive',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'The leading automotive platform in Namibia. Buy parts, rent vehicles, and sell cars with confidence.',
          style: TextStyle(color: bodyColor, height: 1.6),
        ),
        // SOCIALS REMOVED
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> links;
  final Function(String) onTap;
  final Color titleColor;
  final Color linkColor;

  const _FooterColumn({
    required this.title,
    required this.links,
    required this.onTap,
    required this.titleColor,
    required this.linkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => onTap(link),
                child: Text(
                  link,
                  style: TextStyle(color: linkColor, fontSize: 14),
                ),
              ),
            )),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  const _SocialButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Color(0x22FF6600)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
