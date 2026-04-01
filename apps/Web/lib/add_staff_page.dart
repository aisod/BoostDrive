import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:boost_drive_web/web_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class AddStaffPage extends ConsumerStatefulWidget {
  const AddStaffPage({super.key});

  @override
  ConsumerState<AddStaffPage> createState() => _AddStaffPageState();
}

class _AddStaffPageState extends ConsumerState<AddStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _staffIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedRole = 'Mechanic';
  final List<String> _roleOptions = ['Mechanic', 'Lead Mechanic', 'Technician', 'Driver', 'Dispatcher'];

  bool _canViewFleet = false;
  bool _canAcceptSos = false;
  bool _canViewFinance = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _staffIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createStaffAccount() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool isDotEnvInitialized = false;
      try {
        await dotenv.load(fileName: ".env");
        isDotEnvInitialized = true;
      } catch (_) {}

      final supabaseUrl = isDotEnvInitialized 
          ? (dotenv.maybeGet('SUPABASE_URL') ?? WebUtils.getEnv('SUPABASE_URL')) 
          : WebUtils.getEnv('SUPABASE_URL');
      final supabaseAnonKey = isDotEnvInitialized 
          ? (dotenv.maybeGet('SUPABASE_ANON_KEY') ?? WebUtils.getEnv('SUPABASE_ANON_KEY')) 
          : WebUtils.getEnv('SUPABASE_ANON_KEY');

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) throw Exception('Supabase configuration missing.');

      final tempClient = SupabaseClient(
        supabaseUrl, 
        supabaseAnonKey,
        authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
      );

      final email = _emailController.text.trim();
      
      // 2. Sign up the new staff member (dispatches OTP automatically)
      final signUpResponse = await tempClient.auth.signUp(
        email: email,
        password: _passwordController.text,
        data: {
          'full_name': _nameController.text.trim(),
          'role': 'staff',
          'phone': _phoneController.text.trim(),
        }
      );

      final newUserId = signUpResponse.user?.id;
      if (newUserId == null) throw Exception('Failed to create sub-account authentication record.');

      if (!mounted) return;
      
      // 3. Pause & spawn OTP verification dialog. 
      // The DB insert only occurs inside the dialog AFTER successful OTP verification.
      await _showOtpDialog(
        tempClient: tempClient,
        email: email,
        providerId: user.id,
        newUserId: newUserId,
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating staff: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showOtpDialog({
    required SupabaseClient tempClient,
    required String email,
    required String providerId,
    required String newUserId,
  }) async {
    final codeController = TextEditingController();
    bool isVerifying = false;
    bool isResending = false;
    String? errorMessage;
    int resendCooldown = 0;
    
    // Timer logic for resend cooldown
    void startResendTimer(void Function(void Function()) setDialogState) {
      setDialogState(() => resendCooldown = 60);
      Stream.periodic(const Duration(seconds: 1), (i) => 60 - i - 1)
          .take(60)
          .listen((seconds) {
            if (mounted) {
              setDialogState(() => resendCooldown = seconds);
            }
          });
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161A23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              title: const Text('Verify Email Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const Text(
                    'A 6-digit verification code was just sent to the staff member\'s email. Please ask them for the code and enter it below to authorize this sub-account.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: codeController,
                    hintText: '6-Digit Verification Code',
                    prefixIcon: Icons.dialpad,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: (resendCooldown > 0 || isResending) ? null : () async {
                      setDialogState(() {
                        isResending = true;
                        errorMessage = null;
                      });
                      try {
                        await tempClient.auth.resend(
                          type: OtpType.signup,
                          email: email,
                        );
                        if (mounted) {
                          startResendTimer(setDialogState);
                          setDialogState(() => isResending = false);
                        }
                      } catch (e) {
                        if (mounted) {
                          setDialogState(() {
                            isResending = false;
                            errorMessage = 'Failed to resend code. Please try again later.';
                          });
                        }
                      }
                    },
                    child: Text(
                      resendCooldown > 0 
                        ? 'Resend code in ${resendCooldown}s' 
                        : (isResending ? 'Sending...' : 'Didn\'t receive a code? RESEND'),
                      style: TextStyle(
                        color: resendCooldown > 0 ? Colors.white24 : BoostDriveTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () async {
                    if (codeController.text.trim().length < 6) {
                      setDialogState(() => errorMessage = 'Please enter the full 6-digit code.');
                      return;
                    }
                    
                    setDialogState(() {
                      isVerifying = true;
                      errorMessage = null;
                    });
                    
                    try {
                      // Attempt verification
                      await tempClient.auth.verifyOTP(
                        type: OtpType.signup,
                        email: email,
                        token: codeController.text.trim(),
                      );
                      
                      // Success! Verify clears. Insert staff record into the primary hub.
                      await Supabase.instance.client.from('provider_staff').insert({
                        'provider_id': providerId,
                        'staff_user_id': newUserId,
                        'full_name': _nameController.text.trim(),
                        'staff_role': _selectedRole,
                        'staff_internal_id': _staffIdController.text.trim().isEmpty ? null : _staffIdController.text.trim(),
                        'phone_number': _phoneController.text.trim(),
                        'email': email,
                        'can_view_fleet': _canViewFleet,
                        'can_accept_sos': _canAcceptSos,
                        'can_view_finance': _canViewFinance,
                      });
                      
                      // Force immediate refresh of the stream on the dashboard
                      ref.invalidate(providerStaffProvider(providerId));
                      
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Staff member successfully verified and added!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context, true); // Pop AddStaffPage with success signal
                      }
                    } catch (e) {
                      if (mounted) {
                        setDialogState(() {
                          isVerifying = false;
                          errorMessage = 'Verification failed: Ensure the code is correct. ($e)';
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoostDriveTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isVerifying
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('VERIFY & ADD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Team Member',
          style: TextStyle(fontFamily: 'Manrope', 
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: const Color(0xFF161A23),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_rounded, size: 48, color: BoostDriveTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Employee Profile Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Full Legal Name',
                    prefixIcon: Icons.person_outline,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: BoostDriveTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        dropdownColor: BoostDriveTheme.surfaceDark,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        onChanged: (String? newValue) {
                          if (newValue != null) setState(() => _selectedRole = newValue);
                        },
                        items: _roleOptions.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _staffIdController,
                    hintText: 'Staff ID / Employee Number (Optional)',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email Address (for login & notifications)',
                    prefixIcon: Icons.email_outlined,
                    validator: (val) => val == null || !val.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Initial Temporary Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 48),
                  
                  const Text('Sub-Account Permissions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Decide what this staff member can access within your Provider Hub.', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 24),
                  
                  _buildToggleRow('View Fleet', 'Can view status of all vehicles in shop.', _canViewFleet, (val) => setState(() => _canViewFleet = val)),
                  const Divider(color: Colors.white10, height: 32),
                  _buildToggleRow('Accept SOS Tasks', 'Allowed to respond to roadside emergencies.', _canAcceptSos, (val) => setState(() => _canAcceptSos = val)),
                  const Divider(color: Colors.white10, height: 32),
                  _buildToggleRow('Financial Access', 'Can view \$0.00 Lifetime Earnings card and payouts.', _canViewFinance, (val) => setState(() => _canViewFinance = val)),
                  
                  const SizedBox(height: 48),
                  
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createStaffAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BoostDriveTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'CREATE STAFF ACCOUNT',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
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

  Widget _buildToggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: BoostDriveTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(prefixIcon, color: Colors.white54),
        filled: true,
        fillColor: BoostDriveTheme.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BoostDriveTheme.primaryColor),
        ),
      ),
    );
  }
}
