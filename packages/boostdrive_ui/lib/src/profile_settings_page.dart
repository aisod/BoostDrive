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
  final _serviceAreaController = TextEditingController();
  final _workingHoursController = TextEditingController();
  bool _baTLorriHEnabled = false;
  /// Provider service types (mobile): selected values e.g. ['mechanic','towing']. Min 1 when provider.
  List<String> _selectedServiceTypes = [];

  // Operational & Business Details
  bool _businessHours24_7 = false;
  final _serviceRadiusKmController = TextEditingController();
  final _workshopAddressController = TextEditingController();
  final _socialFacebookController = TextEditingController();
  final _socialInstagramController = TextEditingController();
  final _websiteUrlController = TextEditingController();

  // Service Specializations
  List<String> _selectedBrandExpertise = [];
  List<String> _selectedServiceTags = [];
  List<String> _selectedTowingCapabilities = [];

  // Financial & Payout
  final _bankAccountNumberController = TextEditingController();
  final _bankBranchController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _standardLaborRateController = TextEditingController();
  final _taxVatNumberController = TextEditingController();

  // Trust & Experience
  final _businessBioController = TextEditingController();
  List<String> _galleryUrls = [];
  final _teamSizeController = TextEditingController();
  bool _isUploadingDocuments = false;

  // Notification & Alert
  bool _sosAlertsEnabled = true;
  String _preferredCommunication = 'app_chat';

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
    _serviceAreaController.dispose();
    _workingHoursController.dispose();
    _serviceRadiusKmController.dispose();
    _workshopAddressController.dispose();
    _socialFacebookController.dispose();
    _socialInstagramController.dispose();
    _websiteUrlController.dispose();
    _bankAccountNumberController.dispose();
    _bankBranchController.dispose();
    _bankNameController.dispose();
    _standardLaborRateController.dispose();
    _taxVatNumberController.dispose();
    _businessBioController.dispose();
    _teamSizeController.dispose();
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
    if (user == null) return;
    final profile = await ref.read(userProfileProvider(user.id).future);
    final isProvider = profile != null && _isProviderRole(profile.role);
    if (isProvider && !kIsWeb && _selectedServiceTypes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least 1 service you provide')),
        );
      }
      return;
    }
    final fullName = isProvider && _shopDisplayNameController.text.isNotEmpty
        ? _shopDisplayNameController.text
        : _nameController.text;

    if (isProvider) {
      final workingHours = _businessHours24_7 ? '24/7' : _workingHoursController.text.trim();
      final updated = profile.copyWith(
        fullName: fullName,
        phoneNumber: _phoneController.text,
        emergencyContactName: _emergencyNameController.text,
        emergencyContactPhone: _emergencyPhoneController.text,
        serviceAreaDescription: _serviceAreaController.text.trim(),
        workingHours: workingHours,
        providerServiceTypes: _selectedServiceTypes,
        businessHours24_7: _businessHours24_7,
        serviceRadiusKm: int.tryParse(_serviceRadiusKmController.text.trim()),
        workshopAddress: _workshopAddressController.text.trim(),
        socialFacebook: _socialFacebookController.text.trim(),
        socialInstagram: _socialInstagramController.text.trim(),
        websiteUrl: _websiteUrlController.text.trim(),
        brandExpertise: _selectedBrandExpertise,
        serviceTags: _selectedServiceTags,
        towingCapabilities: _selectedTowingCapabilities,
        bankAccountNumber: _bankAccountNumberController.text.trim(),
        bankBranch: _bankBranchController.text.trim(),
        bankName: _bankNameController.text.trim(),
        standardLaborRate: double.tryParse(_standardLaborRateController.text.trim()),
        taxVatNumber: _taxVatNumberController.text.trim(),
        businessBio: _businessBioController.text.trim(),
        galleryUrls: _galleryUrls,
        teamSize: int.tryParse(_teamSizeController.text.trim()),
        sosAlertsEnabled: _sosAlertsEnabled,
        preferredCommunication: _preferredCommunication,
      );
      await ref.read(userServiceProvider).updateProfile(updated);
    } else {
      await ref.read(authServiceProvider).updateProfile(
        userId: user.id,
        fullName: fullName,
        phoneNumber: _phoneController.text,
        emergencyContactName: _emergencyNameController.text,
        emergencyContactPhone: _emergencyPhoneController.text,
        serviceAreaDescription: isProvider ? _serviceAreaController.text.trim() : null,
        workingHours: isProvider ? _workingHoursController.text.trim() : null,
        providerServiceTypes: isProvider && !kIsWeb ? _selectedServiceTypes : null,
      );
    }
    ref.invalidate(userProfileProvider(user.id));
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  bool _isProviderRole(String role) {
    final r = role.toLowerCase();
    return r.contains('service') || r.contains('seller') || r == 'mechanic' || r == 'towing' || r == 'rental';
  }

  /// True when admin has approved this provider (verification_status = approved or verified).
  bool _isProviderApproved(String verificationStatus) {
    final s = verificationStatus.trim().toLowerCase();
    return s == 'approved' || s == 'verified';
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
                      if (_isProviderApproved(profile.verificationStatus)) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified, color: BoostDriveTheme.primaryColor, size: 24),
                      ],
                    ],
                  ),
                  if (_isProviderApproved(profile.verificationStatus)) ...[
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
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildProviderServiceAreaAndHours(profile),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 32),
                    _buildProviderServiceTypes(profile),
                  ],
                  const SizedBox(height: 32),
                  _buildOperationalBusinessDetails(profile),
                  const SizedBox(height: 32),
                  _buildServiceSpecializations(profile),
                  const SizedBox(height: 32),
                  _buildFinancialPayout(),
                  const SizedBox(height: 32),
                  _buildTrustExperience(),
                  const SizedBox(height: 32),
                  _buildNotificationAlertSettings(),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 32),
                    _buildDocumentsVault(profile),
                  ],
                  const SizedBox(height: 32),
                  _buildProviderShopBranding(profile),
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
        // Banner edit button removed (no explicit banner edit control for now).
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

  // ignore: unused_element
  Widget _buildProviderMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _providerMetricCard('RATING', '—', Icons.star, Colors.amber),
          _providerMetricCard('SHIP SPEED', '—', Icons.local_shipping_outlined, BoostDriveTheme.primaryColor),
          _providerMetricCard('RESPONSE', '—', Icons.schedule, BoostDriveTheme.primaryColor),
        ];

        // On very narrow screens (mobile), allow cards to wrap to avoid overflow.
        if (constraints.maxWidth < 380) {
          final cardWidth = (constraints.maxWidth - 12) / 2; // two per row with spacing
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: cardWidth,
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        // Default: three cards in a row, each expanded equally.
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _providerMetricCard(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF667085),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D2939),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Service area (how far / where) and working hours — shown on Find a Provider cards.
  Widget _buildProviderServiceAreaAndHours(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: BoostDriveTheme.primaryColor, size: 22),
            const SizedBox(width: 10),
            Text('Service area & working hours', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1D2939))),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Shown to customers on Find a Provider. E.g. "Within 50 km of Windhoek" and "Mon–Fri 8am–6pm".',
          style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085)),
        ),
        const SizedBox(height: 16),
        _providerLabel('How far you\'re located / service area'),
        const SizedBox(height: 8),
        TextField(
          controller: _serviceAreaController,
          style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)),
          decoration: _providerInputDecoration(hint: 'e.g. Within 50 km of Windhoek, City centre'),
        ),
        const SizedBox(height: 16),
        _providerLabel('Working hours'),
        const SizedBox(height: 8),
        TextField(
          controller: _workingHoursController,
          style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)),
          decoration: _providerInputDecoration(hint: 'e.g. Mon–Fri 8am–6pm, Sat 9am–1pm or 24/7'),
        ),
      ],
    );
  }

  static const List<MapEntry<String, String>> _providerServiceTypeOptions = [
    MapEntry('mechanic', 'Mechanics'),
    MapEntry('towing', 'Towing'),
    MapEntry('parts', 'Parts'),
    MapEntry('rental', 'Rental'),
    MapEntry('service_station', 'Service station'),
  ];

  /// Mobile only: multi-select for which services this provider offers. Min 1 required.
  Widget _buildProviderServiceTypes(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.build_circle_outlined, color: BoostDriveTheme.primaryColor, size: 22),
            const SizedBox(width: 10),
            Text('Services you provide', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1D2939))),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select at least 1 service. You can select multiple.',
          style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _providerServiceTypeOptions.map((e) {
            final value = e.key;
            final label = e.value;
            final selected = _selectedServiceTypes.contains(value);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedServiceTypes = List<String>.from(_selectedServiceTypes)..remove(value);
                  } else {
                    _selectedServiceTypes = List<String>.from(_selectedServiceTypes)..add(value);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? BoostDriveTheme.primaryColor.withOpacity(0.15) : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? BoostDriveTheme.primaryColor : const Color(0xFFE4E7EC),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 20,
                      color: selected ? BoostDriveTheme.primaryColor : const Color(0xFF98A2B3),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? BoostDriveTheme.primaryColor : const Color(0xFF475467),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: BoostDriveTheme.primaryColor, size: 22),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1D2939))),
      ],
    );
  }

  void _toggleMultiSelect(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Widget _buildMultiSelectChips(List<MapEntry<String, String>> options, List<String> selected, void Function(String) onToggle) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((e) {
        final value = e.key;
        final label = e.value;
        final isSelected = selected.contains(value);
        return GestureDetector(
          onTap: () => onToggle(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? BoostDriveTheme.primaryColor.withOpacity(0.15) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? BoostDriveTheme.primaryColor : const Color(0xFFE4E7EC),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: isSelected ? BoostDriveTheme.primaryColor : const Color(0xFF98A2B3)),
                const SizedBox(width: 8),
                Text(label, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? BoostDriveTheme.primaryColor : const Color(0xFF475467))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOperationalBusinessDetails(UserProfile profile) {
    final isTowingOrSos = profile.role.toLowerCase().contains('towing') || profile.role.toLowerCase().contains('service');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Operational & Business Details', Icons.business_center_outlined),
        const SizedBox(height: 12),
        Text('Powers "Open Now" filter and SOS matching.', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
        const SizedBox(height: 16),
        if (isTowingOrSos) ...[
          Row(
            children: [
              Expanded(child: Text('Open 24/7', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1D2939)))),
              Switch(value: _businessHours24_7, onChanged: (v) => setState(() => _businessHours24_7 = v), activeTrackColor: BoostDriveTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 8),
          Text('When on, your profile shows "24/7" for Open Now. When off, use Working hours above.', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF98A2B3))),
          const SizedBox(height: 16),
        ],
        _providerLabel('Service radius (km)'),
        const SizedBox(height: 8),
        TextField(controller: _serviceRadiusKmController, keyboardType: TextInputType.number, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'Max distance you travel for jobs')),
        const SizedBox(height: 16),
        _providerLabel('Workshop address'),
        const SizedBox(height: 8),
        TextField(controller: _workshopAddressController, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'Physical location for drop-offs')),
        const SizedBox(height: 16),
        _providerLabel('Social & website'),
        const SizedBox(height: 8),
        TextField(controller: _socialFacebookController, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'Facebook URL')),
        const SizedBox(height: 8),
        TextField(controller: _socialInstagramController, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'Instagram URL')),
        const SizedBox(height: 8),
        TextField(controller: _websiteUrlController, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'Website URL')),
      ],
    );
  }

  static const List<MapEntry<String, String>> _brandOptions = [
    MapEntry('toyota', 'Toyota'), MapEntry('bmw', 'BMW'), MapEntry('land_rover', 'Land Rover'), MapEntry('ford', 'Ford'),
    MapEntry('mercedes', 'Mercedes'), MapEntry('nissan', 'Nissan'), MapEntry('volkswagen', 'Volkswagen'), MapEntry('other', 'Other'),
  ];
  static const List<MapEntry<String, String>> _serviceTagOptions = [
    MapEntry('diagnostics', 'Diagnostics'), MapEntry('hybrid_electric', 'Hybrid/Electric'), MapEntry('panel_beating', 'Panel Beating'),
    MapEntry('ac_repair', 'AC Repair'), MapEntry('gearbox', 'Gearbox Specialist'), MapEntry('brakes', 'Brakes'), MapEntry('engine', 'Engine'),
  ];
  static const List<MapEntry<String, String>> _towingOptions = [
    MapEntry('flatbed', 'Flatbed'), MapEntry('wheel_lift', 'Wheel Lift'), MapEntry('heavy_duty', 'Heavy Duty (trucks)'),
  ];

  Widget _buildServiceSpecializations(UserProfile profile) {
    final isTowing = profile.role.toLowerCase().contains('towing');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Service Specializations', Icons.build_circle_outlined),
        const SizedBox(height: 12),
        Text('Used for search filters and matching.', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
        const SizedBox(height: 16),
        _providerLabel('Brand expertise'),
        const SizedBox(height: 8),
        _buildMultiSelectChips(_brandOptions, _selectedBrandExpertise, (v) => _toggleMultiSelect(_selectedBrandExpertise, v)),
        const SizedBox(height: 16),
        _providerLabel('Service tags'),
        const SizedBox(height: 8),
        _buildMultiSelectChips(_serviceTagOptions, _selectedServiceTags, (v) => _toggleMultiSelect(_selectedServiceTags, v)),
        if (isTowing) ...[
          const SizedBox(height: 16),
          _providerLabel('Towing capabilities'),
          const SizedBox(height: 8),
          _buildMultiSelectChips(_towingOptions, _selectedTowingCapabilities, (v) => _toggleMultiSelect(_selectedTowingCapabilities, v)),
        ],
      ],
    );
  }

  Widget _buildFinancialPayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Financial & Payout', Icons.account_balance_wallet_outlined),
        const SizedBox(height: 12),
        Text('For automated payouts and customer price estimates.', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
        const SizedBox(height: 16),
        _providerLabel('Bank name'),
        const SizedBox(height: 8),
        TextField(controller: _bankNameController, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'e.g. Bank Windhoek, FNB')),
        const SizedBox(height: 12),
        _providerLabel('Branch'),
        const SizedBox(height: 8),
        TextField(controller: _bankBranchController, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'Branch name or code')),
        const SizedBox(height: 12),
        _providerLabel('Account number'),
        const SizedBox(height: 8),
        TextField(controller: _bankAccountNumberController, keyboardType: TextInputType.number, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'Bank account number')),
        const SizedBox(height: 12),
        _providerLabel(r'Estimated hourly rate (N$)'),
        const SizedBox(height: 8),
        TextField(controller: _standardLaborRateController, keyboardType: TextInputType.number, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'Standard labor rate for quotes')),
        const SizedBox(height: 12),
        _providerLabel('Tax / VAT number'),
        const SizedBox(height: 8),
        TextField(controller: _taxVatNumberController, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'For legal invoices')),
      ],
    );
  }

  Widget _buildTrustExperience() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Trust & Experience', Icons.verified_user_outlined),
        const SizedBox(height: 12),
        Text('Business bio and portfolio build customer trust.', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
        const SizedBox(height: 16),
        _providerLabel('Business bio (About us)'),
        const SizedBox(height: 8),
        TextField(controller: _businessBioController, maxLines: 4, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'Your history and passion')),
        const SizedBox(height: 16),
        _providerLabel('Team size (qualified technicians)'),
        const SizedBox(height: 8),
        TextField(controller: _teamSizeController, keyboardType: TextInputType.number, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1D2939)), decoration: _providerInputDecoration(hint: 'Number on-site')),
        const SizedBox(height: 16),
        Text('Gallery (up to 5 photos)', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF667085))),
        const SizedBox(height: 8),
        Text('Workshop, tow truck, or completed repairs. Upload coming soon.', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF98A2B3))),
      ],
    );
  }

  Widget _buildNotificationAlertSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notification & Alert Settings', Icons.notifications_active_outlined),
        const SizedBox(height: 12),
        Text('Control how you receive emergency and customer requests.', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Emergency (SOS) notifications', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1D2939)))),
            Switch(value: _sosAlertsEnabled, onChanged: (v) => setState(() => _sosAlertsEnabled = v), activeTrackColor: BoostDriveTheme.primaryColor),
          ],
        ),
        const SizedBox(height: 16),
        _providerLabel('Preferred communication'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCommChip('app_chat', 'App Chat'),
            _buildCommChip('phone', 'Phone'),
            _buildCommChip('whatsapp', 'WhatsApp'),
          ],
        ),
      ],
    );
  }

  Widget _buildCommChip(String value, String label) {
    final selected = _preferredCommunication == value;
    return GestureDetector(
      onTap: () => setState(() => _preferredCommunication = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? BoostDriveTheme.primaryColor.withOpacity(0.15) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? BoostDriveTheme.primaryColor : const Color(0xFFE4E7EC), width: selected ? 2 : 1),
        ),
        child: Text(label, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? BoostDriveTheme.primaryColor : const Color(0xFF475467))),
      ),
    );
  }

  Widget _buildDocumentsVault(UserProfile profile) {
    final hasDocs = _galleryUrls.isNotEmpty;
    final isApproved = _isProviderApproved(profile.verificationStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Documents Vault', Icons.folder_outlined),
        const SizedBox(height: 12),
        Text('Upload your official business documents for verification (e.g. BIPA, tax certificate).', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF667085))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE4E7EC))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _documentStatusRow(
                'Tax Certificate',
                isApproved
                    ? 'Approved'
                    : hasDocs
                        ? 'Submitted – pending review'
                        : 'Pending upload',
              ),
              const SizedBox(height: 12),
              _documentStatusRow(
                'Trade Certificate',
                isApproved
                    ? 'On file'
                    : hasDocs
                        ? 'Submitted – pending review'
                        : '—',
              ),
              const SizedBox(height: 12),
              _documentStatusRow(
                'BIPA / NTA',
                isApproved
                    ? 'On file'
                    : hasDocs
                        ? 'Submitted – pending review'
                        : '—',
              ),
              const SizedBox(height: 16),
              if (hasDocs) ...[
                Text('Uploaded documents', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF667085))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _galleryUrls.map((url) {
                    final fileName = url.split('/').last;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE4E7EC)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_outlined, size: 16, color: Color(0xFF667085)),
                          const SizedBox(width: 6),
                          Text(
                            fileName,
                            style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF344054)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _isUploadingDocuments ? null : () => _pickAndUploadProviderDocument(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoostDriveTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isUploadingDocuments
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.upload_file, size: 18, color: Colors.white),
                  label: Text(
                    _isUploadingDocuments ? 'Uploading…' : 'Upload documents',
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadProviderDocument() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profile = await ref.read(userProfileProvider(user.id).future);
    if (profile == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    try {
      setState(() {
        _isUploadingDocuments = true;
      });

      final bytes = await file.readAsBytes();
      final publicUrl = await ref.read(authServiceProvider).uploadProviderDocument(bytes, file.name);

      final updatedUrls = List<String>.from(_galleryUrls)..add(publicUrl);

      // Update local state so the UI reflects the new document immediately.
      setState(() {
        _galleryUrls = updatedUrls;
      });

      // Persist to Supabase profile.
      final updatedProfile = profile.copyWith(galleryUrls: updatedUrls);
      await ref.read(userServiceProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider(user.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Document uploaded. Our team will review it for verification.',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            backgroundColor: BoostDriveTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error uploading document: $e',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingDocuments = false;
        });
      }
    }
  }

  Widget _documentStatusRow(String name, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1D2939))),
        Text(status, style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF667085))),
      ],
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

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
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
          _serviceAreaController.text = profile.serviceAreaDescription;
          _workingHoursController.text = profile.workingHours;
          _businessHours24_7 = profile.businessHours24_7 ?? false;
          _serviceRadiusKmController.text = profile.serviceRadiusKm != null ? profile.serviceRadiusKm.toString() : '';
          _workshopAddressController.text = profile.workshopAddress ?? '';
          _socialFacebookController.text = profile.socialFacebook ?? '';
          _socialInstagramController.text = profile.socialInstagram ?? '';
          _websiteUrlController.text = profile.websiteUrl ?? '';
          _selectedBrandExpertise = List.from(profile.brandExpertise);
          _selectedServiceTags = List.from(profile.serviceTags);
          _selectedTowingCapabilities = List.from(profile.towingCapabilities);
          _bankAccountNumberController.text = profile.bankAccountNumber ?? '';
          _bankBranchController.text = profile.bankBranch ?? '';
          _bankNameController.text = profile.bankName ?? '';
          _standardLaborRateController.text = profile.standardLaborRate != null ? profile.standardLaborRate.toString() : '';
          _taxVatNumberController.text = profile.taxVatNumber ?? '';
          _businessBioController.text = profile.businessBio ?? '';
          _galleryUrls = List.from(profile.galleryUrls);
          _teamSizeController.text = profile.teamSize != null ? profile.teamSize.toString() : '';
          _sosAlertsEnabled = profile.sosAlertsEnabled ?? true;
          _preferredCommunication = profile.preferredCommunication ?? 'app_chat';
        }

        final isProvider = profile.role.toLowerCase().contains('service') || profile.role.toLowerCase().contains('seller') || profile.role == 'mechanic' || profile.role == 'towing' || profile.role == 'rental';
        final isWide = MediaQuery.of(context).size.width > 900;

        if (isProvider) {
          if (_shopDisplayNameController.text.isEmpty && profile.fullName.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _shopDisplayNameController.text.isEmpty) {
                _shopDisplayNameController.text = profile.fullName;
              }
            });
          }
          if (!kIsWeb) {
            final fromProfile = profile.providerServiceTypes;
            if (fromProfile.isNotEmpty && _selectedServiceTypes.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedServiceTypes.isEmpty) {
                  setState(() => _selectedServiceTypes = List<String>.from(fromProfile));
                }
              });
            }
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
