import 'package:flutter/material.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountRecoveryPage extends StatelessWidget {
  const AccountRecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'ACCOUNT RECOVERY',
          style: TextStyle(fontFamily: 'Manrope', 
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderIcon(Icons.shield_outlined, BoostDriveTheme.primaryColor),
                const SizedBox(height: 24),
                Text(
                  'How to Recover Your Suspended Account',
                  style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'We take platform integrity seriously to protect both providers and customers. If your account has been suspended, follow the steps below to appeal the decision.',
                  style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                _buildRecoverySteps(),
                const SizedBox(height: 64),
                const Divider(color: Colors.white10),
                const SizedBox(height: 48),
                _buildHeaderIcon(Icons.rule_rounded, Colors.orange),
                const SizedBox(height: 24),
                Text(
                  'Community Guidelines & Rules',
                  style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'To continue operating on BoostDrive, all providers must adhere to the following strict guidelines to prevent future suspensions.',
                  style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                _buildGuidelines(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 40),
    );
  }

  Widget _buildRecoverySteps() {
    return Column(
      children: [
        _buildStepCard(
          step: '1',
          title: 'Determine the Reason',
          description: 'Check the dashboard overlay you saw when attempting to access the platform. The exact reason for your suspension is listed there.',
          icon: Icons.search,
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          step: '2',
          title: 'Gather Necessary Documentation',
          description: 'Prepare evidence (e.g., correct business registration, updated certifications, chat logs, or proof of service completion) that directly addresses the reason for your suspension.',
          icon: Icons.folder_shared_outlined,
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          step: '3',
          title: 'Contact Compliance',
          description: 'Send an email to our compliance team at info@boostdrive.na. Include your Unique User ID (UID) and attach the supporting documents you gathered.',
          icon: Icons.mail_outline,
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          step: '4',
          title: 'Wait for Review',
          description: 'Our team will review your appeal within 24 to 48 hours. During this period, your business remains hidden from search results, and SOS features are deactivated.',
          icon: Icons.access_time,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildStepCard({required String step, required String title, required String description, required IconData icon, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: BoostDriveTheme.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white54, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(fontFamily: 'Manrope', 
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelines() {
    return Column(
      children: [
        _buildGuidelineItem(
          title: 'Zero Tolerance for Harassment & Bullying',
          description: 'Any form of hate speech, threats, bullying, or unprofessional behavior towards customers or other providers will result in permanent suspension.',
          icon: Icons.gavel_rounded,
          color: Colors.redAccent,
        ),
        const SizedBox(height: 16),
        _buildGuidelineItem(
          title: 'No Spam Messaging',
          description: 'Do not send unsolicited promotional messages, repeated identical texts, or spam to customers. Communicate only regarding active service requests.',
          icon: Icons.speaker_notes_off_outlined,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildGuidelineItem(
          title: 'Honor Your Commitments',
          description: 'Repeatedly failing to show up for accepted SOS requests or booked services breaks trust. Maintain high reliability and cancel gracefully if emergencies occur.',
          icon: Icons.handshake_outlined,
          color: BoostDriveTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        _buildGuidelineItem(
          title: 'Accurate Representation',
          description: 'Do not misrepresent your qualifications, business identity, certifications, or the specific services you provide.',
          icon: Icons.badge_outlined,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 16),
        _buildGuidelineItem(
          title: 'Fair Pricing & Integrity',
          description: 'Provide transparent, honest quotes. Engaging in price gouging, hidden fees, or fraudulent charges will instantly trigger an account review.',
          icon: Icons.price_check_outlined,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        _buildGuidelineItem(
          title: 'Follow All Local Regulations',
          description: 'Strict adherence to all Namibian laws, industry standards, and BoostDrive’s master Terms of Service is mandatory.',
          icon: Icons.account_balance_outlined,
          color: Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget _buildGuidelineItem({required String title, required String description, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.5,
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
