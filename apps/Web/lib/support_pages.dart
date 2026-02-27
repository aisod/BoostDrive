import 'package:flutter/material.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

class SafetyCenterPage extends StatelessWidget {
  const SafetyCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'Safety Center',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSafetyTip(
                  icon: Icons.verified_user_outlined,
                  title: 'Verify Before You Buy',
                  content: 'Always inspect the vehicle or part in person before making any payments. Use our messaging system to ask detailed questions.',
                ),
                const SizedBox(height: 32),
                _buildSafetyTip(
                  icon: Icons.chat_bubble_outline,
                  title: 'Keep Chat on BoostDrive',
                  content: 'Never share personal financial information or move conversations to other platforms. Our in-app chat is secure and monitored for your safety.',
                ),
                const SizedBox(height: 32),
                _buildSafetyTip(
                  icon: Icons.warning_amber_rounded,
                  title: 'Spotting Scams',
                  content: 'Be wary of sellers asking for deposits without viewing the item, or prices that seem too good to be true.',
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emergency_share, color: Colors.red, size: 32),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Emergency Assistance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('If you are in immediate danger, please call 112 or local authorities immediately.', style: TextStyle(color: BoostDriveTheme.textDim)),
                          ],
                        ),
                      ),
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

  Widget _buildSafetyTip({required IconData icon, required String title, required String content}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BoostDriveTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: BoostDriveTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(content, style: const TextStyle(fontSize: 16, color: BoostDriveTheme.textDim, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'Terms of Service',
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last Updated: February 2026', style: TextStyle(color: BoostDriveTheme.textDim)),
                SizedBox(height: 32),
                Text(
                  '1. Acceptance of Terms',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 12),
                Text(
                  'By accessing and using BoostDrive, you accept and agree to be bound by the terms and provision of this agreement.',
                  style: TextStyle(color: BoostDriveTheme.textDim, height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '2. Use License',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 12),
                Text(
                  'Permission is granted to temporarily download one copy of the materials (information or software) on BoostDrive for personal, non-commercial transitory viewing only.',
                  style: TextStyle(color: BoostDriveTheme.textDim, height: 1.6),
                ),
                // Add more lorem ipsum or generic terms as needed
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'Privacy Policy',
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your privacy matters to us.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 32),
                Text(
                  'Information We Collect',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BoostDriveTheme.primaryColor),
                ),
                SizedBox(height: 12),
                Text(
                  'We collect information you provide directly to us, such as when you create an account, list a vehicle, or communicate with other users.',
                  style: TextStyle(color: BoostDriveTheme.textDim, height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  'How We Use Your Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BoostDriveTheme.primaryColor),
                ),
                SizedBox(height: 12),
                Text(
                  'We use the information we collect to provide, maintain, and improve our services, to facilitate transactions, and to communicate with you.',
                  style: TextStyle(color: BoostDriveTheme.textDim, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'Frequently Asked Questions',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: ListView(
              shrinkWrap: true,
              children: const [
                _FaqItem(
                  question: 'How do I sell my car?',
                  answer: 'Simply create an account, click "Add New Listing" or "Sell Your Vehicle", upload photos, and set your price. It takes less than 5 minutes!',
                ),
                _FaqItem(
                  question: 'Is it free to list?',
                  answer: 'Basic listings are free for all personal users. Dealerships can upgrade to a Premium plan for enhanced visibility and bulk tools.',
                ),
                _FaqItem(
                  question: 'How does the rental process work?',
                  answer: 'Browse available rentals, select your dates, and click "Rent Now". You\'ll need to confirm your booking with a payment to secure the vehicle.',
                ),
                _FaqItem(
                  question: 'Can I return a spare part?',
                  answer: 'Return policies depend on the individual seller. We recommend discussing terms in the chat before purchasing.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(answer, style: const TextStyle(fontSize: 16, color: BoostDriveTheme.textDim, height: 1.5)),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }
}
