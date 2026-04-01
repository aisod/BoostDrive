import 'package:flutter/material.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'account_recovery_page.dart';

class SuspensionOverlay extends StatelessWidget {
  final String? supportEmail;
  final String? reason;

  const SuspensionOverlay({
    super.key,
    this.supportEmail = 'info@boostdrive.na',
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 550),
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.3), width: 2),
                boxShadow: [
              BoxShadow(
                color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_problem_rounded,
                  color: BoostDriveTheme.primaryColor,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'ACCOUNT SUSPENDED',
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your service provider account has been flagged for a compliance review and is currently suspended.',
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'REASON FOR SUSPENSION',
                        style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildRestrictionItem(Icons.visibility_off_outlined, 'Business hidden from search/maps'),
                    const SizedBox(height: 12),
                    _buildRestrictionItem(Icons.block_flipped, 'SOS request broadcaster blocked'),
                    const SizedBox(height: 12),
                    _buildRestrictionItem(Icons.money_off_rounded, 'Payouts and withdrawals frozen'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AccountRecoveryPage()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'WHAT CAN I DO? (View Rules & Recovery Guidelines)',
                  style: TextStyle(
                    color: BoostDriveTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please contact our compliance team with your UID and supporting documents to resolve this.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  if (supportEmail == null) return;
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: supportEmail!,
                  );
                  try {
                    await launchUrl(emailLaunchUri);
                  } catch (e) {
                    debugPrint('Could not launch email: $e');
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mail_outline, color: Colors.black87, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        supportEmail!,
                        style: TextStyle(fontFamily: 'Manrope', 
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildRestrictionItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
