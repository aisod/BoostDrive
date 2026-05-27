import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'theme.dart';
import 'boostdrive_stepper.dart';
import 'dashboard_palette.dart';
import 'dashboard_typography.dart';
import 'dashboard_ui_components.dart';
import 'provider_profile_ui.dart';
import 'dashboard_theme_toggle.dart';

/// Editable name/phone row for SOS emergency contacts (backed by [EmergencyContact] on save).
class _EmergencyContactFieldPair {
  _EmergencyContactFieldPair({String nameText = '', String phoneText = ''})
      : name = TextEditingController(text: nameText),
        phone = TextEditingController(text: phoneText);

  final TextEditingController name;
  final TextEditingController phone;

  void dispose() {
    name.dispose();
    phone.dispose();
  }
}

class ProfileSettingsPage extends ConsumerStatefulWidget {
  /// When true, this page opens directly in provider edit mode (stepper only).
  /// Used as the dedicated "Edit Profile Settings" screen; back / Exit Edit Mode pops the route.
  const ProfileSettingsPage({super.key, this.initialProviderEditMode = false});

  final bool initialProviderEditMode;

  @override
  ConsumerState<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<_EmergencyContactFieldPair> _emergencyContactPairs = [];
  final _phoneFocusNode = FocusNode();
  
  // Dynamic business phone fields for providers
  final List<TextEditingController> _businessPhoneControllers = [];
  final List<FocusNode> _businessPhoneFocusNodes = [];
  
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploading = false;
  
  // Provider / shop profile (only used when role is service_provider or seller)
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
  // Dynamic "other" chips
  final List<MapEntry<String, String>> _dynamicBrandOptions = [];
  final List<MapEntry<String, String>> _dynamicServiceTagOptions = [];
  String? _otherBrandExpertiseLabel;
  String? _otherServiceTagLabel;

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
  Map<String, String> _documentStatuses = {};
  Map<String, String> _documentRejectionReasons = {};

  // Core business identity (provider)
  final _registeredBusinessNameController = TextEditingController();
  final _tradingNameController = TextEditingController();
  String _businessType = 'cc'; // cc | pty_ltd | sole_prop
  final _registrationNumberController = TextEditingController();
  final _yearsInOperationController = TextEditingController();
  String _primaryServiceCategory = 'mechanic'; // mechanic | towing | parts

  // Notification & Alert
  List<String> _preferredCommunication = ['app_chat'];

  // Optimistic UI state
  Uint8List? _optimisticImage;
  bool _isOptimisticDelete = false;

  // Provider edit flow (stepper)
  bool _isProviderEditMode = false;
  int _providerCurrentStep = 0;

  // Guard so we only hydrate controllers/flags from profile once per session.
  bool _didInitFromProfile = false;

  bool _isProviderRole(String role) {
    // DB values sometimes come in different formats (e.g. underscores, extra spaces,
    // combined roles like "mechanic & towing"). Normalize before matching.
    final cleaned = role
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]+'), ' ');

    if (cleaned.isEmpty) return false;

    // Standard variations for providers
    if (cleaned == 'service_provider' || cleaned == 'provider') return true;

    return cleaned.contains('provider') ||
        cleaned.contains('service provider') ||
        cleaned.contains('service pro') ||
        cleaned.contains('mechanic') ||
        cleaned.contains('towing') ||
        cleaned.contains('logistics') ||
        cleaned.contains('rental');
  }

  /// Registered service businesses (mechanic/towing/etc.) — not a casual marketplace seller.
  bool _isRegisteredServiceShop(UserProfile profile) => _isProviderRole(profile.role);

  /// Provider edit settings + in-flow provider edit can change profile photo.
  bool get _canChangeProfilePhoto =>
      widget.initialProviderEditMode || _isProviderEditMode;

  void _invalidateProfileAfterPhotoChange() {
    final user = ref.read(currentUserProvider);
    ref.invalidate(currentUserProvider);
    if (user != null) {
      ref.invalidate(userProfileProvider(user.id));
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialProviderEditMode) {
      _isProviderEditMode = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _disposeEmergencyContactPairs();
    _phoneFocusNode.dispose();
    for (var c in _businessPhoneControllers) {
      c.dispose();
    }
    for (var f in _businessPhoneFocusNodes) {
      f.dispose();
    }

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
    _registeredBusinessNameController.dispose();
    _tradingNameController.dispose();
    _registrationNumberController.dispose();
    _yearsInOperationController.dispose();
    super.dispose();
  }

  void _disposeEmergencyContactPairs() {
    for (final p in _emergencyContactPairs) {
      p.dispose();
    }
    _emergencyContactPairs.clear();
  }

  /// Hydrates editable rows from [UserProfile] (legacy single fields map into one row).
  void _syncEmergencyPairsFromProfile(UserProfile profile) {
    _disposeEmergencyContactPairs();
    final list = profile.emergencyContacts;
    if (list.isNotEmpty) {
      for (final c in list) {
        _emergencyContactPairs.add(_EmergencyContactFieldPair(nameText: c.name, phoneText: c.phone));
      }
    } else if (profile.emergencyContactName.isNotEmpty || profile.emergencyContactPhone.isNotEmpty) {
      _emergencyContactPairs.add(_EmergencyContactFieldPair(
        nameText: profile.emergencyContactName,
        phoneText: profile.emergencyContactPhone,
      ));
    }
    if (_emergencyContactPairs.isEmpty) {
      _emergencyContactPairs.add(_EmergencyContactFieldPair());
    }
  }

  List<EmergencyContact> _emergencyContactsFromPairs() {
    return _emergencyContactPairs
        .map((p) => EmergencyContact(name: p.name.text.trim(), phone: p.phone.text.trim()))
        .where((c) => c.name.isNotEmpty || c.phone.isNotEmpty)
        .toList();
  }

  void _replaceEmergencyContactPairsFrom(List<EmergencyContact> list) {
    _disposeEmergencyContactPairs();
    for (final c in list) {
      _emergencyContactPairs.add(_EmergencyContactFieldPair(nameText: c.name, phoneText: c.phone));
    }
    if (_emergencyContactPairs.isEmpty) {
      _emergencyContactPairs.add(_EmergencyContactFieldPair());
    }
  }

  String _emergencyContactsControlSubtitle() {
    final c = _emergencyContactsFromPairs();
    if (c.isEmpty) {
      return 'Set who should be reachable when you trigger SOS.';
    }
    if (c.length == 1) {
      final a = c.first;
      return '${a.name.isEmpty ? 'Contact' : a.name} · ${a.phone.isEmpty ? 'add phone' : a.phone}';
    }
    final a = c.first;
    return '${a.name.isEmpty ? 'Contact' : a.name} · ${a.phone.isEmpty ? 'add phone' : a.phone} · +${c.length - 1} more';
  }

  void _addBusinessPhoneField() {
    setState(() {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      _businessPhoneControllers.add(controller);
      _businessPhoneFocusNodes.add(focusNode);
      
      // Focus the new field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
    });
  }

  void _removeBusinessPhoneField(int index) {
    if (_businessPhoneControllers.length <= 1) return;
    setState(() {
      final controller = _businessPhoneControllers.removeAt(index);
      final focusNode = _businessPhoneFocusNodes.removeAt(index);
      controller.dispose();
      focusNode.dispose();
    });
  }

  Future<void> _loadDocumentStatuses(String providerId) async {
    try {
      final docs = await ref.read(userServiceProvider).getProviderDocuments(providerId);
      if (mounted) {
        setState(() {
          _documentStatuses = {};
          _documentRejectionReasons = {};
          for (final doc in docs) {
             final type = (doc['document_type'] ?? doc['Document_type'] ?? '').toString().trim();
             final status = (doc['status'] ?? doc['Status'] ?? '').toString().trim();
             final reason = (doc['rejection_reason'] ?? doc['Rejection_reason'] ?? '').toString().trim();
             if (type.isNotEmpty) {
               _documentStatuses[type] = status;
               _documentRejectionReasons[type] = reason;
             }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading document statuses: $e');
    }
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

  Widget _buildAccountActions() {
    final palette = DashboardPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final row = constraints.maxWidth > 600;
        final logout = OutlinedButton(
          onPressed: () => _handleLogout(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(140, 48),
            side: BorderSide(color: palette.primary),
            foregroundColor: palette.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Log Out', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        );
        final delete = TextButton(
          onPressed: () => _handleDeleteAccount(),
          style: TextButton.styleFrom(minimumSize: const Size(140, 48)),
          child: Text('Delete Account', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: palette.error)),
        );
        if (row) {
          return Row(children: [logout, const SizedBox(width: 16), delete]);
        }
        return Column(children: [logout, const SizedBox(height: 12), delete]);
      },
    );
  }

  Future<void> _removeProfilePhoto({required bool showInitials}) async {
    try {
      // Optimistic update: Immediately show the change
      setState(() {
        _isUploading = true;
        _optimisticImage = null;
        _isOptimisticDelete = true;
      });

      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update profile with null or empty string based on showInitials
      await ref.read(authServiceProvider).updateProfile(
        userId: user.id,
        avatarUrl: '',
      );

      _invalidateProfileAfterPhotoChange();

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
              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
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
              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
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
    if (_isSaving) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final profile = await ref.read(userProfileProvider(user.id).future);
    if (profile == null) return;

    setState(() => _isSaving = true);

    try {
      final fullName = _nameController.text.trim();
      if (fullName.isEmpty) {
        throw 'Full name is required';
      }

      // 1. Prepare base updates (common for both Customers & Providers)
      var updated = profile.copyWith(
        fullName: fullName,
        phoneNumber: _phoneController.text.trim(),
        emergencyContacts: _emergencyContactsFromPairs(),
      );

      // 2. Prepare role-specific updates (Providers/Sellers)
      final isProviderOrSeller = _isProviderRole(profile.role) || profile.isSeller;
      if (isProviderOrSeller) {
        final workingHours = _businessHours24_7 ? '24/7' : _workingHoursController.text.trim();
        updated = updated.copyWith(
          businessContactNumber: _businessPhoneControllers
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .join(', '),
          registeredBusinessName: _registeredBusinessNameController.text.trim(),
          tradingName: _tradingNameController.text.trim(),
          businessType: _businessType,
          registrationNumber: _registrationNumberController.text.trim(),
          yearsInOperation: int.tryParse(_yearsInOperationController.text.trim()),
          primaryServiceCategory: _primaryServiceCategory,
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
          preferredCommunication: _preferredCommunication.join(','),
        );
      }

      // 3. Email change flow with verification.
      final authClient = Supabase.instance.client.auth;
      final authUser = authClient.currentUser;
      final currentEmail = (authUser?.email?.isNotEmpty ?? false) ? authUser!.email! : profile.email;
      final newEmail = _emailController.text.trim();
      
      if (newEmail.isNotEmpty && newEmail != currentEmail) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Confirm Email Change', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700)),
            content: Text('Are you sure you want to change your email to $newEmail? A verification link will be sent to the new address.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
            ],
          ),
        );
        
        if (confirmed == true) {
          await authClient.updateUser(UserAttributes(email: newEmail));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification link sent to $newEmail. Please confirm it.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }

      // 4. Save using userServiceProvider (robust .upsert() handles all fields correctly)
      await ref.read(userServiceProvider).updateProfile(updated);
      
      // Invalidate providers list if they are a provider/seller so search results update
      if (isProviderOrSeller) {
        ref.invalidate(verifiedProvidersProvider);
      }

      _didInitFromProfile = false; // Force re-hydration from new profile data
      ref.invalidate(userProfileProvider(user.id));
      
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save Failed: $e'), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// True when admin has approved this provider (verification_status = approved or verified).
  bool _isProviderApproved(String verificationStatus) {
    final s = verificationStatus.trim().toLowerCase();
    return s == 'approved' || s == 'verified';
  }

  /// Helper to get a human-readable specialization label for the profile header.
  String _getCategoryLabel(UserProfile profile) {
    final cat = profile.primaryServiceCategory?.toLowerCase();
    if (cat == 'mechanic') return 'Mechanic';
    if (cat == 'towing') return 'Towing Service';
    if (cat == 'parts') return 'Parts Supplier';
    
    // Fallback to role or capitalization
    if (cat != null && cat.isNotEmpty) {
      return cat[0].toUpperCase() + cat.substring(1).replaceAll('_', ' ');
    }
    return profile.role == 'service_provider' ? 'Service Provider' : profile.role;
  }

  Future<void> _showProfilePhotoOptions() async {
    final palette = DashboardPalette.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: palette.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.2)),
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
                    color: palette.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Profile Photo',
                  style: DashboardTypography.headlineMd(palette).copyWith(fontSize: 18),
                ),
                const SizedBox(height: 20),
                _buildPhotoOption(
                  palette: palette,
                  icon: Icons.photo_library,
                  title: 'Choose Photo',
                  subtitle: 'Select from your device',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadImage();
                  },
                ),
                _buildPhotoOption(
                  palette: palette,
                  icon: Icons.person_outline,
                  title: 'No Profile Photo',
                  subtitle: 'Display your initials',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _removeProfilePhoto(showInitials: true);
                  },
                ),
                _buildPhotoOption(
                  palette: palette,
                  icon: Icons.delete_outline,
                  title: 'Delete Photo',
                  subtitle: 'Remove current photo',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _removeProfilePhoto(showInitials: false);
                  },
                  isDestructive: true,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required DashboardPalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final accent = isDestructive ? palette.error : palette.primary;
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
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DashboardTypography.labelLg(palette).copyWith(
                      color: isDestructive ? palette.error : palette.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: DashboardTypography.bodySm(palette)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.muted, size: 20),
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

          final uploadName = _profileImageUploadFileName(image.name);
          final publicUrl = await ref.read(authServiceProvider).uploadProfileImage(
            croppedBytes,
            uploadName,
          );

          final user = ref.read(currentUserProvider);
          if (user != null) {
            await ref.read(authServiceProvider).updateProfile(
              userId: user.id,
              avatarUrl: publicUrl,
            );

            _invalidateProfileAfterPhotoChange();
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
        } else if (mounted) {
          setState(() {
            _isUploading = false;
            _optimisticImage = null;
          });
        }
      } catch (e) {
        debugPrint('Error in profile photo upload: $e');
        if (mounted) {
          _showProfilePhotoUploadError(e);
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

  /// Web cropper often omits an extension; storage bucket requires image/* MIME types.
  String _profileImageUploadFileName(String pickedName) {
    final trimmed = pickedName.trim();
    const allowed = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
    if (trimmed.contains('.')) {
      final ext = trimmed.split('.').last.toLowerCase();
      if (allowed.contains(ext)) return trimmed;
    }
    return 'avatar.jpg';
  }

  void _showProfilePhotoUploadError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 12),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Change Password',
            style: TextStyle(fontFamily: 'Manrope', 
              fontWeight: FontWeight.w800,
              color: const Color(0xFF000000),
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
                    obscureText: obscureCurrent,
                    onToggleVisibility: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                  ),
                  const SizedBox(height: 16),
                   _buildPasswordTextField(
                    controller: newPasswordController,
                    label: 'New Password',
                    hint: 'Enter new password',
                    obscureText: obscureNew,
                    onToggleVisibility: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 16),
                   _buildPasswordTextField(
                    controller: confirmPasswordController,
                    label: 'Confirm New Password',
                    hint: 'Re-enter new password',
                    obscureText: obscureConfirm,
                    onToggleVisibility: () => setDialogState(() => obscureConfirm = !obscureConfirm),
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
              child: Text('Cancel', style: TextStyle(fontFamily: 'Manrope', color: const Color(0xFF000000), fontWeight: FontWeight.w700)),
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
                : Text('Save', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: Colors.white)),
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
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(fontFamily: 'Manrope', fontSize: 14, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
            filled: true,
            fillColor: const Color(0xFFFFFFFF),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF000000),
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFCCAA))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFCCAA))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BoostDriveTheme.primaryColor, width: 2)),
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
    final palette = DashboardPalette.of(context);
    final isEditOnlyPage = widget.initialProviderEditMode;

    return Scaffold(
      backgroundColor: palette.background,
      extendBodyBehindAppBar: true,
      appBar: ProviderProfileUi.providerAppBar(
        context: context,
        palette: palette,
        title: isEditOnlyPage ? 'Edit Profile Settings' : 'Provider Profile',
        onBack: () => Navigator.pop(context),
        action: isEditOnlyPage
            ? ProviderProfileUi.exitEditTextButton(onPressed: () => Navigator.pop(context))
            : ProviderProfileUi.editProfilePillButton(
                palette: palette,
                label: 'Edit Profile',
                onPressed: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileSettingsPage(initialProviderEditMode: true),
                    ),
                  );
                  if (mounted) {
                    _didInitFromProfile = false;
                    ref.invalidate(userProfileProvider(profile.uid));
                    setState(() {});
                  }
                },
              ),
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
                  ProviderProfileUi.identityName(
                    palette,
                    profile.displayName,
                    verified: _isProviderApproved(profile.verificationStatus),
                  ),
                  if (_isProviderApproved(profile.verificationStatus)) ...[
                    const SizedBox(height: 10),
                    ProviderProfileUi.verifiedChip(
                      palette,
                      'Verified ${_getCategoryLabel(profile)}',
                    ),
                  ],
                ],
              ),
            ),
            if (isEditOnlyPage || _isProviderEditMode)
              _buildProviderStepperContent(profile, isWide)
            else
              _buildProviderViewContent(profile, isWide),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderViewContent(UserProfile profile, bool isWide) {
    final palette = DashboardPalette.of(context);
    final hPad = isWide ? 40.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          if (isWide && !_isProviderEditMode)
            _buildProviderViewBento(profile, palette)
          else ...[
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.business_center_outlined,
              title: 'Business Information',
              child: _buildBusinessInformation(profile),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 24),
              ProviderProfileUi.sectionCard(
                palette: palette,
                icon: Icons.emergency_outlined,
                title: 'Safety & SOS',
                accentTint: true,
                child: _buildSafetySection(),
              ),
            ],
            const SizedBox(height: 24),
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.location_on_outlined,
              title: 'Service Area & Hours',
              child: _buildProviderServiceAreaAndHours(profile),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 24),
              ProviderProfileUi.sectionCard(
                palette: palette,
                icon: Icons.build_circle_outlined,
                title: 'Services You Provide',
                child: _buildProviderServiceTypes(profile),
              ),
            ],
            const SizedBox(height: 24),
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.business_center_outlined,
              title: 'Operational & Business Details',
              child: _buildOperationalBusinessDetails(profile),
            ),
            const SizedBox(height: 24),
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.build_circle_outlined,
              title: 'Service Specializations',
              child: _buildServiceSpecializations(profile),
            ),
            const SizedBox(height: 24),
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Financial & Payout',
              accentTint: true,
              child: _buildFinancialPayout(),
            ),
            const SizedBox(height: 24),
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.verified_user_outlined,
              title: 'Trust & Experience',
              child: _buildTrustExperience(),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 24),
              ProviderProfileUi.sectionCard(
                palette: palette,
                icon: Icons.folder_outlined,
                title: 'Documents Vault',
                child: _buildDocumentsVault(profile),
              ),
            ],
          ],
          const SizedBox(height: 32),
          ProviderProfileUi.sectionCard(
            palette: palette,
            icon: Icons.hub_outlined,
            title: 'Control Center',
            child: _buildControlCenterSection(profile),
          ),
          const SizedBox(height: 32),
          _buildAccountActions(),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  'BoostDrive Version 2.4.1 (1209)',
                  style: DashboardTypography.bodySm(palette),
                ),
                Text(
                  'AUTHORIZED PROVIDER INSTANCE',
                  style: DashboardTypography.sectionLabel(palette).copyWith(fontSize: 10, letterSpacing: 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProviderViewBento(UserProfile profile, DashboardPalette palette) {
    final businessTypeLabel = switch (_businessType) {
      'pty_ltd' => 'Pty Ltd',
      'sole_prop' => 'Sole Proprietor',
      _ => 'Close Corporation (CC)',
    };
    final categoryLabel = _getCategoryLabel(profile);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            if (!wide) {
              return Column(
                children: [
                  ProviderProfileUi.sectionCard(
                    palette: palette,
                    icon: Icons.business_center_outlined,
                    title: 'Business Information',
                    child: _buildBusinessInformation(profile),
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: ProviderProfileUi.sectionCard(
                    palette: palette,
                    icon: Icons.business_center_outlined,
                    title: 'Business Information',
                    child: _buildBusinessInformationReadOnlyGrid(profile, businessTypeLabel),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      ProviderProfileUi.sectionCard(
                        palette: palette,
                        icon: Icons.engineering_outlined,
                        title: 'Operational Details',
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            ProviderProfileUi.statRow(
                              palette,
                              'In Operation',
                              _yearsInOperationController.text.isEmpty
                                  ? '—'
                                  : '${_yearsInOperationController.text} Years',
                            ),
                            Divider(color: palette.outlineVariant.withValues(alpha: 0.2)),
                            ProviderProfileUi.statRow(palette, 'Category', categoryLabel),
                            Divider(color: palette.outlineVariant.withValues(alpha: 0.2)),
                            ProviderProfileUi.statRow(
                              palette,
                              'Team Size',
                              _teamSizeController.text.isEmpty ? '—' : '${_teamSizeController.text} Experts',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ProviderProfileUi.sectionCard(
                        palette: palette,
                        icon: Icons.payments_outlined,
                        title: 'Financial & Payout',
                        accentTint: true,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: palette.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Standard Rate', style: DashboardTypography.labelMd(palette)),
                                  Text(
                                    _standardLaborRateController.text.isEmpty
                                        ? '—'
                                        : 'N\$ ${_standardLaborRateController.text}/hr',
                                    style: DashboardTypography.headlineMd(palette).copyWith(
                                      color: palette.primary,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: palette.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _bankNameController.text.isEmpty ? 'Bank not set' : _bankNameController.text,
                                    style: DashboardTypography.labelMd(palette),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _bankAccountNumberController.text.isEmpty
                                        ? '•••• •••• —'
                                        : '•••• •••• ${_bankAccountNumberController.text.length > 4 ? _bankAccountNumberController.text.substring(_bankAccountNumberController.text.length - 4) : _bankAccountNumberController.text}',
                                    style: DashboardTypography.bodyMd(palette).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
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
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth > 700;
            final serviceArea = ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.map_outlined,
              title: 'Service Area & Hours',
              child: Column(
                children: [
                  ProviderProfileUi.iconFactTile(
                    palette: palette,
                    icon: Icons.location_on,
                    title: 'Service Range',
                    subtitle: _serviceAreaController.text.isEmpty ? 'Not set' : _serviceAreaController.text,
                  ),
                  const SizedBox(height: 20),
                  ProviderProfileUi.iconFactTile(
                    palette: palette,
                    icon: Icons.schedule,
                    title: 'Working Hours',
                    subtitle: _workingHoursController.text.isEmpty ? 'Not set' : _workingHoursController.text,
                  ),
                ],
              ),
            );
            final specs = ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.stars_outlined,
              title: 'Specializations',
              child: _buildServiceSpecializationsReadOnly(palette),
            );
            if (!twoCol) {
              return Column(children: [serviceArea, const SizedBox(height: 24), specs]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: serviceArea),
                const SizedBox(width: 24),
                Expanded(child: specs),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        ProviderProfileUi.sectionCard(
          palette: palette,
          icon: Icons.history_edu_outlined,
          title: 'Trust & Experience',
          child: _buildTrustExperience(),
        ),
        if (!kIsWeb) ...[
          const SizedBox(height: 24),
          ProviderProfileUi.sectionCard(
            palette: palette,
            icon: Icons.folder_outlined,
            title: 'Documents Vault',
            child: _buildDocumentsVault(profile),
          ),
        ],
      ],
    );
  }

  Widget _buildBusinessInformationReadOnlyGrid(UserProfile profile, String businessTypeLabel) {
    final palette = DashboardPalette.of(context);
    final contacts = _businessPhoneControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth > 520;
        final children = <Widget>[
          ProviderProfileUi.readOnlyField(
            palette,
            'Registered Business Name',
            _registeredBusinessNameController.text,
          ),
          ProviderProfileUi.readOnlyField(palette, 'Trading Name', _tradingNameController.text),
          ProviderProfileUi.readOnlyField(
            palette,
            'Contact Details',
            contacts.isEmpty ? 'Not set' : contacts.join('\n'),
          ),
          ProviderProfileUi.readOnlyField(
            palette,
            'Business Type & Registration',
            '${businessTypeLabel}\n${_registrationNumberController.text.isEmpty ? '—' : _registrationNumberController.text}',
          ),
        ];
        if (!twoCol) {
          return Column(
            children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 20), child: w)).toList(),
          );
        }
        return Wrap(
          spacing: 48,
          runSpacing: 24,
          children: children.map((w) => SizedBox(width: (constraints.maxWidth - 48) / 2, child: w)).toList(),
        );
      },
    );
  }

  Widget _buildServiceSpecializationsReadOnly(DashboardPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manufacturer Experts', style: DashboardTypography.sectionLabel(palette)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedBrandExpertise.isEmpty
              ? [Text('None selected', style: DashboardTypography.bodySm(palette))]
              : _selectedBrandExpertise
                  .map((k) => _providerChipLabel(_brandOptions, _dynamicBrandOptions, k))
                  .map((label) => ProviderProfileUi.brandChip(palette, label))
                  .toList(),
        ),
        const SizedBox(height: 20),
        Text('Services Provided', style: DashboardTypography.sectionLabel(palette)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedServiceTags.isEmpty
              ? [Text('None selected', style: DashboardTypography.bodySm(palette))]
              : _selectedServiceTags
                  .map((k) => _providerChipLabel(_serviceTagOptions, _dynamicServiceTagOptions, k))
                  .map((label) => ProviderProfileUi.specializationChip(palette, label))
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildProviderStepperContent(UserProfile profile, bool isWide) {
    const steps = [
      'Business Profile',
      'Legal Docs & Certs',
    ];
    final palette = DashboardPalette.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProviderProfileUi.providerStepper(
            palette: palette,
            currentStep: _providerCurrentStep,
            stepTitles: steps,
          ),
          const SizedBox(height: 16),
          _buildProviderStepContent(profile),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_providerCurrentStep > 0)
                TextButton(
                  onPressed: () {
                    setState(() => _providerCurrentStep--);
                  },
                  child: const Text('Back'),
                ),
              const Spacer(),
              ElevatedButton(
                style: ProviderProfileUi.primaryButtonStyle(palette),
                onPressed: () async {
                  if (!_isProviderStepValid(_providerCurrentStep, profile)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _providerCurrentStep == 1
                                ? 'Please upload all required documents before continuing.'
                                : 'Please complete all fields in this section before continuing.',
                            style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                    return;
                  }

                  final isLastStep = _providerCurrentStep >= steps.length - 1;

                  // Prevent final save if mandatory legal docs are missing.
                  final hasDocs = _galleryUrls.isNotEmpty;
                  if (isLastStep && !hasDocs) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please upload your required legal documents before saving your profile.'),
                        ),
                      );
                    }
                    return;
                  }

                  if (!isLastStep) {
                    setState(() => _providerCurrentStep++);
                  } else {
                    await _handleSaveProfile();
                    if (mounted) {
                      if (widget.initialProviderEditMode) {
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          _isProviderEditMode = false;
                          _providerCurrentStep = 0;
                        });
                      }
                    }
                  }
                },
                child: Text(
                  _providerCurrentStep < steps.length - 1 ? 'Next' : 'Save Profile',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Global actions for the provider edit flow so Cancel / Save are
          // available from every step, not only on the final summary.
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final user = ref.read(currentUserProvider);
                    if (user != null) {
                      _didInitFromProfile = false;
                      ref.invalidate(userProfileProvider(user.id));
                    }
                    if (widget.initialProviderEditMode) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _isProviderEditMode = false;
                        _providerCurrentStep = 0;
                      });
                    }
                  },
                  style: ProviderProfileUi.outlinedButtonStyle(palette),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: palette.onBackground),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ProviderProfileUi.primaryButtonStyle(palette),
                  onPressed: () async {
                    // Reuse the same validation and legal-document checks as the
                    // stepper validation, but allow saving from any step.
                    if (!_isProviderStepValid(_providerCurrentStep, profile)) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _providerCurrentStep == 1
                                  ? 'Please upload all required documents before continuing.'
                                  : 'Please complete all fields in this section before saving.',
                              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                      return;
                    }

                    await _handleSaveProfile();
                    // Stay on the Edit Profile Settings page after saving so
                    // providers can continue refining other sections. The
                    // global "Exit Edit Mode" action in the app bar still
                    // closes this screen when they are done.
                  },
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProviderStepContent(UserProfile profile) {
    final palette = _providerPalette;
    switch (_providerCurrentStep) {
      case 0: // Business Profile + Contact Info + Specializations + Location & Payouts
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.business_center_outlined,
              title: 'Business Information',
              child: _buildBusinessInformation(profile),
            ),
            const SizedBox(height: 24),
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.verified_user_outlined,
              title: 'Trust & Experience',
              child: _buildTrustExperience(),
            ),
            const SizedBox(height: 24),
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.build_circle_outlined,
              title: 'Service Specializations',
              child: _buildServiceSpecializations(profile),
            ),
            const SizedBox(height: 24),
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.business_center_outlined,
              title: 'Operational & Business Details',
              child: _buildOperationalBusinessDetails(profile),
            ),
            const SizedBox(height: 24),
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.location_on_outlined,
              title: 'Service Area & Hours',
              child: _buildProviderServiceAreaAndHours(profile),
            ),
            const SizedBox(height: 24),
            ProviderProfileUi.sectionCard(
              palette: palette,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Financial & Payout',
              accentTint: true,
              child: _buildFinancialPayout(),
            ),
          ],
        );
      case 1: // Legal Docs & Certs (BIPA/ID + NTA/RA)
        return ProviderProfileUi.sectionCard(
          palette: palette,
          icon: Icons.folder_outlined,
          title: 'Documents Vault',
          child: _buildDocumentsVault(profile),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  bool _isProviderStepValid(int stepIndex, UserProfile profile) {
    switch (stepIndex) {
      case 0: // Business Profile (all combined)
        return _tradingNameController.text.trim().isNotEmpty;
      case 1: // Legal & Identity, professional permits, tax and social compliance
        // All required legal and compliance documents must be uploaded before continuing.
        final isTowingProvider =
            (profile.role.toLowerCase() == 'towing') || (_primaryServiceCategory.toLowerCase() == 'towing');
        final requiredSlots = <int>[0, 1, 2, 3, 5, 6]; // BIPA or CC1, Owner ID, Fitness, NTA, NamRA, Social Security
        if (isTowingProvider) {
          requiredSlots.add(4); // Road Carrier Permit
        }
        return requiredSlots.every(
          (index) =>
              index < _galleryUrls.length &&
              _galleryUrls[index].trim().isNotEmpty,
        );
      default:
        return true;
    }
  }

  Widget _buildProfileAvatarContent({
    required UserProfile profile,
    required DashboardPalette palette,
    required double radius,
    required double initialsFontSize,
    String? initialsName,
  }) {
    final showInitials = _optimisticImage == null &&
        (_isOptimisticDelete || profile.profileImg.isEmpty);
    final name = initialsName ?? profile.displayName;
    return CircleAvatar(
      radius: radius,
      backgroundColor: palette.surfaceContainerLow,
      backgroundImage: _optimisticImage != null
          ? MemoryImage(_optimisticImage!) as ImageProvider
          : (!showInitials ? NetworkImage(profile.profileImg) : null),
      child: showInitials
          ? Text(
              getInitials(name),
              style: GoogleFonts.manrope(
                fontSize: initialsFontSize,
                fontWeight: FontWeight.w800,
                color: palette.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildProviderBanner(UserProfile profile) {
    final palette = DashboardPalette.of(context);
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final canChangePhoto = _canChangeProfilePhoto;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180 + topInset,
          width: double.infinity,
          decoration: ProviderProfileUi.heroBannerDecoration(palette),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -44,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  cursor: canChangePhoto ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: (_isUploading || !canChangePhoto) ? null : _showProfilePhotoOptions,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: ProviderProfileUi.premiumShadow(palette),
                          ),
                          child: _buildProfileAvatarContent(
                            profile: profile,
                            palette: palette,
                            radius: 52,
                            initialsFontSize: 28,
                          ),
                        ),
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          ),
                        if (canChangePhoto && !_isUploading)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: palette.primaryContainer,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (canChangePhoto) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tap photo to change',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminBanner(UserProfile profile) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Header Banner (Fixed Height 180px)
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: BoostDriveTheme.primaryColor,
          ),
        ),
        
        // Avatar and Identity horizontally aligned inside banner
        Positioned(
          left: 32,
          bottom: 16, 
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar with thick white border
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _isUploading ? null : _showProfilePhotoOptions,
                  child: Container(
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
                            backgroundColor: const Color(0xFFFFFFFF),
                            backgroundImage: _optimisticImage != null
                                ? MemoryImage(_optimisticImage!) as ImageProvider
                                : (profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null),
                            child: (profile.profileImg.isEmpty && _optimisticImage == null)
                                ? Text(
                                    getInitials(profile.displayName),
                                    style: TextStyle(fontFamily: 'Manrope', 
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: BoostDriveTheme.primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (_isUploading)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color(0x22FF6600),
                              child: Center(
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 32),
              
              // Identity Info Section (Moves to right of Avatar)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.displayName,
                          style: const TextStyle(fontFamily: 'Manrope', 
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
                            color: Colors.white.withAlpha(230),
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

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
        border: Border.all(color: const Color(0xFFFFCCAA)),
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
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF000000),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF000000),
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
        _providerSectionSubtitle(
          'Shown to customers on Find a Provider. E.g. "Within 50 km of Windhoek" and "Mon–Fri 8am–6pm".',
        ),
        _providerLabel('How far you\'re located / service area'),
        const SizedBox(height: 8),
        TextField(
          controller: _serviceAreaController,
          readOnly: !_isProviderEditMode,
          enabled: _isProviderEditMode,
          style: _providerFieldStyle(),
          decoration: _providerInputDecoration(hint: 'e.g. Within 50 km of Windhoek, City centre'),
        ),
        const SizedBox(height: 16),
        _providerLabel('Working hours'),
        const SizedBox(height: 8),
        TextField(
          controller: _workingHoursController,
          readOnly: !_isProviderEditMode,
          enabled: _isProviderEditMode,
          style: _providerFieldStyle(),
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
    final palette = _providerPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _providerSectionSubtitle('Select at least 1 service. You can select multiple.'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _providerServiceTypeOptions.map((e) {
            final value = e.key;
            final label = e.value;
            final selected = _selectedServiceTypes.contains(value);
            return ProviderProfileUi.choiceChip(
              palette: palette,
              label: label,
              selected: selected,
              onTap: !_isProviderEditMode
                  ? null
                  : () {
                      setState(() {
                        if (selected) {
                          _selectedServiceTypes = List<String>.from(_selectedServiceTypes)..remove(value);
                        } else {
                          _selectedServiceTypes = List<String>.from(_selectedServiceTypes)..add(value);
                        }
                      });
                    },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return ProviderProfileUi.sectionHeader(
      palette: DashboardPalette.of(context),
      title: title,
      icon: icon,
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
    final palette = _providerPalette;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((e) {
        final value = e.key;
        final label = e.value;
        final isSelected = selected.contains(value);
        return ProviderProfileUi.choiceChip(
          palette: palette,
          label: label,
          selected: isSelected,
          onTap: !_isProviderEditMode
              ? null
              : () async {
            if (!_isProviderEditMode) return;
            if (options.contains(const MapEntry('other', 'Other')) && value == 'other') {
              final result = await showDialog<String>(
                context: context,
                builder: (context) {
                  final controller = TextEditingController(text: _otherBrandExpertiseLabel);
                  return AlertDialog(
                    title: Text(
                      'Other brand expertise',
                      style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700),
                    ),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Enter one brand name',
                        helperText: 'Example: Jeep',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                        child: Text(
                          'Save',
                          style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (result != null && result.isNotEmpty) {
                setState(() {
                  _otherBrandExpertiseLabel = result;
                  final key = 'custom_brand_${result.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
                  final exists = _dynamicBrandOptions.any((entry) => entry.key == key);
                  if (!exists) {
                    _dynamicBrandOptions.add(MapEntry(key, result));
                  }
                  if (!selected.contains(key)) {
                    selected.add(key);
                  }
                });
              } else {
                // If dialog was cancelled, leave the "Other" chip as-is.
              }
            } else if (options.contains(const MapEntry('other_service', 'Other')) && value == 'other_service') {
              final result = await showDialog<String>(
                context: context,
                builder: (context) {
                  final controller = TextEditingController(text: _otherServiceTagLabel);
                  return AlertDialog(
                    title: Text(
                      'Other service tag',
                      style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700),
                    ),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Describe the other service, you can add more than one separated by commas',
                        helperText: 'Example: Auto electrical, Air suspension',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                        child: Text(
                          'Save',
                          style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (result != null && result.isNotEmpty) {
                setState(() {
                  _otherServiceTagLabel = result;
                  final key = 'custom_service_${result.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
                  final exists = _dynamicServiceTagOptions.any((entry) => entry.key == key);
                  if (!exists) {
                    _dynamicServiceTagOptions.add(MapEntry(key, result));
                  }
                  if (!selected.contains(key)) {
                    selected.add(key);
                  }
                });
              } else {
                // Cancelled, leave the "Other" chip untouched.
              }
            } else {
              onToggle(value);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildOperationalBusinessDetails(UserProfile profile) {
    final isTowingOrSos = profile.role.toLowerCase().contains('towing') || profile.role.toLowerCase().contains('service');
    final palette = _providerPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _providerSectionSubtitle('Powers "Open Now" filter and SOS matching.'),
        const SizedBox(height: 16),
        if (isTowingOrSos) ...[
          Row(
            children: [
              Expanded(child: Text('Open 24/7', style: DashboardTypography.labelMd(palette))),
              Switch(
                value: _businessHours24_7,
                onChanged: _isProviderEditMode ? (v) => setState(() => _businessHours24_7 = v) : null,
                activeThumbColor: palette.primaryContainer,
                activeTrackColor: palette.primary.withValues(alpha: 0.35),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _providerSectionSubtitle('When on, your profile shows "24/7" for Open Now. When off, use Working hours above.'),
          const SizedBox(height: 16),
        ],
        _providerLabel('Service radius (km)'),
        const SizedBox(height: 8),
        TextField(
          controller: _serviceRadiusKmController,
          keyboardType: TextInputType.number,
          readOnly: !_isProviderEditMode,
          enabled: _isProviderEditMode,
          style: _providerFieldStyle(),
          decoration: _providerInputDecoration(hint: 'Max distance you travel for jobs'),
        ),
        const SizedBox(height: 16),
        _providerLabel('Workshop address'),
        const SizedBox(height: 8),
        TextField(controller: _workshopAddressController, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: _providerFieldStyle(), decoration: _providerInputDecoration(hint: 'Physical location for drop-offs')),
        const SizedBox(height: 16),
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
    MapEntry('other_service', 'Other'),
  ];
  static const List<MapEntry<String, String>> _towingOptions = [
    MapEntry('flatbed', 'Flatbed'), MapEntry('wheel_lift', 'Wheel Lift'), MapEntry('heavy_duty', 'Heavy Duty (trucks)'),
  ];

  Widget _buildServiceSpecializations(UserProfile profile) {
    final isTowing = profile.role.toLowerCase().contains('towing');
    final brandOptionsForView = _isProviderEditMode
        ? [..._brandOptions, ..._dynamicBrandOptions]
        : [
            ..._brandOptions.where((o) => o.key != 'other'),
            ..._dynamicBrandOptions,
          ];
    final serviceTagOptionsForView = _isProviderEditMode
        ? [..._serviceTagOptions, ..._dynamicServiceTagOptions]
        : [
            ..._serviceTagOptions.where((o) => o.key != 'other_service'),
            ..._dynamicServiceTagOptions,
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _providerSectionSubtitle('Used for search filters and matching.'),
        const SizedBox(height: 16),
        _providerLabel('Brand expertise'),
        const SizedBox(height: 8),
        _buildMultiSelectChips(
          brandOptionsForView,
          _selectedBrandExpertise,
          (v) => _toggleMultiSelect(_selectedBrandExpertise, v),
        ),
        const SizedBox(height: 16),
        _providerLabel('Service tags'),
        const SizedBox(height: 8),
        _buildMultiSelectChips(
          serviceTagOptionsForView,
          _selectedServiceTags,
          (v) => _toggleMultiSelect(_selectedServiceTags, v),
        ),
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
        _providerSectionSubtitle('For automated payouts and customer price estimates.'),
        const SizedBox(height: 16),
        _providerLabel('Bank name'),
        const SizedBox(height: 8),
        TextField(controller: _bankNameController, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: _providerFieldStyle(), decoration: _providerInputDecoration(hint: 'e.g. Bank Windhoek, FNB')),
        const SizedBox(height: 12),
        _providerLabel('Branch'),
        const SizedBox(height: 8),
        TextField(controller: _bankBranchController, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: _providerFieldStyle(), decoration: _providerInputDecoration(hint: 'Branch name or code')),
        const SizedBox(height: 12),
        _providerLabel('Account number'),
        const SizedBox(height: 8),
        TextField(controller: _bankAccountNumberController, keyboardType: TextInputType.number, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: _providerFieldStyle(), decoration: _providerInputDecoration(hint: 'Bank account number')),
        const SizedBox(height: 12),
        _providerLabel(r'Estimated hourly rate (N$)'),
        const SizedBox(height: 8),
        TextField(controller: _standardLaborRateController, keyboardType: TextInputType.number, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: _providerFieldStyle(), decoration: _providerInputDecoration(hint: 'Standard labor rate for quotes')),
        const SizedBox(height: 12),
        _providerLabel('Tax / VAT number'),
        const SizedBox(height: 8),
        TextField(controller: _taxVatNumberController, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: _providerFieldStyle(), decoration: _providerInputDecoration(hint: 'For legal invoices')),
      ],
    );
  }

  // Gallery images use slots 7-16 in _galleryUrls to avoid conflicts with
  // legal document slots 0-6. Maximum 10 gallery images, minimum 1.
  static const int _gallerySlotOffset = 7;
  static const int _galleryMaxImages = 10;

  List<String> get _galleryImageUrls {
    final images = <String>[];
    for (int i = _gallerySlotOffset; i < _gallerySlotOffset + _galleryMaxImages; i++) {
      if (i < _galleryUrls.length && _galleryUrls[i].trim().isNotEmpty) {
        images.add(_galleryUrls[i]);
      }
    }
    return images;
  }

  Future<void> _pickAndUploadGalleryImage() async {
    if (_galleryImageUrls.length >= _galleryMaxImages) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final profile = await ref.read(userProfileProvider(user.id).future);
    if (profile == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image == null) return;

    try {
      setState(() => _isUploadingDocuments = true);

      final bytes = await image.readAsBytes();
      final publicUrl = await ref.read(authServiceProvider).uploadGalleryImage(bytes, image.name);

      // Find first empty gallery slot (7-16)
      final updatedUrls = List<String>.from(_galleryUrls);
      while (updatedUrls.length < _gallerySlotOffset + _galleryMaxImages) {
        updatedUrls.add('');
      }
      for (int i = _gallerySlotOffset; i < _gallerySlotOffset + _galleryMaxImages; i++) {
        if (updatedUrls[i].trim().isEmpty) {
          updatedUrls[i] = publicUrl;
          break;
        }
      }

      setState(() => _galleryUrls = updatedUrls);
      final updatedProfile = profile.copyWith(galleryUrls: updatedUrls);
      await ref.read(userServiceProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider(user.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Photo added to gallery.', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600)),
          backgroundColor: BoostDriveTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error uploading photo: $e', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingDocuments = false);
    }
  }

  Future<void> _deleteGalleryImage(String url) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final profile = await ref.read(userProfileProvider(user.id).future);
    if (profile == null) return;

    try {
      setState(() => _isUploadingDocuments = true);

      await ref.read(authServiceProvider).deleteGalleryImage(url);

      final updatedUrls = List<String>.from(_galleryUrls);
      final idx = updatedUrls.indexOf(url);
      if (idx != -1) updatedUrls[idx] = '';

      setState(() => _galleryUrls = updatedUrls);
      final updatedProfile = profile.copyWith(galleryUrls: updatedUrls);
      await ref.read(userServiceProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider(user.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Photo removed.', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600)),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error removing photo: $e', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingDocuments = false);
    }
  }

  Widget _buildTrustExperience() {
    final galleryImages = _galleryImageUrls;
    final canAddMore = galleryImages.length < _galleryMaxImages;
    final palette = _providerPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _providerSectionSubtitle('Business bio and portfolio build customer trust.'),
        const SizedBox(height: 16),
        _providerLabel('Business bio (About us)'),
        const SizedBox(height: 8),
        TextField(
          controller: _businessBioController,
          maxLines: 4,
          maxLength: 1300,
          readOnly: !_isProviderEditMode,
          enabled: _isProviderEditMode,
          style: _providerFieldStyle(),
          decoration: _providerInputDecoration(hint: 'Your history and passion'),
        ),
        const SizedBox(height: 16),
        _providerLabel('Team size (qualified technicians)'),
        const SizedBox(height: 8),
        TextField(controller: _teamSizeController, keyboardType: TextInputType.number, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: _providerFieldStyle(), decoration: _providerInputDecoration(hint: 'Number on-site')),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gallery (${galleryImages.length}/$_galleryMaxImages photos)',
              style: DashboardTypography.labelMd(palette),
            ),
            if (galleryImages.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Min 1 required',
                  style: DashboardTypography.labelMd(palette).copyWith(
                    fontSize: 10,
                    color: palette.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        _providerSectionSubtitle('Workshop, tow truck, or completed repairs. Upload 1–10 photos.'),
        const SizedBox(height: 12),
        if (_isUploadingDocuments)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Existing gallery thumbnails
              ...galleryImages.map((url) => _buildGalleryThumbnail(url)),
              // Add photo button (only if under max)
              if (canAddMore && _isProviderEditMode)
                GestureDetector(
                  onTap: _pickAndUploadGalleryImage,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: palette.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: palette.primary, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: DashboardTypography.labelMd(palette).copyWith(
                            fontSize: 10,
                            color: palette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildGalleryThumbnail(String url) {
    final palette = _providerPalette;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: palette.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.broken_image_outlined, color: palette.muted),
            ),
          ),
        ),
        if (_isProviderEditMode)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _deleteGalleryImage(url),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildDocumentsVault(UserProfile profile) {
    final palette = _providerPalette;
    final isTowingProvider =
        (profile.role.toLowerCase() == 'towing') || (_primaryServiceCategory.toLowerCase() == 'towing');
    final requiredSlots = <int>[0, 1, 2, 3, 5, 6];
    if (isTowingProvider) requiredSlots.add(4);
    var completed = 0;
    for (final i in requiredSlots) {
      if (i < _galleryUrls.length && _galleryUrls[i].trim().isNotEmpty) completed++;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _providerSectionSubtitle(
                'Upload official business documents for verification (BIPA, tax certificates, etc.). '
                'One file per document type — merge multi-page PDFs before uploading.',
              ),
            ),
            const SizedBox(width: 12),
            ProviderProfileUi.vaultProgressBadge(
              palette,
              completed: completed,
              total: requiredSlots.length,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: ProviderProfileUi.glassCardDecoration(palette),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legal and identity documents
              _documentStatusRow(
                'BIPA or CC1 business registration',
                _galleryUrls[0].trim().isNotEmpty ? 'Submitted – pending review' : 'Pending upload',
              ),
              _documentInputRow('BIPA or CC1 document', 0),
              const SizedBox(height: 12),
              _documentStatusRow(
                'Certified copy of owner ID',
                _galleryUrls[1].trim().isNotEmpty ? 'Submitted – pending review' : 'Pending upload',
              ),
              _documentInputRow('Certified owner ID document', 1),
              const SizedBox(height: 12),
              _documentStatusRow(
                'Municipal fitness certificate',
                _galleryUrls[2].trim().isNotEmpty ? 'Submitted – pending review' : 'Pending upload',
              ),
              _documentInputRow('Municipal fitness certificate document', 2),
              const SizedBox(height: 16),

              // Professional permits and compliance
              _documentStatusRow(
                'NTA trade certificate',
                _galleryUrls[3].trim().isNotEmpty ? 'Submitted – pending review' : 'Pending upload',
              ),
              _documentInputRow('NTA trade certificate document', 3),
              const SizedBox(height: 12),
              if (isTowingProvider) ...[
                _documentStatusRow(
                  'Road Carrier Permit (towing)',
                  _galleryUrls[4].trim().isNotEmpty ? 'Submitted – pending review' : 'Pending upload',
                ),
                _documentInputRow('Road Carrier Permit document', 4),
                const SizedBox(height: 12),
              ],
              _documentStatusRow(
                'NamRA tax certificate',
                _galleryUrls[5].trim().isNotEmpty ? 'Submitted – pending review' : 'Pending upload',
              ),
              _documentInputRow('NamRA tax certificate document', 5),
              const SizedBox(height: 12),
              _documentStatusRow(
                'Social Security good standing',
                _galleryUrls[6].trim().isNotEmpty ? 'Submitted – pending review' : 'Pending upload',
              ),
              _documentInputRow('Social Security good standing document', 6),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadProviderDocumentForSlot(int slotIndex) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profile = await ref.read(userProfileProvider(user.id).future);
    if (profile == null) return;

    // Use FilePicker so providers can upload PDFs, Word, Excel, PowerPoint, etc.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: true,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'csv',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
      ],
    );
    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    final bytes = pickedFile.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to read file contents. Please try again.',
              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Enforce a maximum file size of 10 MB per document.
    const maxBytes = 10 * 1024 * 1024; // 10 MB
    if (bytes.lengthInBytes > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File is too large. Please upload a document smaller than 10 MB.',
              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _isUploadingDocuments = true;
      });

      final publicUrl = await ref.read(authServiceProvider).uploadProviderDocument(bytes, pickedFile.name);

      final updatedUrls = List<String>.from(_galleryUrls);
      while (updatedUrls.length <= slotIndex) {
        updatedUrls.add('');
      }
      updatedUrls[slotIndex] = publicUrl;

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
              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
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
              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
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

  Future<void> _confirmAndRemoveProviderDocument(String url) async {
    final slotIndex = _galleryUrls.indexOf(url);
    if (slotIndex == -1) return;
    if (_isUploadingDocuments) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Remove document?',
            style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700),
          ),
          content: Text(
            'This document will be removed from your profile. You can upload it again later if needed.',
            style: TextStyle(fontFamily: 'Manrope', ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Remove',
                style: TextStyle(fontFamily: 'Manrope', color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profile = await ref.read(userProfileProvider(user.id).future);
    if (profile == null) return;

    try {
      setState(() {
        _isUploadingDocuments = true;
      });

      // Delete from storage via auth service helper.
      await ref.read(authServiceProvider).deleteProviderDocument(url);

      // Update profile gallery URLs.
      final updatedUrls = List<String>.from(_galleryUrls);
      if (slotIndex < updatedUrls.length) {
        updatedUrls[slotIndex] = '';
      }
      final updatedProfile = profile.copyWith(galleryUrls: updatedUrls);
      await ref.read(userServiceProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider(user.id));

      if (mounted) {
        setState(() {
          _galleryUrls = updatedUrls;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Document removed from your profile.',
              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green.shade600,
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
              'Error removing document: $e',
              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
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

  Widget _documentStatusRow(String name, String fallbackStatus) {
    final palette = _providerPalette;
    final backendStatus = _documentStatuses[name];
    final rejectionReason = _documentRejectionReasons[name];
    
    Color statusColor = palette.muted;
    String displayStatus = fallbackStatus;
    IconData? statusIcon;

    if (backendStatus == 'approved') {
      statusColor = palette.secondary;
      displayStatus = 'Approved';
      statusIcon = Icons.check_circle;
    } else if (backendStatus == 'rejected') {
      statusColor = palette.error;
      displayStatus = 'Rejected';
      statusIcon = Icons.cancel;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: DashboardTypography.labelLg(palette).copyWith(fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (statusIcon != null) ...[
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    displayStatus.toUpperCase(),
                    style: TextStyle(fontFamily: 'Manrope', 
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (backendStatus == 'rejected' && rejectionReason != null && rejectionReason.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'REASON: $rejectionReason',
                    style: TextStyle(fontFamily: 'Manrope', 
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _documentInputRow(String label, int slotIndex) {
    final palette = _providerPalette;
    String? url;
    if (slotIndex < _galleryUrls.length) {
      url = _galleryUrls[slotIndex];
    }
    final hasUrl = url != null && url.trim().isNotEmpty;
    final fileName = hasUrl ? url!.split('/').last : 'No document uploaded';

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: DashboardTypography.labelMd(palette)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: palette.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardTypography.bodySm(palette).copyWith(
                      color: hasUrl ? palette.onBackground : palette.muted,
                    ),
                  ),
                ),
              ),
              if (_isProviderEditMode) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isUploadingDocuments ? null : () => _pickAndUploadProviderDocumentForSlot(slotIndex),
                  style: ProviderProfileUi.primaryButtonStyle(palette).copyWith(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    minimumSize: WidgetStateProperty.all(const Size(0, 40)),
                  ),
                  child: Text(
                    'Upload',
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isUploadingDocuments || !hasUrl ? null : () => _confirmAndRemoveProviderDocument(url!),
                  child: Text(
                    'Remove',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasUrl ? palette.error : palette.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _providerLabel(String text) {
    final palette = DashboardPalette.of(context);
    return ProviderProfileUi.fieldLabel(palette, text);
  }

  InputDecoration _providerInputDecoration({String? hint}) {
    final palette = DashboardPalette.of(context);
    return ProviderProfileUi.inputDecoration(palette, hint: hint, readOnly: !_isProviderEditMode);
  }

  TextStyle _providerFieldStyle() {
    return ProviderProfileUi.fieldTextStyle(
      DashboardPalette.of(context),
      readOnly: !_isProviderEditMode,
    );
  }

  DashboardPalette get _providerPalette => DashboardPalette.of(context);

  Widget _providerSectionSubtitle(String text) {
    return ProviderProfileUi.sectionSubtitle(_providerPalette, text);
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
            Text('Shipping & Logistics', style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF000000))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFCCAA)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('BT', style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w800, color: BoostDriveTheme.primaryColor))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BaTLorriH Integration', style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF000000))),
                    const SizedBox(height: 2),
                    Text('Automated freight dispatch.', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000))),
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
          style: _providerFieldStyle(),
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
            Text('Payments & Payouts', style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF000000))),
          ],
        ),
        const SizedBox(height: 16),
        _providerInfoCard(
          icon: Icons.credit_card_outlined,
          title: 'Bank Account',
          value: 'Not set',
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF000000)),
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
                  border: Border.all(color: const Color(0xFFFFCCAA)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000))),
                    Text('—', style: TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF000000))),
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
        border: Border.all(color: const Color(0xFFFFCCAA)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF000000), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000))),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF000000))),
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
            Text('Business Registration', style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF000000))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFCCAA)),
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
                  Text('Verification Status', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000))),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        profile.verificationStatus == 'verified' ? Icons.check_circle : Icons.pending_outlined,
                        size: 18,
                        color: profile.verificationStatus == 'verified' ? Colors.green : const Color(0xFF000000),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profile.verificationStatus.isEmpty ? '—' : profile.verificationStatus.toUpperCase(),
                        style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF000000)),
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
        Text(key, style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000))),
        const Spacer(),
        Text(value, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF000000))),
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

        // widgets (switches, chips) are not reset on every rebuild.
        if (!_didInitFromProfile) {
          _loadDocumentStatuses(profile.uid);
          _nameController.text = profile.fullName;
          _emailController.text = profile.email;
          _phoneController.text = profile.phoneNumber;

          // Initialize business contact numbers
          final bizContactString = profile.businessContactNumber ?? '';
          final bizContacts = bizContactString.split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          
          // Clear and rebuild controllers from profile data
          for (var c in _businessPhoneControllers) { c.dispose(); }
          for (var f in _businessPhoneFocusNodes) { f.dispose(); }
          _businessPhoneControllers.clear();
          _businessPhoneFocusNodes.clear();

          if (bizContacts.isEmpty) {
            _businessPhoneControllers.add(TextEditingController());
            _businessPhoneFocusNodes.add(FocusNode());
          } else {
            for (final contact in bizContacts) {
              _businessPhoneControllers.add(TextEditingController(text: contact));
              _businessPhoneFocusNodes.add(FocusNode());
            }
          }
          
          _syncEmergencyPairsFromProfile(profile);
          _serviceAreaController.text = profile.serviceAreaDescription;
          _workingHoursController.text = profile.workingHours;
          _registeredBusinessNameController.text = profile.registeredBusinessName ?? '';
          _tradingNameController.text = profile.tradingName ?? '';
          _businessType = (profile.businessType?.isNotEmpty ?? false)
              ? profile.businessType!
              : 'cc';
          _registrationNumberController.text = profile.registrationNumber ?? '';
          _yearsInOperationController.text =
              profile.yearsInOperation != null ? profile.yearsInOperation.toString() : '';
          _primaryServiceCategory = (profile.primaryServiceCategory?.isNotEmpty ?? false)
              ? profile.primaryServiceCategory!
              : 'mechanic';
          _businessHours24_7 = profile.businessHours24_7 ?? false;
          _serviceRadiusKmController.text =
              profile.serviceRadiusKm != null ? profile.serviceRadiusKm.toString() : '';
          _workshopAddressController.text = profile.workshopAddress ?? '';
          _socialFacebookController.text = profile.socialFacebook ?? '';
          _socialInstagramController.text = profile.socialInstagram ?? '';
          _websiteUrlController.text = profile.websiteUrl ?? '';
          _selectedBrandExpertise = List.from(profile.brandExpertise);
          _selectedServiceTags = List.from(profile.serviceTags);
          _selectedTowingCapabilities = List.from(profile.towingCapabilities);

          // Re-populate dynamic "other" chips from profile data
          _dynamicBrandOptions.clear();
          for (final key in _selectedBrandExpertise) {
            if (key.startsWith('custom_brand_')) {
              final label = key.substring('custom_brand_'.length).replaceAll('_', ' ');
              final capitalized = label.isNotEmpty ? (label[0].toUpperCase() + label.substring(1)) : label;
              if (!_dynamicBrandOptions.any((e) => e.key == key)) {
                _dynamicBrandOptions.add(MapEntry(key, capitalized));
              }
            }
          }
          _dynamicServiceTagOptions.clear();
          for (final key in _selectedServiceTags) {
            if (key.startsWith('custom_service_')) {
              final label = key.substring('custom_service_'.length).replaceAll('_', ' ');
              final capitalized = label.isNotEmpty ? (label[0].toUpperCase() + label.substring(1)) : label;
              if (!_dynamicServiceTagOptions.any((e) => e.key == key)) {
                _dynamicServiceTagOptions.add(MapEntry(key, capitalized));
              }
            }
          }
          _bankAccountNumberController.text = profile.bankAccountNumber ?? '';
          _bankBranchController.text = profile.bankBranch ?? '';
          _bankNameController.text = profile.bankName ?? '';
          _standardLaborRateController.text =
              profile.standardLaborRate != null ? profile.standardLaborRate.toString() : '';
          _taxVatNumberController.text = profile.taxVatNumber ?? '';
          _businessBioController.text = profile.businessBio ?? '';
          // Restore 17-slot structure (0-6 docs, 7-16 gallery) strictly preserving indices.
          _galleryUrls = List.generate(17, (_) => '');
          for (int i = 0; i < profile.galleryUrls.length && i < 17; i++) {
            _galleryUrls[i] = profile.galleryUrls[i];
          }
          _teamSizeController.text =
              profile.teamSize != null ? profile.teamSize.toString() : '';
          final comm = profile.preferredCommunication ?? 'app_chat';
          _preferredCommunication = comm
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (_preferredCommunication.isEmpty) {
            _preferredCommunication = ['app_chat'];
          }
          _didInitFromProfile = true;
        }

        final isProvider = _isProviderRole(profile.role);
        final isWide = MediaQuery.of(context).size.width > 900;

        if (isProvider) {
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

        final dashPalette = DashboardPalette.of(context);
        return Scaffold(
          backgroundColor: dashPalette.background,
          appBar: AppBar(
            backgroundColor: dashPalette.navBar,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Profile Settings',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
            actions: [
              const DashboardThemeToggle(compact: true, onColoredHeader: true),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onPressed: () {},
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _handleSaveProfile,
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: DashboardPageContainer(
              maxWidth: 960,
              child: Column(
              children: [
                if (profile.role.toLowerCase() == 'admin') ...[
                  _buildAdminProfileView(profile, isWide),
                ] else ...[
                  const SizedBox(height: 16),
                  _buildProfileHeader(profile),
                  const SizedBox(height: 24),
                  Column(
                      children: [
                        _buildPersonalInformation(showInlineEdit: true),
                        if (!kIsWeb) ...[
                          const SizedBox(height: 32),
                          _buildSafetySection(),
                        ],
                        const SizedBox(height: 24),
                        _buildControlCenterSection(profile),
                        const SizedBox(height: 24),
                      ],
                    ),
                ],
                const SizedBox(height: 32),
                _buildAccountActions(),
                const SizedBox(height: 24),
                Text(
                  'BoostDrive Version 2.4.1 (1209)',
                  style: TextStyle(fontFamily: 'Manrope', 
                    color: const Color(0xFF000000),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(fontFamily: 'Manrope', fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF000000)),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: TextStyle(fontFamily: 'Manrope', color: const Color(0xFF000000)),
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
    final isProvider = _isProviderRole(profile.role);
    final palette = DashboardPalette.of(context);

    return DashboardCard(
      padding: const EdgeInsets.all(32),
      child: Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isUploading ? null : _showProfilePhotoOptions,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.primaryFixed, width: 4),
                    boxShadow: palette.cardShadowLow,
                  ),
                  child: _buildProfileAvatarContent(
                    profile: profile,
                    palette: palette,
                    radius: 55,
                    initialsFontSize: 32,
                    initialsName: profile.fullName,
                  ),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
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
                      decoration: BoxDecoration(
                        color: palette.primary,
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
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: palette.title,
          ),
        ),
        if (isProvider) ...[
          const SizedBox(height: 4),
          Text(
            '${profile.role.replaceAll('_', ' ').toUpperCase()} • Professional Partner',
            style: TextStyle(fontFamily: 'Manrope', 
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
                style: TextStyle(fontFamily: 'Manrope', color: const Color(0xFF000000), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                '(— reviews)',
                style: TextStyle(fontFamily: 'Manrope', color: const Color(0xFF000000), fontSize: 12),
              ),
            ],
          ),
        ] else
          Text(
            profile.isSeller
                ? 'BoostDrive Seller since ${profile.createdAt.year}'
                : 'BoostDrive Customer since ${profile.createdAt.year}',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: palette.body,
            ),
          ),
      ],
      ),
    );
  }

  String _providerChipLabel(
    List<MapEntry<String, String>> options,
    List<MapEntry<String, String>> dynamicOptions,
    String key,
  ) {
    for (final e in options) {
      if (e.key == key) return e.value;
    }
    for (final e in dynamicOptions) {
      if (e.key == key) return e.value;
    }
    return key.replaceAll('_', ' ');
  }

  Widget _buildBusinessInformation(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProviderProfileUi.subsectionHeading(_providerPalette, 'Core Business Identity'),
              _providerLabel('Registered business name'),
              const SizedBox(height: 8),
              TextField(
                controller: _registeredBusinessNameController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: _providerFieldStyle(),
                decoration: _providerInputDecoration(
                  hint: 'Official BIPA name e.g. Mubiana Mechanical Services CC',
                ),
              ),
              const SizedBox(height: 16),
              _providerLabel('Trading name (DBA)'),
              const SizedBox(height: 8),
              TextField(
                controller: _tradingNameController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: _providerFieldStyle(),
                decoration: _providerInputDecoration(
                  hint: 'Name customers see, e.g. The Turbo Doc',
                ),
              ),
              const SizedBox(height: 16),
              _providerLabel('Business contact number'),
              const SizedBox(height: 8),
              if (_businessPhoneControllers.isEmpty)
                const SizedBox()
              else
                ..._businessPhoneControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  final focusNode = _businessPhoneFocusNodes[index];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            readOnly: !_isProviderEditMode,
                            enabled: _isProviderEditMode,
                            keyboardType: TextInputType.phone,
                            style: _providerFieldStyle(),
                            decoration: _providerInputDecoration(
                              hint: 'Office WhatsApp or landline',
                            ),
                          ),
                        ),
                        if (_isProviderEditMode && _businessPhoneControllers.length > 1) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              if (_businessPhoneControllers.length > 1) {
                                setState(() {
                                  _businessPhoneControllers.removeAt(index).dispose();
                                  _businessPhoneFocusNodes.removeAt(index).dispose();
                                });
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            tooltip: 'Remove Number',
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              if (_isProviderEditMode)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addBusinessPhoneField,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('ADD NEW CONTACT NUMBER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: BoostDriveTheme.primaryColor,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _providerLabel('Business type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _businessType,
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 14,
                  color: const Color(0xFF000000),
                ),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(
                    value: 'cc',
                    child: Text(
                      'Close Corporation (CC)',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'pty_ltd',
                    child: Text(
                      'Private Company (Pty Ltd)',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'sole_prop',
                    child: Text(
                      'Sole Proprietor',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                  ),
                ],
                onChanged: _isProviderEditMode ? (val) {
                  if (val == null) return;
                  setState(() => _businessType = val);
                } : null,
                decoration: _providerInputDecoration(),
              ),
              const SizedBox(height: 16),
              _providerLabel('Registration number'),
              const SizedBox(height: 8),
              TextField(
                controller: _registrationNumberController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: _providerFieldStyle(),
                decoration: _providerInputDecoration(
                  hint: 'e.g. CC/2026/0123',
                ),
              ),
              const SizedBox(height: 24),
              ProviderProfileUi.subsectionHeading(_providerPalette, 'Operational Details'),
              _providerLabel('Years in operation'),
              const SizedBox(height: 8),
              TextField(
                controller: _yearsInOperationController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                keyboardType: TextInputType.number,
                style: _providerFieldStyle(),
                decoration: _providerInputDecoration(hint: 'e.g. 5'),
              ),
              const SizedBox(height: 16),
              _providerLabel('Primary service category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _primaryServiceCategory,
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 14,
                  color: const Color(0xFF000000),
                ),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(
                    value: 'mechanic',
                    child: Text(
                      'Mechanics',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'towing',
                    child: Text(
                      'Towing',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'electrical',
                    child: Text(
                      'Electrical',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'tires',
                    child: Text(
                      'Tires',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'parts',
                    child: Text(
                      'Parts Supply',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                  ),
                ],
                onChanged: _isProviderEditMode ? (val) {
                  if (val == null) return;
                  setState(() => _primaryServiceCategory = val);
                } : null,
                decoration: _providerInputDecoration(),
              ),
              _providerLabel('Team size (technicians/drivers)'),
              const SizedBox(height: 8),
              TextField(
                controller: _teamSizeController,
                keyboardType: TextInputType.number,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: _providerFieldStyle(),
                decoration: _providerInputDecoration(hint: 'Number of staff on your team'),
              ),
              const SizedBox(height: 24),
              ProviderProfileUi.subsectionHeading(_providerPalette, 'Physical & Digital Presence'),
              _providerLabel('Workshop physical address'),
              const SizedBox(height: 8),
              TextField(
                controller: _workshopAddressController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: _providerFieldStyle(),
                decoration: _providerInputDecoration(hint: 'Registered base of operations'),
              ),
              const SizedBox(height: 16),
              _providerLabel('Website & social links'),
              const SizedBox(height: 8),
              TextField(
                controller: _socialFacebookController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: _providerFieldStyle(),
                decoration: _providerInputDecoration(hint: 'Facebook business page URL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _socialInstagramController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: _providerFieldStyle(),
                decoration: _providerInputDecoration(hint: 'Instagram handle / URL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _websiteUrlController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: _providerFieldStyle(),
                decoration: _providerInputDecoration(hint: 'Website URL (optional)'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBusinessStat(String label, String value, {bool isLast = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: isLast ? null : const Border(right: BorderSide(color: Color(0xFFFFFFFF))),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontFamily: 'Manrope', 
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF000000),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontFamily: 'Manrope', 
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInformation({bool showInlineEdit = true, bool isProviderProfile = false}) {
    // In stepper edit mode (showInlineEdit = false) for providers, it should only be editable if _isProviderEditMode is true.
    // Otherwise, respect _isEditing for normal user settings.
    final isSectionEditable = isProviderProfile ? _isProviderEditMode : (showInlineEdit ? _isEditing : true);
    final palette = DashboardPalette.of(context);
    return DashboardCard(
      padding: const EdgeInsets.all(24),
      elevated: true,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isProviderProfile ? 'PRIMARY ACCOUNT DETAILS' : 'PERSONAL INFORMATION',
              style: DashboardTypography.sectionLabel(palette),
            ),
            if (showInlineEdit)
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
            color: palette.surfaceContainerLow,
            borderRadius: BorderRadius.circular(palette.radiusDefault),
            border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.person_outline,
                title: isProviderProfile ? 'Business Trading Name' : 'Full Name',
                value: _nameController.text,
                controller: _nameController,
                isEditable: isSectionEditable,
              ),
              const Divider(height: 1, indent: 64),
              _buildInfoTile(
                icon: Icons.email_outlined,
                title: 'Email Address',
                value: _emailController.text,
                controller: _emailController,
                isEditable: isSectionEditable,
              ),
              const Divider(height: 1, indent: 64),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.contact_phone_outlined, size: 16, color: const Color(0xFF000000)),
                    const SizedBox(width: 8),
                    Text(
                      'CONTACT DETAILS',
                      style: TextStyle(fontFamily: 'Manrope', 
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF000000),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 64),
              if (isProviderProfile) ...[
                // For providers, render multiple business contact numbers
                for (int i = 0; i < _businessPhoneControllers.length; i++) ...[
                  _buildInfoTile(
                    icon: Icons.phone_android_outlined,
                    title: 'Business Contact Number${_businessPhoneControllers.length > 1 ? " ${i + 1}" : ""}',
                    value: _businessPhoneControllers[i].text,
                    controller: _businessPhoneControllers[i],
                    isEditable: isSectionEditable,
                    isLast: i == _businessPhoneControllers.length - 1,
                    focusNode: _businessPhoneFocusNodes[i],
                    trailingAction: _isProviderEditMode ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_businessPhoneControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFD92D20), size: 20),
                            onPressed: () => _removeBusinessPhoneField(i),
                          ),
                        if (i == _businessPhoneControllers.length - 1)
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: BoostDriveTheme.primaryColor, size: 20),
                            onPressed: _addBusinessPhoneField,
                          ),
                      ],
                    ) : null,
                  ),
                  if (i < _businessPhoneControllers.length - 1)
                    const Divider(height: 1, indent: 64),
                ],
              ] else ...[
                // For customers, render single personal contact number
                _buildInfoTile(
                  icon: Icons.phone_android_outlined,
                  title: 'Personal Contact Number',
                  value: _phoneController.text,
                  controller: _phoneController,
                  isEditable: isSectionEditable,
                  isLast: true,
                ),
              ],
            ],
          ),
        ),
        if (showInlineEdit && _isEditing) ...[
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
                    side: const BorderSide(color: Color(0xFFFFCCAA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: const Color(0xFF000000)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSaveProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: BoostDriveTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Save Changes',
                        style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
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
    Widget? trailingAction,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
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
                  style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF000000),
                  ),
                ),
                if (isEditable)
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: TextStyle(fontFamily: 'Manrope', fontSize: 13, color: const Color(0xFF000000)),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  )
                else
                  Text(
                    value.isEmpty ? 'Not set' : value,
                    style: TextStyle(fontFamily: 'Manrope', 
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF000000),
                    ),
                  ),
              ],
            ),
          ),
          if (trailingAction != null) trailingAction,
          if (trailingAction == null && isEditable)
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFFFCCAA)),
        ],
      ),
    );
  }

  Widget _buildSafetySection() {
    final palette = _providerPalette;
    final contacts = _emergencyContactsFromPairs();
    return ProviderProfileUi.safetyPanel(
      palette: palette,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: palette.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SOS',
                  style: DashboardTypography.labelLg(palette).copyWith(
                    color: palette.error,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency contacts', style: DashboardTypography.labelLg(palette)),
                    const SizedBox(height: 2),
                    Text(
                      'Notifications can be sent to these contacts in case of a breakdown or collision.',
                      style: DashboardTypography.bodySm(palette),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: palette.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _showEmergencyContactsEditor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: contacts.isEmpty
                                ? Text(
                                    'No contacts saved. Tap Manage to add people we can reference for SOS.',
                                    style: DashboardTypography.bodySm(palette),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      for (var i = 0; i < contacts.length && i < 4; i++) ...[
                                        if (i > 0) const SizedBox(height: 10),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${i + 1}. ',
                                              style: DashboardTypography.labelMd(palette).copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    contacts[i].name.isEmpty ? 'Unnamed' : contacts[i].name,
                                                    style: DashboardTypography.labelLg(palette).copyWith(fontSize: 14),
                                                  ),
                                                  Text(
                                                    contacts[i].phone.isEmpty ? 'No phone' : contacts[i].phone,
                                                    style: DashboardTypography.bodySm(palette),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (contacts.length > 4)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            '+ ${contacts.length - 4} more',
                                            style: DashboardTypography.bodySm(palette).copyWith(color: palette.muted),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Manage',
                            style: DashboardTypography.labelLg(palette).copyWith(color: palette.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAdminProfileView(UserProfile profile, bool isWide) {
    return Column(
      children: [
        _buildAdminBanner(profile),
        const SizedBox(height: 100), // Increased top margin to prevent crowding header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pair Personal Identity and Account Security side-by-side with equal height
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildAdminPersonalInfo(profile)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildAdminSecurity(profile)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildControlCenterSection(profile),
              _buildAdminFooter(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEmergencyContactsEditor() async {
    final savedFullJson = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _EmergencyContactsSheet(
        initialContacts: _emergencyContactsFromPairs(),
        onSave: (contacts) async {
          final user = ref.read(currentUserProvider);
          if (user == null) throw StateError('Not logged in');
          final fresh = await ref.read(userProfileProvider(user.id).future);
          if (fresh == null) throw StateError('Profile not found');
          final fullJson = await ref.read(userServiceProvider).updateProfile(
            fresh.copyWith(emergencyContacts: contacts),
          );
          if (!mounted) return fullJson;
          setState(() => _replaceEmergencyContactPairsFrom(contacts));
          ref.invalidate(userProfileProvider(user.id));
          return fullJson;
        },
      ),
    );
    if (!mounted || savedFullJson == null) return;

    if (savedFullJson) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => AlertDialog(
          title: Text(
            'Emergency contacts saved',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: BoostDriveTheme.primaryColor,
            ),
          ),
          content: const Text(
            'Your emergency contacts have been saved. We\'ll use them when you trigger SOS.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              height: 1.35,
              color: Color(0xFF000000),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: FilledButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
              child: const Text(
                'OK',
                style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => AlertDialog(
          title: Text(
            'Partially saved',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: BoostDriveTheme.primaryColor,
            ),
          ),
          content: const Text(
            'Your profile was updated, but the database is missing the emergency_contacts column, '
            'so only the first contact was stored. Ask your project admin to run the SQL migration '
            'supabase/migrations/20260410210000_profiles_emergency_contacts_jsonb.sql in the Supabase SQL Editor, '
            'then try saving again for full multi-contact support.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              height: 1.35,
              color: Color(0xFF000000),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: FilledButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
              child: const Text(
                'OK',
                style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Control Center: emergency contacts (non-shops), shop-only staff/payouts.
  Widget _buildControlCenterSection(UserProfile profile) {
    final palette = _providerPalette;
    return ProviderProfileUi.controlCenterShell(
      palette: palette,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            onSurface: palette.onBackground,
            onSurfaceVariant: palette.muted,
          ),
          listTileTheme: ListTileThemeData(
            iconColor: palette.primary,
            textColor: palette.onBackground,
            titleTextStyle: DashboardTypography.labelLg(palette),
            subtitleTextStyle: DashboardTypography.bodySm(palette),
          ),
          expansionTileTheme: ExpansionTileThemeData(
            iconColor: palette.primary,
            collapsedIconColor: palette.primary,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Text(
            'Hub & operations',
            style: DashboardTypography.labelLg(palette).copyWith(color: palette.primary),
          ),
          subtitle: Text(
            _isRegisteredServiceShop(profile) ? 'Staff, payouts.' : 'Emergency contacts.',
            style: DashboardTypography.bodySm(palette),
          ),
          children: [
            if (!_isRegisteredServiceShop(profile))
              ListTile(
                leading: Icon(Icons.contact_phone_outlined, color: palette.primary),
                title: Text('Emergency contacts', style: DashboardTypography.labelLg(palette)),
                subtitle: Text(_emergencyContactsControlSubtitle(), style: DashboardTypography.bodySm(palette)),
                onTap: _showEmergencyContactsEditor,
              ),
            if (_isRegisteredServiceShop(profile)) ...[
              ListTile(
                leading: Icon(Icons.groups_outlined, color: palette.primary),
                title: Text('Staff & roles', style: DashboardTypography.labelLg(palette)),
                subtitle: Text(
                  'Delegate dispatch, finance, and SOS oversight (org rollout).',
                  style: DashboardTypography.bodySm(palette),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Multi-user staff workspaces will link from here soon.')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.payments_outlined, color: palette.primary),
                title: Text('Payouts', style: DashboardTypography.labelLg(palette)),
                subtitle: Text(
                  'Bank and VAT details live under Financial & Payout in your provider profile.',
                  style: DashboardTypography.bodySm(palette),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payout configuration stays in your business profile for now.')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPersonalInfo(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PERSONAL INFORMATION',
              style: TextStyle(fontFamily: 'Manrope', 
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF000000),
                letterSpacing: 0.5,
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 20, color: BoostDriveTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24), // Consistent Padding 24
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFFFFF)),
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
                title: 'Official Email',
                value: _emailController.text,
                controller: _emailController,
                isEditable: _isEditing,
              ),
              const Divider(height: 1, indent: 64),
              _buildInfoTile(
                icon: Icons.phone_outlined,
                title: 'Work Phone',
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
          _buildSaveAdminAction(),
        ],
      ],
    );
  }

  Widget _buildSaveAdminAction() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() => _isEditing = false);
              ref.invalidate(userProfileProvider(ref.read(currentUserProvider)!.id));
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: const Color(0xFF000000))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSaveProfile,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: BoostDriveTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Save Changes', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSecurity(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCOUNT SECURITY',
          style: TextStyle(fontFamily: 'Manrope', 
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF000000),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24), // Consistent Padding 24
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSecurityAction(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: _showChangePasswordDialog,
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.laptop_mac, color: BoostDriveTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ASUS Laptop - Windhoek, Namibia - Active Now',
                        style: TextStyle(fontFamily: 'Manrope', color: Colors.white70, fontSize: 12),
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

  Widget _buildSecurityAction({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(fontFamily: 'Manrope', color: Colors.white, fontWeight: FontWeight.w700)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
        ],
      ),
    );
  }



  Widget _buildAdminFooter() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: Icon(Icons.logout, color: Colors.white),
            label: Text('LOG OUT', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.0)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'BoostDrive Admin v1.0.4',
          style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF000000)),
        ),
      ],
    );
  }

  Widget _buildAdminInfoTile({
    required IconData icon,
    required String title,
    required String value,
    TextEditingController? controller,
    bool isEditable = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Icon with centered vertical alignment and fixed 24px width
          SizedBox(
            width: 24,
            child: Icon(icon, color: const Color(0xFF000000), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF000000))),
                if (isEditable)
                  TextField(
                    controller: controller,
                    style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF000000)),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  )
                else
                  Text(value, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF000000))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet: edit multiple SOS emergency contacts; [onSave] returns whether `emergency_contacts` was persisted.
class _EmergencyContactsSheet extends StatefulWidget {
  const _EmergencyContactsSheet({
    required this.initialContacts,
    required this.onSave,
  });

  final List<EmergencyContact> initialContacts;
  final Future<bool> Function(List<EmergencyContact> contacts) onSave;

  @override
  State<_EmergencyContactsSheet> createState() => _EmergencyContactsSheetState();
}

class _EmergencyContactsSheetState extends State<_EmergencyContactsSheet> {
  late final List<_EmergencyContactFieldPair> _rows;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialContacts;
    if (initial.isEmpty) {
      _rows = [_EmergencyContactFieldPair()];
    } else {
      _rows = initial
          .map((c) => _EmergencyContactFieldPair(nameText: c.name, phoneText: c.phone))
          .toList();
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  List<EmergencyContact> _parsedContacts() {
    return _rows
        .map((p) => EmergencyContact(name: p.name.text.trim(), phone: p.phone.text.trim()))
        .where((c) => c.name.isNotEmpty || c.phone.isNotEmpty)
        .toList();
  }

  InputDecoration _outlineFieldDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF424242)),
      floatingLabelStyle: TextStyle(
        color: BoostDriveTheme.primaryColor,
        fontWeight: FontWeight.w600,
      ),
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: BoostDriveTheme.primaryColor.withValues(alpha: 0.45),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: BoostDriveTheme.primaryColor, width: 2),
      ),
    );
  }

  Future<void> _onSavePressed() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final fullJson = await widget.onSave(_parsedContacts());
      if (mounted) Navigator.of(context).pop(fullJson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.78;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 24,
      ),
      child: SizedBox(
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Emergency contacts',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: BoostDriveTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add people we can reference when you use SOS — keep this updated so help reaches the right people.',
              style: TextStyle(fontFamily: 'Manrope', fontSize: 13, color: Color(0xFF000000), height: 1.35),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _rows.length + 1,
                itemBuilder: (context, index) {
                  if (index == _rows.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _rows.add(_EmergencyContactFieldPair())),
                        icon: Icon(Icons.person_add_alt_1_outlined, color: BoostDriveTheme.primaryColor.withValues(alpha: _saving ? 0.4 : 1)),
                        label: Text(
                          'Add another contact',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w700,
                            color: BoostDriveTheme.primaryColor.withValues(alpha: _saving ? 0.4 : 1),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.55)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Contact ${index + 1}',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF000000),
                              ),
                            ),
                            const Spacer(),
                            if (_rows.length > 1)
                              IconButton(
                                tooltip: 'Remove contact',
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFD92D20)),
                                onPressed: _saving
                                    ? null
                                    : () {
                                        setState(() {
                                          final r = _rows.removeAt(index);
                                          r.dispose();
                                        });
                                      },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _rows[index].name,
                          enabled: !_saving,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                          cursorColor: const Color(0xFF000000),
                          decoration: _outlineFieldDecoration('Contact name'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _rows[index].phone,
                          enabled: !_saving,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                          cursorColor: const Color(0xFF000000),
                          decoration: _outlineFieldDecoration('Phone number'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _onSavePressed,
              style: FilledButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
