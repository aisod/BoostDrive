import 'package:flutter/material.dart';
import 'theme.dart';

class AppFooter extends StatelessWidget {
  final Function(String section, String title)? onLinkTap;

  const AppFooter({super.key, this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
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
                _buildAboutSection(),
                const SizedBox(height: 48),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FooterColumn(
                        title: 'Marketplace',
                        links: const ['Buy Parts', 'Rent a Car', 'Sell Your Vehicle', 'New Arrivals'],
                        onTap: (link) => onLinkTap?.call('Marketplace', link),
                      ),
                    ),
                    Expanded(
                      child: _FooterColumn(
                        title: 'Company',
                        links: const ['About Us', 'Contact', 'Careers', 'Partner Program'],
                        onTap: (link) => onLinkTap?.call('Company', link),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _FooterColumn(
                  title: 'Support',
                  links: const ['Safety Center', 'Terms of Service', 'Privacy Policy', 'FAQ'],
                  onTap: (link) => onLinkTap?.call('Support', link),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & About
                Expanded(
                  flex: 2,
                  child: _buildAboutSection(),
                ),
                const Spacer(),
                // Links Section
                _FooterColumn(
                  title: 'Marketplace',
                  links: const ['Buy Parts', 'Rent a Car', 'Sell Your Vehicle', 'New Arrivals'],
                  onTap: (link) => onLinkTap?.call('Marketplace', link),
                ),
                const SizedBox(width: 48),
                _FooterColumn(
                  title: 'Company',
                  links: const ['About Us', 'Contact', 'Careers', 'Partner Program'],
                  onTap: (link) => onLinkTap?.call('Company', link),
                ),
                const SizedBox(width: 48),
                _FooterColumn(
                  title: 'Support',
                  links: const ['Safety Center', 'Terms of Service', 'Privacy Policy', 'FAQ'],
                  onTap: (link) => onLinkTap?.call('Support', link),
                ),
              ],
            ),
          const SizedBox(height: 80),
          const Divider(color: Colors.white10),
          const SizedBox(height: 32),
          if (isMobile)
            const Column(
              children: [
                Text(
                  '© 2026 BoostDrive Namibia. All rights reserved.',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    const Text(
                      'Windhoek, Namibia',
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                    ),
                  ],
                ),
              ],
            )
          else
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© 2026 BoostDrive Namibia. All rights reserved.',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                ),
                const Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Windhoek, Namibia',
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BoostDrive',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'The leading automotive platform in Namibia. Buy parts, rent vehicles, and sell cars with confidence.',
          style: TextStyle(color: BoostDriveTheme.textDim, height: 1.6),
        ),
        SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SocialButton(icon: Icons.facebook),
            _SocialButton(icon: Icons.camera_alt),
            _SocialButton(icon: Icons.alternate_email),
          ],
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> links;
  final Function(String) onTap;

  const _FooterColumn({
    required this.title,
    required this.links,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
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
                  style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 14),
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
        border: Border.all(color: Colors.white10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
