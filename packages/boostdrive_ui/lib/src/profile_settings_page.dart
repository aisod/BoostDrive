import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'theme.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  bool _isEditing = false;
  bool _isUploading = false;
  
  // Provider / shop profile (only used when role is service_provider or seller)
  final _shopDisplayNameController = TextEditingController();
  final _storeBioController = TextEditingController();
  final _warehouseAddressController = TextEditingController();
  bool _baTLorriHEnabled = false;
  
  // Optimistic UI state
  Uint8List? _optimisticImage;
  bool _isOptimisticDelete = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _shopDisplayNameController.dispose();
    _storeBioController.dispose();
    _warehouseAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: BoostDriveTheme.textDim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action is permanent and will delete your profile data. Are you sure?',
          style: TextStyle(color: BoostDriveTheme.textDim),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(authServiceProvider).deleteAccount(user.id);
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _removeProfilePhoto({required bool showInitials}) async {
    try {
      // Optimistic update: Immediately show the change
      setState(() {
        _isUploading = true;
        _optimisticImage = null;
        _isOptimisticDelete = showInitials; // If showing initials, we are effectively deleting the image
      });

      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update profile with null or empty string based on showInitials
      await ref.read(authServiceProvider).updateProfile(
        userId: user.id,
        avatarUrl: showInitials ? '' : null,
      );

      // Refresh profile by invalidating the provider
      ref.invalidate(currentUserProvider);

      if (mounted) {
        setState(() {
          _isUploading = false;
          // Keep optimistic state until the new provider value loads? 
          // Actually, invalidating assumes the next build might still fetch. 
          // But to be safe and avoid flickering, we can reset optimistic state 
          // only if we are sure the provider has updated, or just rely on the provider from now.
          // For now, clearing them is safer to avoid stale state, 
          // but we might see a flicker if provider read is slow.
          // A better approach is usually to keep them until the new data matches, 
          // but for simplicity, we'll clear them and hope the invalidate acts fast enough 
          // or the UI won't flicker too noticeably.
          _isOptimisticDelete = false; 
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              showInitials 
                  ? 'Profile photo removed.' 
                  : 'Profile photo deleted.',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            backgroundColor: BoostDriveTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Revert optimistic state on error
        setState(() {
          _isUploading = false;
          _isOptimisticDelete = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error removing photo: $e',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final profile = await ref.read(userProfileProvider(user.id).future);
      final isProvider = profile != null && (profile.role.toLowerCase().contains('service') || profile.role.toLowerCase().contains('seller'));
      final fullName = isProvider && _shopDisplayNameController.text.isNotEmpty
          ? _shopDisplayNameController.text
          : _nameController.text;
      await ref.read(authServiceProvider).updateProfile(
        userId: user.id,
        fullName: fullName,
        phoneNumber: _phoneController.text,
        emergencyContactName: _emergencyNameController.text,
        emergencyContactPhone: _emergencyPhoneController.text,
      );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
  }

  Future<void> _showProfilePhotoOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E7EC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Profile Photo',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D2939),
                ),
              ),
              const SizedBox(height: 20),
              _buildPhotoOption(
                icon: Icons.photo_library,
                title: 'Choose Photo',
                subtitle: 'Select from your device',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
              _buildPhotoOption(
                icon: Icons.person_outline,
                title: 'No Profile Photo',
                subtitle: 'Display your initials',
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePhoto(showInitials: true);
                },
              ),
              _buildPhotoOption(
                icon: Icons.delete_outline,
                title: 'Delete Photo',
                subtitle: 'Remove current photo',
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePhoto(showInitials: false);
                },
                isDestructive: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.1) 
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF667085),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDestructive ? Colors.red : const Color(0xFF1D2939),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF98A2B3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      
      // Optimistic update: Immediately show the selected image
      setState(() {
        _isUploading = true;
        _optimisticImage = bytes;
        _isOptimisticDelete = false;
      });

      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 70,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Edit Photo',
              toolbarColor: BoostDriveTheme.primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              cropStyle: CropStyle.circle,
            ),
            IOSUiSettings(
              title: 'Edit Photo',
              cropStyle: CropStyle.circle,
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.page,
              size: const CropperSize(width: 300, height: 300),
            ),
          ],
        );

        if (croppedFile != null) {
          final croppedBytes = await croppedFile.readAsBytes();
          
          // Update optimistic state with cropped image
          setState(() {
            _optimisticImage = croppedBytes;
          });

          final publicUrl = await ref.read(authServiceProvider).uploadProfileImage(
            croppedBytes,
            image.name,
          );

          final user = ref.read(currentUserProvider);
          if (user != null) {
            await ref.read(authServiceProvider).updateProfile(
              userId: user.id,
              avatarUrl: publicUrl,
            );
            
            // Refresh profile
            ref.invalidate(currentUserProvider);
          }
           
           if (mounted) {
             setState(() {
               _isUploading = false;
               _isOptimisticDelete = false;
             });
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile picture updated successfully')),
             );
           }
        }
      } catch (e) {
        debugPrint('Error in profile photo upload: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _isOptimisticDelete = false;
          });
        }
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Change Password',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D2939),
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   _buildPasswordTextField(
                    controller: currentPasswordController,
                    label: 'Current Password',
                    hint: 'Enter current password',
                  ),
                  const SizedBox(height: 16),
                   _buildPasswordTextField(
                    controller: newPasswordController,
                    label: 'New Password',
                    hint: 'Enter new password',
                  ),
                  const SizedBox(height: 16),
                   _buildPasswordTextField(
                    controller: confirmPasswordController,
                    label: 'Confirm New Password',
                    hint: 'Re-enter new password',
                    validator: (val) {
                      if (val != newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.manrope(color: const Color(0xFF667085), fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isLoading = true);
                  try {
                    final authService = ref.read(authServiceProvider);
                    final isVerified = await authService.verifyPassword(currentPasswordController.text);
                    
                    if (!isVerified) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Incorrect current password')),
                        );
                      }
                      setDialogState(() => isLoading = false);
                      return;
                    }

                    await authService.updatePassword(newPasswordController.text);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated successfully')),
                      );
                    }
                  } catch (e) {
                     if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                  } finally {
                    setDialogState(() => isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BoostDriveTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Save', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF667085))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF98A2B3)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator ?? (val) {
            if (val == null || val.isEmpty) return 'Field required';
            if (val.length < 6) return 'Minimum 6 characters';
            return null;
          },
        ),
      ],
    );
  }

  Scaffold _buildProviderProfileScaffold(UserProfile profile, bool isWide) {
    const bg = Color(0xFFF7F9FB);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Provider Profile Settings',
          style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderBanner(profile),
            const SizedBox(height: 56),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _shopDisplayNameController.text.isEmpty ? profile.fullName : _shopDisplayNameController.text,
                        style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF1D2939)),
                      ),
                      if (profile.verificationStatus == 'verified') ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified, color: BoostDriveTheme.primaryColor, size: 24),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: BoostDriveTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Text('TOP RATED SELLER', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: BoostDriveTheme.primaryColor, letterSpacing: 0.5)),
                      ),
                      Text('Verified Salvage Yard', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildProviderMetrics(),
                  const SizedBox(height: 32),
                  _buildProviderShopBranding(profile),
                  const SizedBox(height: 32),
                  _buildProviderShippingLogistics(),
                  const SizedBox(height: 32),
                  _buildProviderPaymentsPayouts(),
                  const SizedBox(height: 32),
                  _buildProviderBusinessRegistration(profile),
                  const SizedBox(height: 32),
                  _buildPersonalInformation(),
                  const SizedBox(height: 32),
                  _buildBusinessInformation(profile),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 32),
                    _buildSafetySection(),
                  ],
                  const SizedBox(height: 32),
                  _buildActionsSection(profile),
                  const SizedBox(height: 40),
                  _buildProviderFooterButtons(),
                  const SizedBox(height: 40),
                  Text(
                    'BoostDrive Version 2.4.1 (1209)',
                    style: GoogleFonts.manrope(color: const Color(0xFF98A2B3), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderBanner(UserProfile profile) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BoostDriveTheme.primaryColor.withValues(alpha: 0.9),
                BoostDriveTheme.primaryColor,
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 24,
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            label: Text('Edit Banner', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -44,
          child: Center(
            child: GestureDetector(
              onTap: _isUploading ? null : _showProfilePhotoOptions,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    backgroundImage: _optimisticImage != null
                        ? MemoryImage(_optimisticImage!) as ImageProvider
                        : (profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null),
                    child: profile.profileImg.isEmpty && _optimisticImage == null
                        ? Text(getInitials(profile.fullName), style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: BoostDriveTheme.primaryColor))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: BoostDriveTheme.primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.edit, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderMetrics() {
    return Row(
      children: [
        _providerMetricCard('RATING', '—', Icons.star, Colors.amber),
        const SizedBox(width: 16),
        _providerMetricCard('SHIP SPEED', '—', Icons.local_shipping_outlined, BoostDriveTheme.primaryColor),
        const SizedBox(width: 16),
        _providerMetricCard('RESPONSE', '—', Icons.schedule, BoostDriveTheme.primaryColor),
      ],
    );
  }

  Widget _providerMetricCard(String label, String value, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E7EC)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF667085), letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1D2939))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderShopBranding(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.store_outlined, color: BoostDriveTheme.primaryColor, size: 22),
            const SizedBox(width: 10),
            Text('Shop Branding', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1D2939))),
          ],
        ),
        const SizedBox(height: 16),
        _providerLabel('Shop Display Name'),
        const SizedBox(height: 8),
        TextField(
          controller: _shopDisplayNameController,
          style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)),
          decoration: _providerInputDecoration(),
        ),
        const SizedBox(height: 16),
        _providerLabel('Store Biography'),
        const SizedBox(height: 8),
        TextField(
          controller: _storeBioController,
          maxLines: 3,
          style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)),
          decoration: _providerInputDecoration(hint: 'Describe your shop'),
        ),
      ],
    );
  }

  Widget _providerLabel(String text) {
    return Text(text, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF667085)));
  }

  InputDecoration _providerInputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint ?? '',
      hintStyle: GoogleFonts.manrope(color: const Color(0xFF98A2B3)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE4E7EC))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BoostDriveTheme.primaryColor, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildProviderShippingLogistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_shipping_outlined, color: BoostDriveTheme.primaryColor, size: 22),
            const SizedBox(width: 10),
            Text('Shipping & Logistics', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1D2939))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E7EC)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('BT', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: BoostDriveTheme.primaryColor))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BaTLorriH Integration', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1D2939))),
                    const SizedBox(height: 2),
                    Text('Automated freight dispatch.', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
                  ],
                ),
              ),
              Switch(
                value: _baTLorriHEnabled,
                onChanged: (v) => setState(() => _baTLorriHEnabled = v),
                activeTrackColor: BoostDriveTheme.primaryColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _providerLabel('Warehouse Address'),
        const SizedBox(height: 8),
        TextField(
          controller: _warehouseAddressController,
          style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)),
          decoration: _providerInputDecoration(hint: 'Not set'),
        ),
      ],
    );
  }

  Widget _buildProviderPaymentsPayouts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_outlined, color: BoostDriveTheme.primaryColor, size: 22),
            const SizedBox(width: 10),
            Text('Payments & Payouts', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1D2939))),
          ],
        ),
        const SizedBox(height: 16),
        _providerInfoCard(
          icon: Icons.credit_card_outlined,
          title: 'Bank Account',
          value: 'Not set',
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF667085)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _providerInfoCard(icon: Icons.calendar_today_outlined, title: 'Next Payout', value: '—'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
                    Text('—', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1D2939))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _providerInfoCard({required IconData icon, required String title, required String value, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF667085), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1D2939))),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildProviderBusinessRegistration(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business_center_outlined, color: BoostDriveTheme.primaryColor, size: 22),
            const SizedBox(width: 10),
            Text('Business Registration', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1D2939))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E7EC)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              _providerKeyValue('Tax ID (EIN)', '—'),
              const SizedBox(height: 12),
              _providerKeyValue('Entity Type', '—'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Verification Status', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        profile.verificationStatus == 'verified' ? Icons.check_circle : Icons.pending_outlined,
                        size: 18,
                        color: profile.verificationStatus == 'verified' ? Colors.green : const Color(0xFF667085),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profile.verificationStatus.isEmpty ? '—' : profile.verificationStatus.toUpperCase(),
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1D2939)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _providerKeyValue(String key, String value) {
    return Row(
      children: [
        Text(key, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
        const Spacer(),
        Text(value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1D2939))),
      ],
    );
  }

  Widget _buildProviderFooterButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: BoostDriveTheme.primaryColor,
              side: const BorderSide(color: BoostDriveTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Preview Store', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _handleSaveProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BoostDriveTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save All Changes', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return ref.watch(userProfileProvider(user.id)).when(
      data: (profile) {
        if (profile == null) return const Scaffold(body: Center(child: Text('Profile not found')));
        
        if (!_isEditing) {
          _nameController.text = profile.fullName;
          _emailController.text = profile.email;
          _phoneController.text = profile.phoneNumber;
          _emergencyNameController.text = profile.emergencyContactName;
          _emergencyPhoneController.text = profile.emergencyContactPhone;
        }

        final isProvider = profile.role.toLowerCase().contains('service') || profile.role.toLowerCase().contains('seller');
        final isWide = MediaQuery.of(context).size.width > 900;

        if (isProvider) {
          if (_shopDisplayNameController.text.isEmpty && profile.fullName.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _shopDisplayNameController.text.isEmpty) {
                _shopDisplayNameController.text = profile.fullName;
              }
            });
          }
          return _buildProviderProfileScaffold(profile, isWide);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FB),
          appBar: AppBar(
            backgroundColor: BoostDriveTheme.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Profile Settings',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _handleSaveProfile,
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildProfileHeader(profile),
                const SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
                  child: Column(
                    children: [
                      _buildPersonalInformation(),
                      if (!kIsWeb) ...[
                        const SizedBox(height: 32),
                        _buildSafetySection(),
                      ],
                      const SizedBox(height: 32),
                      _buildActionsSection(profile),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'BoostDrive Version 2.4.1 (1209)',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF98A2B3),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1D2939)),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: GoogleFonts.manrope(color: const Color(0xFF667085)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentUserProvider),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    final isProvider = profile.role.toLowerCase().contains('service') || profile.role.toLowerCase().contains('seller');
    
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _isUploading ? null : _showProfilePhotoOptions,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFE4E7EC),
                    backgroundImage: _optimisticImage != null
                        ? MemoryImage(_optimisticImage!) as ImageProvider
                        : (!_isOptimisticDelete && profile.profileImg.isNotEmpty)
                            ? NetworkImage(profile.profileImg)
                            : null,
                    child: (_optimisticImage == null && (_isOptimisticDelete || profile.profileImg.isEmpty))
                        ? Text(
                            getInitials(profile.fullName),
                            style: GoogleFonts.manrope(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: BoostDriveTheme.primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: BoostDriveTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: _isUploading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.fullName.isEmpty ? 'Set Name' : profile.fullName,
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1D2939),
          ),
        ),
        if (isProvider) ...[
          const SizedBox(height: 4),
          Text(
            '${profile.role.replaceAll('_', ' ').toUpperCase()} • Professional Partner',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BoostDriveTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '—',
                style: GoogleFonts.manrope(color: const Color(0xFF1D2939), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                '(— reviews)',
                style: GoogleFonts.manrope(color: const Color(0xFF667085), fontSize: 12),
              ),
            ],
          ),
        ] else
          Text(
            'BoostDrive Member since ${profile.createdAt.year}',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF667085),
            ),
          ),
      ],
    );
  }

  Widget _buildBusinessInformation(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUSINESS INFORMATION',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF667085),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF2F4F7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBusinessStat('AVG TIME', '45 mins'),
                  _buildBusinessStat('COMPLETED', profile.totalEarnings > 0 ? (profile.totalEarnings / 50).toInt().toString() : '0'),
                  _buildBusinessStat('SUCCESS', profile.verificationStatus == 'verified' ? '100%' : '99%', isLast: true),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'ABOUT',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF98A2B3),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile.role.toLowerCase().contains('service') 
                  ? 'Professional service provider since ${profile.createdAt.year}. Dedicated to delivering high-quality logistic and maintenance solutions for the BoostDrive community.'
                  : 'Verified seller since ${profile.createdAt.year}. Committed to providing quality automotive parts and vehicles to the BoostDrive marketplace.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF475467),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ACTIVE SERVICES',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF98A2B3),
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'MANAGE',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: BoostDriveTheme.primaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (profile.role.toLowerCase().contains('service')) ...[
                _buildServiceListItem('General Logistics', 'N\$ 45.00', '2-4 hours'),
                _buildServiceListItem('Express Delivery', 'N\$ 85.00', '30-45 min'),
                _buildServiceListItem('Scheduled Fleet', 'N\$ 120.00', '60-90 min', isLast: true),
              ] else ...[
                _buildServiceListItem('Standard Shipping', 'N\$ 150.00', '1-2 days'),
                _buildServiceListItem('Local Pickup', 'FREE', 'Instant', isLast: true),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessStat(String label, String value, {bool isLast = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: isLast ? null : const Border(right: BorderSide(color: Color(0xFFF2F4F7))),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF98A2B3),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D2939),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceListItem(String name, String price, String duration, {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BoostDriveTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.settings_outlined, color: BoostDriveTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1D2939)),
                ),
                Text(
                  duration,
                  style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085)),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: BoostDriveTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PERSONAL INFORMATION',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF667085),
                letterSpacing: 0.5,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                size: 20,
                color: BoostDriveTheme.primaryColor,
              ),
              tooltip: _isEditing ? 'Cancel' : 'Edit',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF2F4F7)),
          ),
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.person_outline,
                title: 'Full Name',
                value: _nameController.text,
                controller: _nameController,
                isEditable: _isEditing,
              ),
              const Divider(height: 1, indent: 64),
              _buildInfoTile(
                icon: Icons.email_outlined,
                title: 'Email Address',
                value: _emailController.text,
                controller: _emailController,
                isEditable: false,
              ),
              const Divider(height: 1, indent: 64),
              _buildInfoTile(
                icon: Icons.phone_android_outlined,
                title: 'Phone Number',
                value: _phoneController.text,
                controller: _phoneController,
                isEditable: _isEditing,
                isLast: true,
              ),
            ],
          ),
        ),
        if (_isEditing) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      final user = ref.read(currentUserProvider);
                      if (user != null) {
                        ref.invalidate(userProfileProvider(user.id));
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: const Color(0xFF344054)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleSaveProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: BoostDriveTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionsSection(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIONS',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF667085),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            _buildActionButton(
              icon: Icons.lock_outline,
              label: 'Change Password',
              onTap: _showChangePasswordDialog,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.logout,
              label: 'Log Out',
              onTap: _handleLogout,
              color: const Color(0xFFD92D20),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.delete_outline,
              label: 'Delete Account',
              onTap: _handleDeleteAccount,
              color: const Color(0xFF98A2B3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF2F4F7)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color ?? const Color(0xFF1D2939), size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color ?? const Color(0xFF1D2939),
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, size: 16, color: color?.withOpacity(0.5) ?? const Color(0xFFD0D5DD)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    TextEditingController? controller,
    bool isEditable = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: BoostDriveTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D2939),
                  ),
                ),
                if (isEditable)
                  TextField(
                    controller: controller,
                    style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF667085)),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  )
                else
                  Text(
                    value.isEmpty ? 'Not set' : value,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF667085),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFD0D5DD)),
        ],
      ),
    );
  }

  Widget _buildSafetySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAFETY & SOS',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFD92D20),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFEE4E2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE4E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SOS',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFD92D20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Contact',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D2939),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Notifications will be sent to this contact in case of a breakdown or collision.',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isEditing)
                              TextField(
                                controller: _emergencyNameController,
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1D2939)),
                                decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Contact Name'),
                              )
                            else
                              Text(
                                _emergencyNameController.text.isEmpty ? 'No Contact' : _emergencyNameController.text,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1D2939),
                                ),
                              ),
                            if (_isEditing)
                              TextField(
                                controller: _emergencyPhoneController,
                                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF667085)),
                                decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Phone Number'),
                              )
                            else
                              Text(
                                _emergencyPhoneController.text.isEmpty ? 'Not set' : _emergencyPhoneController.text,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!_isEditing)
                        Text(
                          'Edit',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD92D20),
                          ),
                        ),
                    ],
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
