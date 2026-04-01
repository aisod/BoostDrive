import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseAuthProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

class AuthService {
  final SupabaseClient _supabase;
  AuthService(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sends OTP to the phone number
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String code) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      String formatted = phoneNumber.trim();
      // Ensure phone number starts with +
      if (!formatted.startsWith('+')) {
        formatted = formatted.startsWith('0') ? '+264${formatted.substring(1)}' : '+264$formatted';
      }

      await _supabase.auth.signInWithOtp(
        phone: formatted,
      );
      
      // Supabase signals success if no error is thrown
      onCodeSent(formatted); 
    } catch (e) {
      print("DEBUG: Supabase Auth Error: $e");
      onError(e.toString());
    }
  }

  /// Sends OTP to the email address
  Future<void> signInWithEmail({
    required String email,
    required Function(String email) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: true,
      );
      onCodeSent(email.trim());
    } catch (e) {
      print("DEBUG: Supabase Email Auth Error: $e");
      onError(e.toString());
    }
  }

  /// Sends a password reset OTP (using signInWithOtp as proxy for recovery)
  Future<void> sendPasswordResetOtp(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: false, // Don't create new users for password reset
      );
    } catch (e) {
      print("DEBUG: Password Reset OTP Error: $e");
      // Security: Don't reveal if user exists or not, but for now rethrow for debugging
      rethrow;
    }
  }

  /// Updates the user's password (requires authenticated session)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      print("DEBUG: Update Password Error: $e");
      rethrow;
    }
  }

  /// Verifies the current user's password
  Future<bool> verifyPassword(String password) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      if (user.email != null) {
        await _supabase.auth.signInWithPassword(
          email: user.email!,
          password: password,
        );
        return true;
      } else if (user.phone != null) {
        await _supabase.auth.signInWithPassword(
          phone: user.phone!,
          password: password,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }


  Future<bool> signInWithGoogle() async {
    try {
      final res = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      return res;
    } catch (e) {
      print("DEBUG: Google Sign In Error: $e");
      rethrow;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      final res = await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      return res;
    } catch (e) {
      print("DEBUG: Apple Sign In Error: $e");
      rethrow;
    }
  }

  /// New: Sign in with Email and Password
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        // Check if the user's profile exists — if not, treat as deleted account
        final profileExists = await _supabase
            .from('profiles')
            .select('id')
            .eq('id', response.user!.id)
            .maybeSingle();

        if (profileExists == null) {
          // Account exists in Auth but not in profiles — sign out and reject
          await _supabase.auth.signOut();
          throw 'This account no longer exists. Please create a new account.';
        }

        await _handlePostAuthSync(response.user!);
      }
      return response;
    } catch (e) {
      print("DEBUG: Supabase Login Error: $e");
      rethrow;
    }
  }


  /// Sign in with Email, Phone, or Username
  Future<AuthResponse> signInWithUsernameOrEmail({
    required String identifier,
    required String password,
  }) async {
    final loginIdentifier = identifier.trim();
    if (loginIdentifier.isEmpty) throw 'Please enter your email or phone number';

    // 1. Try identifying it as a phone number directly
    if (RegExp(r'^[0-9+ ]+$').hasMatch(loginIdentifier) && !loginIdentifier.contains('@')) {
      try {
        return await _supabase.auth.signInWithPassword(
          phone: formatPhoneNumber(loginIdentifier),
          password: password,
        );
      } catch (e) {
        print("DEBUG: Direct phone login failed: $e. trying other methods...");
      }
    }

    // 2. Lookup profile to see if this is an email or username linked to a phone number
    try {
      final query = _supabase.from('profiles').select('email, phone_number');
      
      final Map<String, dynamic>? profileData = loginIdentifier.contains('@')
          ? await query.eq('email', loginIdentifier).maybeSingle()
          : await query.eq('username', loginIdentifier).maybeSingle();
            
      if (profileData != null) {
        final phone = profileData['phone_number']?.toString().trim();
        final emailFromProfile = profileData['email']?.toString().trim();
        
        // If we found a valid phone number, try it first
        if (phone != null && phone.isNotEmpty && phone != 'null') {
          try {
            return await _supabase.auth.signInWithPassword(phone: phone, password: password);
          } catch (phoneLoginError) {
            // Silently fall back if direct phone mapping fails
          }
        }
        
        // If phone login failed or no phone, try the email from profile or the identifier itself
        final effectiveEmail = (emailFromProfile != null && emailFromProfile.isNotEmpty && emailFromProfile != 'null') ? emailFromProfile : loginIdentifier;
        if (effectiveEmail.contains('@')) {
           return await signInWithEmailPassword(email: effectiveEmail, password: password);
        }
      }
    } catch (e) {
      print("DEBUG: Profile lookup failed: $e");
    }

    // 3. Last resort: try logging in with whatever was provided as an email
    return signInWithEmailPassword(email: loginIdentifier, password: password);
  }

  /// Sign up with Email and Password
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    String? phone,
    String? username,
    String? fullName,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (phone != null) data['phone'] = formatPhoneNumber(phone);
      if (username != null) data['username'] = username.trim();
      if (fullName != null) data['full_name'] = fullName.trim();
      if (role != null) data['role'] = role;

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: data.isNotEmpty ? data : null,
      );
      return response;
    } catch (e) {
      print("DEBUG: Supabase Email SignUp Error: $e");
      rethrow;
    }
  }

  /// Sign up with Phone and Password (triggers SMS verification)
  Future<AuthResponse> signUpWithPhonePassword({
    required String phone,
    required String password,
    String? email,
    String? username,
    String? role,
  }) async {
    try {
      String formatted = formatPhoneNumber(phone);
      final Map<String, dynamic> data = {};
      if (email != null) data['email'] = email.trim();
      if (username != null) data['username'] = username.trim();
      if (role != null) data['role'] = role;

      final response = await _supabase.auth.signUp(
        phone: formatted,
        password: password,
        data: data.isNotEmpty ? data : null,
      );
      return response;
    } catch (e) {
      print("DEBUG: Supabase Phone SignUp Error: $e");
      rethrow;
    }
  }

  String formatPhoneNumber(String phone) {
    // Remove all non-digit characters except the leading +
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = digits;
    
    if (formatted.startsWith('08')) {
      formatted = '264${formatted.substring(1)}';
    } else if (!formatted.startsWith('264')) {
      formatted = '264$formatted';
    }
    
    return '+$formatted';
  }

  /// Verifies the 6-digit OTP code (Phone)
  Future<bool> verifySmsCode(String phoneNumber, String token) async {
    try {
      final formattedPhone = formatPhoneNumber(phoneNumber);
      print("DEBUG: Verifying SMS OTP for $formattedPhone");
      final response = await _supabase.auth.verifyOTP(
        phone: formattedPhone,
        token: token,
        type: OtpType.sms,
      );

      if (response.user != null) {
        try {
          await syncUserProfile(response.user!);
        } catch (syncError) {
          print("DEBUG: Profile sync failed (ignoring): $syncError");
        }
        return true;
      }
      return false;
    } catch (e) {
      print("DEBUG: OTP Verification Error: $e");
      rethrow;
    }
  }

  /// Verifies the 6-digit OTP code (Email)
  /// Tries 'email', 'signup', 'magiclink', and 'recovery' types.
  Future<bool> verifyEmailCode(String email, String token) async {
    final types = [OtpType.email, OtpType.signup, OtpType.magiclink, OtpType.recovery];
    
    for (final type in types) {
      try {
        print("DEBUG: Verifying Email OTP (type: $type) for $email");
        final response = await _supabase.auth.verifyOTP(
          email: email.trim(),
          token: token,
          type: type,
        );

        if (response.user != null) {
          await _handlePostAuthSync(response.user!);
          return true;
        }
      } catch (e) {
        print("DEBUG: Email OTP Verification (type: $type) failed: $e");
        // Continue to next type if this one fails
        if (type == types.last) rethrow;
      }
    }
    return false;
  }

  /// Uploads a profile image to Supabase storage
  Future<String> uploadProfileImage(List<int> bytes, String fileName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User must be logged in to upload images');

      final extension = fileName.split('.').last;
      final path = 'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      // First ensure the bucket exists or we use a known bucket
      // Using 'profile-images' bucket for consistency
      await _supabase.storage.from('profile-images').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = _supabase.storage.from('profile-images').getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      if (e.statusCode == '404' && e.message.contains('Bucket not found')) {
        throw Exception(
          'Storage bucket "profile-images" not found.\n\n'
          'Please create it in Supabase Dashboard:\n'
          '1. Go to Storage section\n'
          '2. Click "New bucket"\n'
          '3. Name: "profile-images"\n'
          '4. Enable "Public bucket"\n'
          '5. Click "Create bucket"'
        );
      }
      print('Storage error uploading profile image: $e');
      rethrow;
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }

  /// Uploads a provider verification document (e.g. BIPA, tax certificate) to Supabase storage.
  ///
  /// Files are stored in the `provider-docs` bucket under:
  /// `docs/<userId>/<timestamp>.<ext>` and the public URL is returned.
  Future<String> uploadProviderDocument(List<int> bytes, String fileName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be logged in to upload documents');
      }

      final extension = fileName.split('.').last;
      final path = 'docs/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _supabase.storage.from('provider-docs').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = _supabase.storage.from('provider-docs').getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      if (e.statusCode == '404' && e.message.contains('Bucket not found')) {
        throw Exception(
          'Storage bucket "provider-docs" not found.\n\n'
          'Please create it in Supabase Dashboard:\n'
          '1. Go to Storage section\n'
          '2. Click "New bucket"\n'
          '3. Name: "provider-docs"\n'
          '4. Enable "Public bucket"\n'
          '5. Click "Create bucket"',
        );
      }
      print('Storage error uploading provider document: $e');
      rethrow;
    } catch (e) {
      print('Error uploading provider document: $e');
      rethrow;
    }
  }

  /// Deletes a previously uploaded provider document given its public URL.
  ///
  /// The [publicUrl] is expected to be generated by [uploadProviderDocument] and contain
  /// `/provider-docs/docs/<userId>/<timestamp>.<ext>` in its path.
  Future<void> deleteProviderDocument(String publicUrl) async {
    try {
      // Extract the storage path after the bucket name "provider-docs/".
      final marker = '/provider-docs/';
      final idx = publicUrl.indexOf(marker);
      if (idx == -1) {
        throw Exception('Invalid document URL. Cannot determine storage path.');
      }
      final path = publicUrl.substring(idx + marker.length);
      if (path.isEmpty) {
        throw Exception('Invalid document URL. Missing storage path segment.');
      }

      await _supabase.storage.from('provider-docs').remove([path]);
    } on StorageException catch (e) {
      print('Storage error deleting provider document: $e');
      rethrow;
    } catch (e) {
      print('Error deleting provider document: $e');
      rethrow;
    }
  }

  /// Uploads a gallery image to Supabase storage.
  ///
  /// Files are stored in the `provider-galleries` bucket under:
  /// `gallery/<userId>/<timestamp>.<ext>` and the public URL is returned.
  Future<String> uploadGalleryImage(List<int> bytes, String fileName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be logged in to upload gallery images');
      }

      final extension = fileName.split('.').last;
      final path = 'gallery/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _supabase.storage.from('provider-galleries').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = _supabase.storage.from('provider-galleries').getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      if (e.statusCode == '404' && e.message.contains('Bucket not found')) {
        throw Exception(
          'Storage bucket "provider-galleries" not found.\n\n'
          'Please create it in Supabase Dashboard:\n'
          '1. Go to Storage section\n'
          '2. Click "New bucket"\n'
          '3. Name: "provider-galleries"\n'
          '4. Enable "Public bucket"\n'
          '5. Click "Create bucket"',
        );
      }
      print('Storage error uploading gallery image: $e');
      rethrow;
    } catch (e) {
      print('Error uploading gallery image: $e');
      rethrow;
    }
  }

  /// Deletes a previously uploaded gallery image given its public URL.
  Future<void> deleteGalleryImage(String publicUrl) async {
    try {
      final marker = '/provider-galleries/';
      final idx = publicUrl.indexOf(marker);
      if (idx == -1) return; // Not a gallery image or already deleted
      
      final path = publicUrl.substring(idx + marker.length);
      if (path.isEmpty) return;

      await _supabase.storage.from('provider-galleries').remove([path]);
    } catch (e) {
      print('Error deleting gallery image: $e');
    }
  }

  Future<void> _handlePostAuthSync(User user) async {
    try {
      await syncUserProfile(user);
    } catch (syncError) {
      print("DEBUG: Profile sync failed (ignoring): $syncError");
    }
  }

  Future<void> resendOtp({
    required OtpType type,
    String? email,
    String? phone,
  }) async {
    try {
      await _supabase.auth.resend(
        type: type,
        email: email?.trim(),
        phone: phone?.trim(),
      );
    } catch (e) {
      print("DEBUG: Resend OTP Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Supabase Gotrue throws AuthRetryableFetchException on logout if network fails
      // We can safely ignore this as the local session is usually cleared.
      print("DEBUG: Sign out network error ignored: $e");
    }
  }

  /// Deletes the current user's profile and signs them out.
  /// Note: Full Auth user deletion typically requires a service role key on a backend.
  /// This method removes the profile data and signs out.
  Future<void> deleteAccount(String userId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', userId);
      await signOut();
    } catch (e) {
      print("DEBUG: Delete Account Error: $e");
      rethrow;
    }
  }

  /// Syncs the user's basic info to Supabase profiles
  Future<void> syncUserProfile(User user) async {
    final Map<String, dynamic> updates = {
      'last_active': DateTime.now().toIso8601String(),
    };

    // Read existing profile first so auth/session metadata does not
    // unintentionally overwrite user-edited profile fields on login.
    String? existingRole;
    String? existingPhone;
    String? existingEmail;
    String? existingFullName;
    try {
      final existing = await _supabase
          .from('profiles')
          .select('role, phone_number, email, full_name')
          .eq('id', user.id)
          .maybeSingle();
      existingRole = existing?['role'];
      existingPhone = existing?['phone_number']?.toString();
      existingEmail = existing?['email']?.toString();
      existingFullName = existing?['full_name']?.toString();
    } catch (e) {
      print("DEBUG: Profile check failed: $e");
    }

    // Keep existing DB phone/email/full name when present.
    // Only hydrate from auth/user metadata if profile values are empty.
    if ((existingPhone == null || existingPhone.trim().isEmpty)) {
      if (user.userMetadata != null && user.userMetadata!['phone'] != null) {
        updates['phone_number'] = user.userMetadata!['phone'];
      } else if (user.phone != null && user.phone!.trim().isNotEmpty) {
        updates['phone_number'] = user.phone!;
      }
    }

    if ((existingEmail == null || existingEmail.trim().isEmpty)) {
      if (user.userMetadata != null && user.userMetadata!['email'] != null) {
        updates['email'] = user.userMetadata!['email'];
      } else if (user.email != null && user.email!.trim().isNotEmpty) {
        updates['email'] = user.email!;
      }
    }

    if ((existingFullName == null || existingFullName.trim().isEmpty)) {
      if (user.userMetadata != null && user.userMetadata!['full_name'] != null) {
        updates['full_name'] = user.userMetadata!['full_name'];
      }
    }

    // Keep role defaults but avoid overriding an existing profile role.
    if (user.userMetadata != null && user.userMetadata!['role'] != null) {
      updates['role'] = user.userMetadata!['role'];
    }

    // Default to customer if no role is found in metadata OR database
    updates['role'] ??= existingRole ?? 'customer';
    
    // Basic flags - only set defaults if record doesn't exist
    if (existingRole == null) {
      updates['is_buyer'] = true;

      // Only Service Providers go through the manual verification queue.
      // Customers and Sellers are activated immediately upon profile sync.
      final role = (updates['role'] ?? 'customer').toString().trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');
      final isProviderRole = role == 'service_provider' ||
          role.contains('service provider') ||
          role.contains('service pro') ||
          role.contains('mechanic') ||
          role.contains('towing') ||
          role.contains('logistics') ||
          role.contains('rental');

      if (isProviderRole) {
        updates['verification_status'] = 'unverified';
        updates['is_buyer'] = false;
        updates['is_seller'] = false;
        // Keep DB defaults (likely pending_verification) for providers
      } else {
        // Customers/Sellers/Admins: Bypass verification entirely
        updates['status'] = 'active';
        updates['verification_status'] = 'approved';
      }
    }

    await _supabase.from('profiles').upsert({'id': user.id, ...updates});
  }

  /// Updates specific profile fields (like full_name)
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? username,
    String? avatarUrl,
    String? phoneNumber,
    String? businessContactNumber,
    String? tradingName,
    String? primaryServiceCategory,
    bool? remindersEnabled,
    bool? dealsEnabled,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? serviceAreaDescription,
    String? workingHours,
    List<String>? providerServiceTypes,
    List<String>? brandExpertise,
    List<String>? serviceTags,
    List<String>? towingCapabilities,
  }) async {
    final Map<String, dynamic> updates = {
      'last_active': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['profile_img'] = avatarUrl; // Changed from avatar_url to profile_img
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (businessContactNumber != null) updates['business_contact_number'] = businessContactNumber;
    if (tradingName != null) updates['trading_name'] = tradingName;
    if (primaryServiceCategory != null) updates['primary_service_category'] = primaryServiceCategory;
    if (remindersEnabled != null) updates['reminders_enabled'] = remindersEnabled;
    if (dealsEnabled != null) updates['deals_enabled'] = dealsEnabled;
    if (emergencyContactName != null) updates['emergency_contact_name'] = emergencyContactName;
    if (emergencyContactPhone != null) updates['emergency_contact_phone'] = emergencyContactPhone;
    if (serviceAreaDescription != null) updates['service_area_description'] = serviceAreaDescription;
    if (workingHours != null) updates['working_hours'] = workingHours;
    if (providerServiceTypes != null) updates['provider_service_types'] = providerServiceTypes.isEmpty ? '' : providerServiceTypes.join(',');
    if (brandExpertise != null) updates['brand_expertise'] = brandExpertise.isEmpty ? '' : brandExpertise.join(',');
    if (serviceTags != null) updates['service_tags'] = serviceTags.isEmpty ? '' : serviceTags.join(',');
    if (towingCapabilities != null) updates['towing_capabilities'] = towingCapabilities.isEmpty ? '' : towingCapabilities.join(',');

    await _supabase.from('profiles').update(updates).eq('id', userId);
    print("DEBUG: Profile updated for $userId");
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseAuthProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseAuthProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ?? ref.watch(supabaseAuthProvider).auth.currentUser;
});
