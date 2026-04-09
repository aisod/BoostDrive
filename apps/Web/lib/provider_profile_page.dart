import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_fonts/google_fonts.dart';

class ProviderProfilePage extends ConsumerWidget {
  final String uid;
  const ProviderProfilePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PROFESSIONAL PROFILE',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found', style: TextStyle(color: Colors.white)));
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(profile),
                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoSection(
                                'Contact Details',
                                Icons.contact_mail_outlined,
                                [
                                  _infoTile(Icons.email_outlined, 'Email Address', profile.email),
                                  _infoTile(Icons.phone_outlined, 'Phone Number', profile.phoneNumber),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _buildInfoSection(
                                'Business Information',
                                Icons.business_center_outlined,
                                [
                                  _infoTile(Icons.category_outlined, 'Service Specialization', profile.primaryServiceCategory ?? 'General Service'),
                                  _infoTile(Icons.verified_outlined, 'Account Status', profile.verificationStatus.toUpperCase(), isStatus: true),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isWide) const SizedBox(width: 48),
                        if (isWide)
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildStatsCard(profile),
                                const SizedBox(height: 32),
                                _buildActionList(context),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (MediaQuery.of(context).size.width <= 900) ...[
                  const SizedBox(height: 32),
                  _buildStatsCard(profile),
                  const SizedBox(height: 32),
                  _buildActionList(context),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: BoostDriveTheme.primaryColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null,
            child: profile.profileImg.isEmpty 
              ? const Icon(Icons.person, color: Colors.white, size: 60)
              : null,
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SERVICE PROVIDER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: BoostDriveTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 18),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 11)),
              const SizedBox(height: 4),
              isStatus 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: value.toLowerCase() == 'approved' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: value.toLowerCase() == 'approved' ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PERFORMANCE SUMMARY', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 24),
          _statRow('Total Earnings', '\$${profile.totalEarnings.toStringAsFixed(2)}'),
          const Divider(color: Colors.white10, height: 32),
          _statRow('Account Standing', 'Excellence'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionList(BuildContext context) {
    return Column(
      children: [
        _actionButton('Edit Profile Information', Icons.edit_outlined, () {}),
        const SizedBox(height: 12),
        _actionButton('Privacy & Security', Icons.lock_outline, () {}),
        const SizedBox(height: 12),
        _actionButton('Billing Settings', Icons.credit_card_outlined, () {}),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
