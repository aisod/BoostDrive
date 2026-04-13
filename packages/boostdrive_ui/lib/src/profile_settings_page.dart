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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _handleLogout(),
            icon: const Icon(Icons.logout, color: Colors.black, size: 20),
            label: const Text('Log Out', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, color: Colors.black)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFCCAA)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: () => _handleDeleteAccount(),
            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
            label: const Text('Delete Account', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, color: Colors.red)),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
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
    debugPrint('DEBUG: _showProfilePhotoOptions called');
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
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
                    color: const Color(0xFFFFCCAA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Profile Photo',
                  style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF000000),
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
                    ? Colors.red.withValues(alpha: 0.1) 
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF000000),
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
                    style: TextStyle(fontFamily: 'Manrope', 
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDestructive ? Colors.red : const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontFamily: 'Manrope', 
                      fontSize: 13,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF000000),
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
    const bg = Color(0xFFFFFFFF);
    final isEditOnlyPage = widget.initialProviderEditMode;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (isEditOnlyPage) {
              Navigator.pop(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          isEditOnlyPage ? 'Edit Profile Settings' : 'Provider Profile',
          style: TextStyle(fontFamily: 'Manrope', color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (isEditOnlyPage)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Exit Edit Mode',
                style: TextStyle(color: Colors.white),
              ),
            )
            else
            TextButton(
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileSettingsPage(initialProviderEditMode: true),
                  ),
                );
                if (mounted) {
                  _didInitFromProfile = false;
                  ref.invalidate(userProfileProvider(profile.uid));
                  setState(() {});
                }
              },
              child: const Text(
                'Edit Profile',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
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
                        profile.displayName,
                        style: TextStyle(fontFamily: 'Manrope', fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF000000)),
                      ),
                      if (_isProviderApproved(profile.verificationStatus)) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified, color: BoostDriveTheme.primaryColor, size: 24),
                      ],
                    ],
                  ),
                  if (_isProviderApproved(profile.verificationStatus)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'Verified ${_getCategoryLabel(profile)}',
                        style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BoostDriveTheme.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          _buildBusinessInformation(profile),
          if (!kIsWeb) ...[
            const SizedBox(height: 32),
            _buildSafetySection(),
          ],
          const SizedBox(height: 32),
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
          if (!kIsWeb) ...[
            const SizedBox(height: 32),
            _buildDocumentsVault(profile),
        ],
        const SizedBox(height: 32),
          _buildControlCenterSection(profile),
        const SizedBox(height: 40),
          _buildAccountActions(),
          const SizedBox(height: 24),
          Text(
            'BoostDrive Version 2.4.1 (1209)',
            style: TextStyle(fontFamily: 'Manrope', color: const Color(0xFF000000), fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProviderStepperContent(UserProfile profile, bool isWide) {
    const steps = [
      'Business Profile',
      'Legal Docs & Certs',
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BoostDriveStepper(
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
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: BoostDriveTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: Colors.white),
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
    switch (_providerCurrentStep) {
      case 0: // Business Profile + Contact Info + Specializations + Location & Payouts
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBusinessInformation(profile),
            const SizedBox(height: 32),
            const SizedBox(height: 32),
            _buildTrustExperience(),
            const SizedBox(height: 32),
            _buildServiceSpecializations(profile),
            const SizedBox(height: 32),
            _buildOperationalBusinessDetails(profile),
            const SizedBox(height: 24),
            _buildProviderServiceAreaAndHours(profile),
            const SizedBox(height: 24),
            _buildFinancialPayout(),
          ],
        );
      case 1: // Legal Docs & Certs (BIPA/ID + NTA/RA)
        return _buildDocumentsVault(profile);
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
            child: MouseRegion(
              cursor: _isProviderEditMode ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: (_isUploading || !_isProviderEditMode) ? null : () {
                  _showProfilePhotoOptions();
                },
                child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    backgroundImage: _optimisticImage != null
                        ? MemoryImage(_optimisticImage!) as ImageProvider
                        : (profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null),
                    child: profile.profileImg.isEmpty && _optimisticImage == null
                        ? Text(
                            getInitials(profile.displayName),
                             style: TextStyle(fontFamily: 'Manrope', 
                               fontSize: 28,
                               fontWeight: FontWeight.w800,
                               color: BoostDriveTheme.primaryColor,
                             ),
                           )
                        : null,
                  ),
                  if (_isProviderEditMode)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: BoostDriveTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
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
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: BoostDriveTheme.primaryColor, size: 22),
            const SizedBox(width: 10),
            Text('Service area & working hours', style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF000000))),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Shown to customers on Find a Provider. E.g. "Within 50 km of Windhoek" and "Mon–Fri 8am–6pm".',
          style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000)),
        ),
        const SizedBox(height: 16),
        _providerLabel('How far you\'re located / service area'),
        const SizedBox(height: 8),
        TextField(
          controller: _serviceAreaController,
          readOnly: !_isProviderEditMode,
          enabled: _isProviderEditMode,
          style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
          decoration: _providerInputDecoration(hint: 'e.g. Within 50 km of Windhoek, City centre'),
        ),
        const SizedBox(height: 16),
        _providerLabel('Working hours'),
        const SizedBox(height: 8),
        TextField(
          controller: _workingHoursController,
          readOnly: !_isProviderEditMode,
          enabled: _isProviderEditMode,
          style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
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
            Text('Services you provide', style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF000000))),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select at least 1 service. You can select multiple.',
          style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000)),
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
                if (!_isProviderEditMode) return;
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
                  color: selected ? BoostDriveTheme.primaryColor.withValues(alpha: 0.15) : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? BoostDriveTheme.primaryColor : const Color(0xFFFFCCAA),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 20,
                      color: selected ? BoostDriveTheme.primaryColor : const Color(0xFF000000),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(fontFamily: 'Manrope', 
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? BoostDriveTheme.primaryColor : const Color(0xFF000000),
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
        Text(title, style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF000000))),
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
          onTap: () async {
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? BoostDriveTheme.primaryColor.withValues(alpha: 0.15) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? BoostDriveTheme.primaryColor : const Color(0xFFFFCCAA),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: isSelected ? BoostDriveTheme.primaryColor : const Color(0xFF000000)),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? BoostDriveTheme.primaryColor : const Color(0xFF000000))),
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
        Text('Powers "Open Now" filter and SOS matching.', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000))),
        const SizedBox(height: 16),
        if (isTowingOrSos) ...[
          Row(
            children: [
              Expanded(child: Text('Open 24/7', style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF000000)))),
              Switch(
                value: _businessHours24_7,
                onChanged: _isProviderEditMode ? (v) => setState(() => _businessHours24_7 = v) : null,
                activeTrackColor: BoostDriveTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('When on, your profile shows "24/7" for Open Now. When off, use Working hours above.', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000))),
          const SizedBox(height: 16),
        ],
        _providerLabel('Service radius (km)'),
        const SizedBox(height: 8),
        TextField(
          controller: _serviceRadiusKmController,
          keyboardType: TextInputType.number,
          readOnly: !_isProviderEditMode,
          enabled: _isProviderEditMode,
          style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
          decoration: _providerInputDecoration(hint: 'Max distance you travel for jobs'),
        ),
        const SizedBox(height: 16),
        _providerLabel('Workshop address'),
        const SizedBox(height: 8),
        TextField(controller: _workshopAddressController, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)), decoration: _providerInputDecoration(hint: 'Physical location for drop-offs')),
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
        _buildSectionTitle('Service Specializations', Icons.build_circle_outlined),
        const SizedBox(height: 12),
        Text('Used for search filters and matching.', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000))),
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
        _buildSectionTitle('Financial & Payout', Icons.account_balance_wallet_outlined),
        const SizedBox(height: 12),
        Text('For automated payouts and customer price estimates.', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000))),
        const SizedBox(height: 16),
        _providerLabel('Bank name'),
        const SizedBox(height: 8),
        TextField(controller: _bankNameController, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)), decoration: _providerInputDecoration(hint: 'e.g. Bank Windhoek, FNB')),
        const SizedBox(height: 12),
        _providerLabel('Branch'),
        const SizedBox(height: 8),
        TextField(controller: _bankBranchController, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)), decoration: _providerInputDecoration(hint: 'Branch name or code')),
        const SizedBox(height: 12),
        _providerLabel('Account number'),
        const SizedBox(height: 8),
        TextField(controller: _bankAccountNumberController, keyboardType: TextInputType.number, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)), decoration: _providerInputDecoration(hint: 'Bank account number')),
        const SizedBox(height: 12),
        _providerLabel(r'Estimated hourly rate (N$)'),
        const SizedBox(height: 8),
        TextField(controller: _standardLaborRateController, keyboardType: TextInputType.number, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)), decoration: _providerInputDecoration(hint: 'Standard labor rate for quotes')),
        const SizedBox(height: 12),
        _providerLabel('Tax / VAT number'),
        const SizedBox(height: 8),
        TextField(controller: _taxVatNumberController, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)), decoration: _providerInputDecoration(hint: 'For legal invoices')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Trust & Experience', Icons.verified_user_outlined),
        const SizedBox(height: 12),
        Text('Business bio and portfolio build customer trust.', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000))),
        const SizedBox(height: 16),
        _providerLabel('Business bio (About us)'),
        const SizedBox(height: 8),
        TextField(
          controller: _businessBioController,
          maxLines: 4,
          maxLength: 1300,
          readOnly: !_isProviderEditMode,
          enabled: _isProviderEditMode,
          style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
          decoration: _providerInputDecoration(hint: 'Your history and passion'),
        ),
        const SizedBox(height: 16),
        _providerLabel('Team size (qualified technicians)'),
        const SizedBox(height: 8),
        TextField(controller: _teamSizeController, keyboardType: TextInputType.number, readOnly: !_isProviderEditMode, enabled: _isProviderEditMode, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)), decoration: _providerInputDecoration(hint: 'Number on-site')),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gallery (${galleryImages.length}/$_galleryMaxImages photos)',
              style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF000000)),
            ),
            if (galleryImages.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text('Min 1 required', style: TextStyle(fontFamily: 'Manrope', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Workshop, tow truck, or completed repairs. Upload 1–10 photos.',
          style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: const Color(0xFF000000)),
        ),
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
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCCAA), style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: BoostDriveTheme.primaryColor, size: 28),
                        const SizedBox(height: 4),
                        Text('Add Photo', style: TextStyle(fontFamily: 'Manrope', fontSize: 10, fontWeight: FontWeight.w600, color: BoostDriveTheme.primaryColor)),
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
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.broken_image_outlined, color: Color(0xFF000000)),
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
    final hasDocs = _galleryUrls.any((url) => url.trim().isNotEmpty);
    final isTowingProvider =
        (profile.role.toLowerCase() == 'towing') || (_primaryServiceCategory.toLowerCase() == 'towing');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Documents Vault', Icons.folder_outlined),
        const SizedBox(height: 10),
        Text(
          'Upload your official business documents for verification, for example BIPA and tax certificates. '
          'Only upload one file per document type. If you have several versions or pages of the same document, '
          'please merge them into a single file and upload that one file only for that row.',
          style: TextStyle(fontFamily: 'Manrope', fontSize: 16, color: const Color(0xFF000000)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFCCAA))),
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
    final backendStatus = _documentStatuses[name];
    final rejectionReason = _documentRejectionReasons[name];
    
    Color statusColor = const Color(0xFF000000);
    String displayStatus = fallbackStatus;
    IconData? statusIcon;

    if (backendStatus == 'approved') {
      statusColor = Colors.green;
      displayStatus = 'Approved';
      statusIcon = Icons.check_circle;
    } else if (backendStatus == 'rejected') {
      statusColor = Colors.red;
      displayStatus = 'Rejected';
      statusIcon = Icons.cancel;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF000000))),
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
          Text(
            label,
            style: TextStyle(fontFamily: 'Manrope', 
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCCAA)),
                  ),
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Manrope', 
                      fontSize: 13,
                      color: hasUrl ? const Color(0xFF000000) : const Color(0xFF000000),
                    ),
                  ),
                ),
              ),
              if (_isProviderEditMode) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isUploadingDocuments ? null : () => _pickAndUploadProviderDocumentForSlot(slotIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoostDriveTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    minimumSize: const Size(0, 40),
                  ),
                  child: Text(
                    'Upload',
                    style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isUploadingDocuments || !hasUrl ? null : () => _confirmAndRemoveProviderDocument(url!),
                  child: Text(
                    'Remove',
                    style: TextStyle(fontFamily: 'Manrope', 
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasUrl ? const Color(0xFFB42318) : const Color(0xFF000000),
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
    return Text(text, style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF000000)));
  }

  InputDecoration _providerInputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint ?? '',
      hintStyle: TextStyle(fontFamily: 'Manrope', color: const Color(0xFF000000)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFFCCAA))),
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
          style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
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

        return Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          appBar: AppBar(
            backgroundColor: BoostDriveTheme.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Profile Settings',
              style: TextStyle(fontFamily: 'Manrope', 
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
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                if (profile.role.toLowerCase() == 'admin') ...[
                  _buildAdminProfileView(profile, isWide),
                ] else ...[
                  const SizedBox(height: 32),
                  _buildProfileHeader(profile),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
                    child: Column(
                      children: [
                        _buildPersonalInformation(showInlineEdit: true),
                        if (!kIsWeb) ...[
                          const SizedBox(height: 32),
                          _buildSafetySection(),
                        ],
                        const SizedBox(height: 32),
                        _buildControlCenterSection(profile),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
                  child: _buildAccountActions(),
                ),
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
    
    return Column(
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
                    backgroundColor: const Color(0xFFFFCCAA),
                    backgroundImage: _optimisticImage != null
                        ? MemoryImage(_optimisticImage!) as ImageProvider
                        : (!_isOptimisticDelete && profile.profileImg.isNotEmpty)
                            ? NetworkImage(profile.profileImg)
                            : null,
                    child: (_optimisticImage == null && (_isOptimisticDelete || profile.profileImg.isEmpty))
                        ? Text(
                            getInitials(profile.fullName),
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
          style: TextStyle(fontFamily: 'Manrope', 
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF000000),
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
            style: TextStyle(fontFamily: 'Manrope', 
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF000000),
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
          style: TextStyle(fontFamily: 'Manrope', 
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF000000),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Core Business Identity',
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),
              _providerLabel('Registered business name'),
              const SizedBox(height: 8),
              TextField(
                controller: _registeredBusinessNameController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
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
                style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
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
                            style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
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
                style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
                decoration: _providerInputDecoration(
                  hint: 'e.g. CC/2026/0123',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Operational Details',
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),
              _providerLabel('Years in operation'),
              const SizedBox(height: 8),
              TextField(
                controller: _yearsInOperationController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                keyboardType: TextInputType.number,
                style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
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
                style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
                decoration: _providerInputDecoration(hint: 'Number of staff on your team'),
              ),
              const SizedBox(height: 24),
              Text(
                'Physical & Digital Presence',
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),
              _providerLabel('Workshop physical address'),
              const SizedBox(height: 8),
              TextField(
                controller: _workshopAddressController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
                decoration: _providerInputDecoration(hint: 'Registered base of operations'),
              ),
              const SizedBox(height: 16),
              _providerLabel('Website & social links'),
              const SizedBox(height: 8),
              TextField(
                controller: _socialFacebookController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
                decoration: _providerInputDecoration(hint: 'Facebook business page URL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _socialInstagramController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
                decoration: _providerInputDecoration(hint: 'Instagram handle / URL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _websiteUrlController,
                readOnly: !_isProviderEditMode,
                enabled: _isProviderEditMode,
                style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: const Color(0xFF000000)),
                decoration: _providerInputDecoration(hint: 'Website URL (optional)'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isProviderProfile ? 'PRIMARY ACCOUNT DETAILS' : 'PERSONAL INFORMATION',
              style: TextStyle(fontFamily: 'Manrope', 
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF000000),
                letterSpacing: 0.5,
              ),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFFFFF)),
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
    final contacts = _emergencyContactsFromPairs();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAFETY & SOS',
            style: TextStyle(fontFamily: 'Manrope', 
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
                        style: TextStyle(fontFamily: 'Manrope', 
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
                            'Emergency contacts',
                            style: TextStyle(fontFamily: 'Manrope', 
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF000000),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Notifications can be sent to these contacts in case of a breakdown or collision.',
                            style: TextStyle(fontFamily: 'Manrope', 
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF000000),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.white,
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
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF000000),
                                    ),
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
                                              style: TextStyle(
                                                fontFamily: 'Manrope',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF000000),
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    contacts[i].name.isEmpty ? 'Unnamed' : contacts[i].name,
                                                    style: TextStyle(
                                                      fontFamily: 'Manrope',
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: const Color(0xFF000000),
                                                    ),
                                                  ),
                                                  Text(
                                                    contacts[i].phone.isEmpty ? 'No phone' : contacts[i].phone,
                                                    style: TextStyle(
                                                      fontFamily: 'Manrope',
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: const Color(0xFF000000),
                                                    ),
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
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF666666),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Manage',
                            style: TextStyle(fontFamily: 'Manrope', 
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFD92D20),
                            ),
                          ),
                        ],
                      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTROL CENTER',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF000000),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              colorScheme: Theme.of(context).colorScheme.copyWith(
                onSurface: const Color(0xFF000000),
                onSurfaceVariant: const Color(0xFF000000),
              ),
              listTileTheme: ListTileThemeData(
                iconColor: const Color(0xFF000000),
                textColor: const Color(0xFF000000),
                titleTextStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
                subtitleTextStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  height: 1.35,
                  color: Color(0xFF000000),
                ),
              ),
              expansionTileTheme: ExpansionTileThemeData(
                iconColor: BoostDriveTheme.primaryColor,
                collapsedIconColor: BoostDriveTheme.primaryColor,
              ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                'Hub & operations',
                style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: BoostDriveTheme.primaryColor),
              ),
              subtitle: Text(
                _isRegisteredServiceShop(profile)
                    ? 'Staff, payouts.'
                    : 'Emergency contacts.',
                style: const TextStyle(fontFamily: 'Manrope', fontSize: 12, color: Color(0xFF000000)),
              ),
              children: [
                if (!_isRegisteredServiceShop(profile))
                  ListTile(
                    leading: const Icon(Icons.contact_phone_outlined, color: Color(0xFF000000)),
                    title: const Text('Emergency contacts', style: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _emergencyContactsControlSubtitle(),
                      style: const TextStyle(color: Color(0xFF000000)),
                    ),
                    onTap: _showEmergencyContactsEditor,
                  ),
                if (_isRegisteredServiceShop(profile)) ...[
                  ListTile(
                    leading: const Icon(Icons.groups_outlined, color: Color(0xFF000000)),
                    title: const Text('Staff & roles', style: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Delegate dispatch, finance, and SOS oversight (org rollout).',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Multi-user staff workspaces will link from here soon.')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.payments_outlined, color: Color(0xFF000000)),
                    title: const Text('Payouts', style: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Bank and VAT details live under Financial & Payout in your provider profile.',
                      style: TextStyle(color: Color(0xFF000000)),
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
        ),
      ],
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
