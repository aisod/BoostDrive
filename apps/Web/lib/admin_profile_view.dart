import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

final adminProfileImageUploadProvider = StateProvider<bool>((ref) => false);

class AdminProfileView extends ConsumerWidget {
  final String uid;
  const AdminProfileView({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final pendingVerifications = ref.watch(pendingVerificationsProvider);
    final activeSos = ref.watch(globalActiveSosRequestsProvider);
    final userCount = ref.watch(userCountProvider);
    final isUploading = ref.watch(adminProfileImageUploadProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const Center(child: Text('Profile not found'));

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(profile, ref, context),
              const SizedBox(height: 24), // Reduced space since no more overlap
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  if (!isWide) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildPersonalSection(profile),
                          const SizedBox(height: 24),
                          _buildSecuritySection(profile),
                          const SizedBox(height: 24),
                          _buildStatsGrid(
                            ref: ref,
                            pending: pendingVerifications.value?.length ?? 0,
                            activeSos: activeSos.value?.length ?? 0,
                            users: userCount.value ?? 0,
                          ),
                          const SizedBox(height: 24),
                          _buildActivitySummary(ref),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 64),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPersonalSection(profile),
                              const SizedBox(height: 24),
                              _buildActivitySummary(ref),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSecuritySection(profile),
                              const SizedBox(height: 24),
                              _buildStatsGrid(
                                ref: ref,
                                pending: pendingVerifications.value?.length ?? 0,
                                activeSos: activeSos.value?.length ?? 0,
                                users: userCount.value ?? 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64),
                child: _buildActions(context),
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildHeader(UserProfile profile, WidgetRef ref, BuildContext context) {
    final isUploading = ref.watch(adminProfileImageUploadProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Brand Banner (Fixed Height 180px)
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: BoostDriveTheme.primaryColor,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Stack(
            children: [
              // Brand Banner (Fixed Height 180px)
              const SizedBox.shrink(),
            ],
          ),
        ),
        
        // Identity Overlap (Horizontally aligned to right of Avatar)
        Positioned(
          bottom: 16, 
          left: 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Profile Picture with thick white border
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFFF2F4F7),
                        backgroundImage: profile.profileImg.isNotEmpty
                            ? NetworkImage(profile.profileImg)
                            : null,
                        child: profile.profileImg.isEmpty
                            ? Text(
                                getInitials(profile.fullName),
                                style: TextStyle(fontFamily: 'Manrope', 
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: BoostDriveTheme.primaryColor,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (isUploading)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black26,
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 32),
              
              // Identity info moved to right of avatar
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.fullName,
                          style: TextStyle(fontFamily: 'Manrope', 
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PLATFORM ADMINISTRATOR',
                            style: TextStyle(fontFamily: 'Manrope', 
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: BoostDriveTheme.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
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
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D2939),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                style: TextStyle(fontFamily: 'Manrope', 
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
          Builder(
            builder: (context) {
              String device = 'Unknown Device';
              if (kIsWeb) {
                final userAgent = html.window.navigator.userAgent.toLowerCase();
                if (userAgent.contains('chrome')) device = 'Chrome on ';
                else if (userAgent.contains('safari')) device = 'Safari on ';
                else if (userAgent.contains('firefox')) device = 'Firefox on ';
                
                if (userAgent.contains('mac')) device += 'macOS';
                else if (userAgent.contains('win')) device += 'Windows';
                else if (userAgent.contains('linux')) device += 'Linux';
                else device += 'Web';
              }
              return _infoRow(Icons.computer_outlined, 'Current Session', '$device • Active Session');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary(WidgetRef ref) {
    final activityAsync = ref.watch(recentAuditLogsStreamProvider);

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
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D2939),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          activityAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No recent activity logs found.', 
                      style: TextStyle(fontFamily: 'Manrope', fontSize: 13, color: Colors.black45)),
                  ),
                );
              }
              // Skip the first log if it's the current "PROFILE_REVIEW_OPEN" 
              // to show more meaningful history
              return Column(
                children: logs.take(6).map((log) {
                  final type = log['action_type'] ?? 'ACTION';
                  final notes = log['notes'] ?? '';
                  final createdAt = log['created_at'] != null 
                      ? DateTime.parse(log['created_at']) 
                      : DateTime.now();
                  
                  // Humanize common types
                  String humanType = type.toString().replaceAll('_', ' ');
                  if (type == 'APPROVE_PROVIDER') humanType = 'Approved Provider';
                  if (type == 'REJECT_PROVIDER') humanType = 'Rejected Provider';
                  if (type == 'ADMIN_MESSAGE_SENT') humanType = 'Messaged Provider';
                  if (type == 'PROFILE_REVIEW_OPEN') humanType = 'Review Started';
                  if (type == 'DOC_VIEW') humanType = 'Document Viewed';

                  return _activityItem('$humanType: $notes', _formatTimeAgo(createdAt));
                }).toList(),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (err, _) => Center(child: Text('Error loading activity logs')),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildStatsGrid({required WidgetRef ref, required int pending, required int activeSos, required int users}) {
    final profiles = ref.watch(allProfilesProvider).valueOrNull ?? [];
    final verifiedCount = profiles.where((p) => p.verificationStatus == 'approved' && p.role != 'customer').length;
    
    // Check system uptime (heartbeat proxy)
    final uptime = profiles.isNotEmpty ? '100%' : '---';

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
        _statCard('VERIFIED SHOPS', verifiedCount.toString(), Colors.blue), 
        _statCard('SYSTEM UPTIME', uptime, Colors.green),
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
            style: TextStyle(fontFamily: 'Manrope', 
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontFamily: 'Manrope', 
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Vertically centered
        children: [
          SizedBox(
            width: 24, // Consistent icon width
            child: Icon(icon, size: 20, color: const Color(0xFF667085)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF667085), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF1D2939), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            child: Icon(icon, size: 20, color: const Color(0xFF667085)),
          ),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF667085), fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8), // More modern smaller radius
            ),
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: color, fontWeight: FontWeight.w800),
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
          Expanded(child: Text(title, style: TextStyle(fontFamily: 'Manrope', fontSize: 13, color: const Color(0xFF344054)))),
          Text(time, style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF98A2B3))),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
            );
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profile', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: Color(0xFF344054))),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
        ),
      ],
    );
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Colors.black87),
            title: const Text('Change Profile Photo', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
            onTap: () {
              Navigator.pop(context);
              _pickAndUploadImage(ref, profile.uid);
            },
          ),
          ListTile(
            leading: const Icon(Icons.no_photography_outlined, color: Colors.black87),
            title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
            onTap: () {
              Navigator.pop(context);
              _removeProfileImage(ref, profile.uid);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Photo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _removeProfileImage(ref, profile.uid);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(WidgetRef ref, String userId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    ref.read(adminProfileImageUploadProvider.notifier).state = true;
    try {
      final bytes = await image.readAsBytes();
      final authService = ref.read(authServiceProvider);
      
      final publicUrl = await authService.uploadProfileImage(bytes, image.name);
      await authService.updateProfile(userId: userId, avatarUrl: publicUrl);
      
      // Refresh profiles
      ref.invalidate(userProfileProvider(userId));
      ref.invalidate(allProfilesProvider);
      
    } catch (e) {
      print('Error uploading profile image: $e');
    } finally {
      ref.read(adminProfileImageUploadProvider.notifier).state = false;
    }
  }

  Future<void> _removeProfileImage(WidgetRef ref, String userId) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(userId: userId, avatarUrl: '');
      
      ref.invalidate(userProfileProvider(userId));
      ref.invalidate(allProfilesProvider);
    } catch (e) {
      print('Error removing profile image: $e');
    }
  }
}
