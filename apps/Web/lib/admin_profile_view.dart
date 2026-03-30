import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:intl/intl.dart';

class AdminProfileView extends ConsumerWidget {
  final String uid;
  const AdminProfileView({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final pendingVerifications = ref.watch(pendingVerificationsProvider);
    final activeSos = ref.watch(globalActiveSosRequestsProvider);
    final userCount = ref.watch(userCountProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const Center(child: Text('Profile not found'));

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(profile),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isWide ? 3 : 1,
                        child: Column(
                          children: [
                            _buildPersonalSection(profile),
                            const SizedBox(height: 24),
                            _buildActivitySummary(ref),
                          ],
                        ),
                      ),
                      if (isWide) const SizedBox(width: 24),
                      if (isWide)
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildSecuritySection(profile),
                              const SizedBox(height: 24),
                              _buildStatsGrid(
                                pending: pendingVerifications.value?.length ?? 0,
                                activeSos: activeSos.value?.length ?? 0,
                                users: userCount.value ?? 0,
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (MediaQuery.of(context).size.width <= 900) ...[
                const SizedBox(height: 24),
                _buildSecuritySection(profile),
                const SizedBox(height: 24),
                _buildStatsGrid(
                  pending: pendingVerifications.value?.length ?? 0,
                  activeSos: activeSos.value?.length ?? 0,
                  users: userCount.value ?? 0,
                ),
              ],
              const SizedBox(height: 48),
              _buildActions(context),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildHeader(UserProfile profile) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Brand Banner
        Container(
          height: 160,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: BoostDriveTheme.primaryColor,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        // Identity Overlap
        Positioned(
          bottom: -50,
          left: 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Profile Picture
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFF2F4F7),
                  backgroundImage: profile.profileImg.isNotEmpty
                      ? NetworkImage(profile.profileImg)
                      : null,
                  child: profile.profileImg.isEmpty
                      ? Text(
                          getInitials(profile.fullName),
                          style: GoogleFonts.manrope(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: BoostDriveTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.fullName,
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1D2939),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.verified, color: Colors.blue, size: 24),
                        const SizedBox(width: 4),
                        const Icon(Icons.shield, color: BoostDriveTheme.primaryColor, size: 24),
                      ],
                    ),
                    Text(
                      'System Administrator • Super Admin',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalSection(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: BoostDriveTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                'Personal Information',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D2939),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _infoRow(Icons.face, 'Pronouns', 'she / her'), // Standard placeholder
          _infoRow(Icons.description_outlined, 'Bio', (profile.businessBio?.isNotEmpty ?? false) ? profile.businessBio! : 'Lead Administrator overseeing Namibian automotive ecosystem integrity and provider verification.'),
          _infoRow(Icons.email_outlined, 'Official Email', profile.email),
          _infoRow(Icons.phone_outlined, 'Work Phone', profile.phoneNumber),
          _infoRow(Icons.calendar_today_outlined, 'Joined Date', 'Joined ${DateFormat('MMMM yyyy').format(profile.createdAt)}'),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: BoostDriveTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                'System Authority & Security',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D2939),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _statusRow(Icons.admin_panel_settings_outlined, 'Access Level', 'Full System Access', Colors.green),
          _statusRow(Icons.lock_outline, '2FA Status', 'Active', Colors.green),
          _infoRow(Icons.history, 'Last Login', '${DateFormat('MMM d, HH:mm').format(profile.lastActive)} • Windhoek, NA'),
          _infoRow(Icons.computer_outlined, 'Current Session', 'Chrome on MacOS • 192.168.1.104'),
        ],
      ),
    );
  }

  Widget _buildActivitySummary(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: BoostDriveTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                'Recent Administrative Activity',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D2939),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _activityItem('Approved BIPA documents for Mubiana Mechanical Shop', '2 hours ago'),
          _activityItem('Resolved member dispute #4921', 'Yesterday'),
          _activityItem('Verified NamRA certificate for Towing Pros', '2 days ago'),
          _activityItem('System-wide SOS connectivity check completed', '3 days ago'),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({required int pending, required int activeSos, required int users}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [
        _statCard('REVIEWS PENDING', pending.toString(), Colors.orange),
        _statCard('ACTIVE SOS', activeSos.toString(), Colors.redAccent),
        _statCard('VERIFIED SHOPS', '142', Colors.blue), // Mocked for now
        _statCard('SYSTEM UPTIME', '99.9%', Colors.green),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D2939),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF667085)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF667085)),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF667085), fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: GoogleFonts.manrope(fontSize: 12, color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: BoostDriveTheme.primaryColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF344054)))),
          Text(time, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF98A2B3))),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Handle Dashboard navigation - assuming it's done via parent state (_selectedIndex)
          },
          icon: const Icon(Icons.dashboard_outlined),
          label: const Text('Go to Dashboard'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profile'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Color(0xFFD0D5DD)),
            foregroundColor: const Color(0xFF344054),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.list_alt),
          label: const Text('System Logs'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Color(0xFFD0D5DD)),
            foregroundColor: const Color(0xFF344054),
          ),
        ),
      ],
    );
  }
}
