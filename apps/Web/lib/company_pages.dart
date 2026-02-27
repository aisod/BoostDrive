import 'package:flutter/material.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'About BoostDrive',
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driving Namibia Forward.',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1),
                ),
                SizedBox(height: 32),
                Text(
                  'BoostDrive is Namibia\'s premier digital automotive ecosystem. Founded in 2026, our mission is to simplify vehicle ownership and commerce through technology.',
                  style: TextStyle(fontSize: 18, color: BoostDriveTheme.textDim, height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  'We connect buyers, sellers, and renters in a secure, transparent, and efficient marketplace. Whether you need a spare part for your project car, a rental for your holiday, or are looking to sell your daily driver, BoostDrive provides the tools you need.',
                  style: TextStyle(fontSize: 18, color: BoostDriveTheme.textDim, height: 1.6),
                ),
                SizedBox(height: 48),
                Divider(color: Colors.white10),
                SizedBox(height: 48),
                _StatRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CareersPage extends StatelessWidget {
  const CareersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'Join Our Team',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              children: [
                const Icon(Icons.rocket_launch_outlined, size: 80, color: BoostDriveTheme.primaryColor),
                const SizedBox(height: 32),
                const Text(
                  'Build the Future of Mobility.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We are always looking for passionate engineers, designers, and automotive enthusiasts to join our remote-first team.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: BoostDriveTheme.textDim, height: 1.6),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Current Openings',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      _JobListing(title: 'Senior Flutter Engineer', location: 'Remote (Namibia)'),
                      const Divider(color: Colors.white10, height: 32),
                      _JobListing(title: 'Automotive Data Specialist', location: 'Windhoek'),
                      const Divider(color: Colors.white10, height: 32),
                      _JobListing(title: 'Customer Success Lead', location: 'Remote'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PartnerProgramPage extends StatelessWidget {
  const PartnerProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'Partner Program',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              children: [
                const Icon(Icons.handshake_outlined, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 32),
                const Text(
                  'Grow with BoostDrive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'For dealerships, rental agencies, and parts suppliers. Integrate your inventory directly with our platform and reach thousands of verified customers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: BoostDriveTheme.textDim, height: 1.6),
                ),
                const SizedBox(height: 48),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: BoostDriveTheme.surfaceDark,
                        title: const Text('Coming Soon', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'The Partner Portal is currently invitation-only. Please contact support to request early access.',
                          style: TextStyle(color: BoostDriveTheme.textDim),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  ),
                  child: const Text('Apply for Partnership', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatItem(value: '5K+', label: 'Active Users'),
        _StatItem(value: '1.2K', label: 'Vehicles Listed'),
        _StatItem(value: '24/7', label: 'Support'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: BoostDriveTheme.primaryColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: BoostDriveTheme.textDim),
        ),
      ],
    );
  }
}

class _JobListing extends StatelessWidget {
  final String title;
  final String location;

  const _JobListing({required this.title, required this.location});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(location, style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 14)),
          ],
        ),
        OutlinedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: BoostDriveTheme.surfaceDark,
                title: const Text('Coming Soon', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Our application portal is currently being updated. Please check back soon to apply for this role.',
                  style: TextStyle(color: BoostDriveTheme.textDim),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: BoostDriveTheme.primaryColor)),
                  ),
                ],
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
