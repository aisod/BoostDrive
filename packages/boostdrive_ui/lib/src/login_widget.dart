import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'theme.dart';

class BoostLoginWidget extends StatefulWidget {
  final Function(String email, String password) onLogin;
  final Function({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? username,
    String? primaryServiceCategory,
  }) onSignUp;
  final Function(String otp) onVerifyOtp;
  final VoidCallback? onResendOtp;
  final VoidCallback? onCancelOtp;
  final VoidCallback? onClose;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onAppleSignIn;
  final bool isLoading;
  final bool isOtpSent;
  final String? errorText;

  const BoostLoginWidget({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    required this.onVerifyOtp,
    this.onResendOtp,
    this.onCancelOtp,
    this.onClose,
    this.onForgotPassword,
    this.onGoogleSignIn,
    this.onAppleSignIn,
    this.isLoading = false,
    this.isOtpSent = false,
    this.errorText,
  });

  @override
  State<BoostLoginWidget> createState() => _BoostLoginWidgetState();
}

class _BoostLoginWidgetState extends State<BoostLoginWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;
  Timer? _timer;
  int _secondsRemaining = 0;

  /// Input text color: black on web (light fields), white on mobile (dark theme).
  Color get _inputTextColor => kIsWeb ? Colors.black87 : Colors.white;

  final List<Map<String, String>> _primaryServiceOptions = const [
    {'key': 'mechanic', 'label': 'Mechanics'},
    {'key': 'towing', 'label': 'Towing'},
    {'key': 'electrical', 'label': 'Electrical'},
    {'key': 'tires', 'label': 'Tires'},
  ];

  String? _primaryServiceCategoryKey = 'mechanic';


  @override
  void didUpdateWidget(covariant BoostLoginWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isOtpSent && widget.isOtpSent) {
      _startTimer();
    } else if (oldWidget.isOtpSent && !widget.isOtpSent) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer();
    setState(() {
      _secondsRemaining = 180; // 3 minutes
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String? _selectedRole;

  @override
  void dispose() {
    _stopTimer();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _businessPhoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isServiceProviderSignUp => _selectedRole == 'Service Provider';

  String _formatNamibiaBusinessPhone(String raw) {
    // Keep digits only.
    String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    // If user entered a leading country prefix without + (e.g. 264...), keep it.
    if (digits.startsWith('264')) {
      digits = digits.substring(3);
    }
    // If user entered a local '0...' number, drop the leading 0.
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '+264$digits';
  }

  void _submit() {
    final currentKey = widget.isOtpSent 
        ? _otpFormKey 
        : (_isSignUp ? _signUpFormKey : _loginFormKey);

    if (currentKey.currentState?.validate() ?? false) {
      if (widget.isOtpSent) {
        widget.onVerifyOtp(_otpController.text);
      } else if (_isSignUp) {
        if (_selectedRole == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a role to continue'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        final isProvider = _isServiceProviderSignUp;
        final formattedBusinessPhone =
            isProvider ? _formatNamibiaBusinessPhone(_businessPhoneController.text) : '';
        widget.onSignUp(
          fullName: _nameController.text,
          email: _emailController.text,
          phone: formattedBusinessPhone,
          password: _passwordController.text,
          role: _selectedRole!,
          primaryServiceCategory: isProvider ? (_primaryServiceCategoryKey ?? 'mechanic') : null,
        );
      } else {
        widget.onLogin(
          _emailController.text,
          _passwordController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TextField/TextFormField require a Material ancestor; provide one so login works
    // when this widget is used inside Container/Stack (e.g. login_page split layout) without a Scaffold.
    return Material(
      color: Colors.transparent,
      child: widget.isOtpSent ? _buildOtpView() : (_isSignUp ? _buildSignUpView() : _buildLoginView()),
    );
  }

  void _handleClose() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Widget _buildLoginView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = kIsWeb;
        
        // Mobile-specific or small screen layout
        // On Web, if the available width is less than 900px (e.g. in a side drawer), 
        // we should probably use a single column layout to avoid cramping.
        if (!isWeb || constraints.maxWidth < 900) {
          final totalHeight = constraints.maxHeight;
          final headerHeight = totalHeight * 0.35;
          
          return Container(
            color: BoostDriveTheme.backgroundDark,
            child: Stack(
              children: [
                Column(
                  children: [
                    // Hero Header
                    Container(
                      height: headerHeight,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F0F0F),
                            Color(0xFF000000),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BoostDrive',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Premium Mobility\nReimagined.',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Login Content
                    Expanded(
                      child: Container(
                        transform: Matrix4.translationValues(0, -24, 0),
                        decoration: const BoxDecoration(
                          color: BoostDriveTheme.backgroundDark,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: Form(
                            key: _loginFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28, 
                                    fontWeight: FontWeight.w900, 
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to your premium account',
                                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                                ),
                                const SizedBox(height: 32),
                                
                                _buildLabel('Email'),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: _inputDecoration('name@example.com', Icons.alternate_email),
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                                  validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
                                ),
                                const SizedBox(height: 16),
                                
                                _buildLabel('Password'),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: _inputDecoration('••••••••', Icons.lock_outline, isPassword: true),
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                                  validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
                                ),
                                
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: widget.onForgotPassword,
                                    child: Text(
                                      'Forgot Password?', 
                                      style: GoogleFonts.poppins(
                                        color: BoostDriveTheme.primaryColor, 
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                if (widget.errorText != null) ...[
                                  const SizedBox(height: 16),
                                  _buildErrorDisplay(widget.errorText!),
                                ],
                                
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: BoostDriveTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 0,
                                    ),
                                    onPressed: widget.isLoading ? null : _submit,
                                    child: widget.isLoading 
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                      : Text(
                                          'LOGIN',
                                          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                                        ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text("Don't have an account?", style: TextStyle(color: Colors.white60)),
                                      TextButton(
                                        onPressed: () => setState(() => _isSignUp = true),
                                        child: const Text('Sign Up', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Close Button for Side Panel (Web only)
                if (isWeb)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: _handleClose,
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // Web-specific layout (Split-Screen Editorial)
        return _buildWebLayout(
          constraints: constraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: GoogleFonts.montserrat(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your account',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white54,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48),
              Form(
                key: _loginFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('EMAIL ADDRESS'),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('name@example.com', Icons.alternate_email),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                      validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('PASSWORD'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration('••••••••', Icons.lock_outline, isPassword: true),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                      validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onForgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.poppins(
                            color: BoostDriveTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    if (widget.errorText != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorDisplay(widget.errorText!),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BoostDriveTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: widget.isLoading ? null : _submit,
                        child: widget.isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text(
                              'LOGIN',
                              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isSignUp = true),
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.poppins(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 14),
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
      },
    );
  }
  Widget _buildSignUpView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = kIsWeb;

        // Mobile-specific or small screen layout
        if (!isWeb || constraints.maxWidth <= 900) {
          return Container(
            color: BoostDriveTheme.backgroundDark,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F0F0F),
                            Color(0xFF000000),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JOIN BOOSTDRIVE',
                            style: GoogleFonts.montserrat(
                              color: BoostDriveTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Create Your\nPremium Account.',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        onPressed: _handleClose,
                        icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _signUpFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Account Type',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose your primary role to get started.',
                            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          
                          // Role Grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.2,
                            children: [
                              _buildRoleCard('Customer / Seller', 'Buy & sell vehicle parts', Icons.person),
                              _buildRoleCard('Service Provider', 'Registered Businesses', Icons.build),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                          


                          
                          _buildLabel(_isServiceProviderSignUp ? 'Business Trading Name' : 'Full Name'),
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration('John Doe', Icons.person_outline),
                            style: TextStyle(color: _inputTextColor),
                            validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 20),

                          if (_isServiceProviderSignUp) ...[
                            _buildLabel('BUSINESS PHONE NUMBER'),
                            TextFormField(
                              controller: _businessPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration('61 555 0036', Icons.phone_outlined).copyWith(
                                prefixText: '+264 ',
                              ),
                              style: TextStyle(color: _inputTextColor),
                              validator: (v) {
                                final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                                if (digits.isEmpty) return 'Business phone number is required';
                                if (digits.length < 9) return 'Enter a valid phone number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            _buildLabel('PRIMARY SERVICE'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _primaryServiceOptions.map((opt) {
                                  final key = opt['key']!;
                                  final label = opt['label']!;
                                  final selected = (_primaryServiceCategoryKey ?? 'mechanic') == key;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: ChoiceChip(
                                      label: Text(label),
                                      selected: selected,
                                      onSelected: (_) {
                                        setState(() => _primaryServiceCategoryKey = key);
                                      },
                                      selectedColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                                      labelStyle: TextStyle(
                                        color: selected ? BoostDriveTheme.primaryColor : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: selected ? BoostDriveTheme.primaryColor : Colors.white24,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          _buildLabel('EMAIL ADDRESS'),
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('john@example.com', Icons.mail_outline),
                            style: TextStyle(color: _inputTextColor),
                            validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                          ),
                          const SizedBox(height: 20),
                          
                          _buildLabel('PASSWORD'),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: _inputTextColor),
                            decoration: _inputDecoration('••••••••', Icons.lock_outline, isPassword: true).copyWith(
                              helperText: _isSignUp ? 'Min 8 chars: Upper, Lower, Number & Symbol' : null,
                              helperStyle: TextStyle(color: kIsWeb ? Colors.black54 : Colors.white38, fontSize: 10),
                            ),
                            validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
                          ),
                          const SizedBox(height: 20),
                          
                          _buildLabel('CONFIRM PASSWORD'),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: _inputTextColor),
                            decoration: _inputDecoration('••••••••', Icons.lock_outline, isPassword: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm password';
                              if (v != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          
                          if (widget.errorText != null) ...[
                            const SizedBox(height: 24),
                            _buildErrorDisplay(widget.errorText!),
                          ],
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BoostDriveTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: widget.isLoading ? null : _submit,
                              child: widget.isLoading 
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : Text(
                                    'CREATE ACCOUNT',
                                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                                  ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          const Text(
                            'By tapping "Create Account", you agree to our Terms of Service and Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white24, fontSize: 11),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account?', style: TextStyle(color: Colors.white60)),
                                TextButton(
                                  onPressed: () => setState(() => _isSignUp = false),
                                  child: const Text('Login', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
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

        // Web-specific layout (Split-Screen Editorial)
        return _buildWebLayout(
          constraints: constraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: GoogleFonts.montserrat(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join the premium automotive ecosystem',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white54,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              
              // Role Selection
              Row(
                children: [
                  Expanded(child: _buildWebRoleCard('Customer / Seller', 'Buy & sell vehicle parts', Icons.person)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildWebRoleCard('Service Provider', 'Registered Businesses', Icons.build)),
                ],
              ),
                   Form(
                key: _signUpFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(_isServiceProviderSignUp ? 'BUSINESS TRADING NAME' : 'FULL NAME'),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('e.g. John Doe', Icons.person_outline),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                      validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 24),

                    if (_isServiceProviderSignUp) ...[
                      _buildLabel('BUSINESS PHONE NUMBER'),
                      TextFormField(
                        controller: _businessPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('61 555 0036', Icons.phone_outlined).copyWith(
                          prefixText: '+264 ',
                          prefixStyle: GoogleFonts.poppins(color: Colors.white70),
                        ),
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                        validator: (v) {
                          final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.isEmpty) return 'Phone number is required';
                          if (digits.length < 9) return 'Invalid phone number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('PRIMARY SERVICE'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _primaryServiceOptions.map((opt) {
                            final key = opt['key']!;
                            final label = opt['label']!;
                            final selected = (_primaryServiceCategoryKey ?? 'mechanic') == key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ChoiceChip(
                                label: Text(label),
                                selected: selected,
                                onSelected: (_) => setState(() => _primaryServiceCategoryKey = key),
                                selectedColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                                backgroundColor: Colors.white.withValues(alpha: 0.03),
                                labelStyle: GoogleFonts.poppins(
                                  color: selected ? BoostDriveTheme.primaryColor : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: selected ? BoostDriveTheme.primaryColor : Colors.white10),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    _buildLabel('EMAIL ADDRESS'),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('name@example.com', Icons.alternate_email),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                      validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('PASSWORD'),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: _inputDecoration('••••••••', Icons.lock_outline, isPassword: true),
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                                validator: (v) => v == null || v.length < 6 ? 'Too short' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CONFIRM'),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscurePassword,
                                decoration: _inputDecoration('••••••••', Icons.lock_clock_outlined, isPassword: true),
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                                validator: (v) => v != _passwordController.text ? 'Mismatch' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (widget.errorText != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorDisplay(widget.errorText!),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BoostDriveTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: widget.isLoading ? null : _submit,
                        child: widget.isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text(
                              'CREATE ACCOUNT',
                              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isSignUp = false),
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.poppins(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 14),
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
      },
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, String subtitle, IconData icon) {
    bool isSelected = (_selectedRole == title);

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? BoostDriveTheme.primaryColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BoostDriveTheme.primaryColor : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isSelected ? BoostDriveTheme.primaryColor : Colors.white38, 
              size: 28
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebRoleCard(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedRole == title;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? BoostDriveTheme.primaryColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? BoostDriveTheme.primaryColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon, 
              color: isSelected ? BoostDriveTheme.primaryColor : Colors.white38, 
              size: 32
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.montserrat(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white54 : Colors.white24,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = kIsWeb;

        // Mobile/Small layout
        if (!isWeb || constraints.maxWidth <= 900) {
          return Container(
            color: BoostDriveTheme.backgroundDark,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F0F0F),
                            Color(0xFF000000),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SECURE VERIFICATION',
                            style: GoogleFonts.montserrat(
                              color: BoostDriveTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Verify Your\nAccount.',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        onPressed: widget.onCancelOtp,
                        icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 24),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _otpFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter 6-digit Code',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We sent a verification code to your email address.',
                            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                          ),
                          const SizedBox(height: 32),
                          
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 12,
                            ),
                            decoration: _inputDecoration('000000', Icons.lock_person_outlined),
                            validator: (v) => (v ?? '').length < 6 ? 'Invalid code' : null,
                          ),
                          
                          if (widget.errorText != null) ...[
                            const SizedBox(height: 16),
                            _buildErrorDisplay(widget.errorText!),
                          ],
                          
                          const SizedBox(height: 48),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BoostDriveTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: widget.isLoading ? null : _submit,
                              child: widget.isLoading 
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : Text(
                                    'VERIFY CODE',
                                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                                  ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          Center(
                            child: TextButton(
                              onPressed: _secondsRemaining == 0 ? widget.onResendOtp : null,
                              child: Text(
                                _secondsRemaining > 0
                                    ? 'Resend code in ${_formatDuration(_secondsRemaining)}'
                                    : 'Resend Verification Code',
                                style: GoogleFonts.poppins(
                                  color: _secondsRemaining == 0 ? BoostDriveTheme.primaryColor : Colors.white38,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
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

        // Web Split-Screen OTP
        return _buildWebLayout(
          constraints: constraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               IconButton(
                onPressed: widget.onCancelOtp,
                icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Email',
                style: GoogleFonts.montserrat(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirm your secure access code',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white54,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48),
              
              Form(
                key: _otpFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('6-DIGIT VERIFICATION CODE'),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 20,
                      ),
                      decoration: _inputDecoration('000000', Icons.lock_person_outlined),
                      validator: (v) => (v ?? '').length < 6 ? 'Invalid code' : null,
                    ),

                    if (widget.errorText != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorDisplay(widget.errorText!),
                    ],
                    
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BoostDriveTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: widget.isLoading ? null : _submit,
                        child: widget.isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text(
                              'VERIFY & CONTINUE',
                              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: TextButton(
                        onPressed: _secondsRemaining == 0 ? widget.onResendOtp : null,
                        child: Text(
                          _secondsRemaining > 0
                              ? 'Resend code in ${_formatDuration(_secondsRemaining)}'
                              : 'Resend Verification Code',
                          style: GoogleFonts.poppins(
                            color: _secondsRemaining == 0 ? BoostDriveTheme.primaryColor : Colors.white38,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
      },
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {bool isPassword = false}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BoostDriveTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout({
    required BoxConstraints constraints,
    required Widget child,
  }) {
    return Material(
      color: Colors.black,
      child: SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: Row(
          children: [
            // Left Side: Editorial Image & Quote
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                   Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/landing-page-image.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(80.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'BoostDrive',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          '"Drive Your Dreams\nForward."',
                          style: GoogleFonts.montserrat(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 100,
                          height: 6,
                          color: BoostDriveTheme.primaryColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'EXPERIENCE PREMIUM MOBILITY IN NAMIBIA',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Right Side: Auth Form
            Expanded(
              flex: 3,
              child: Container(
                color: const Color(0xFF0F0F0F),
                child: Stack(
                  children: [
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
                        child: child,
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 40,
                      child: IconButton(
                        onPressed: _handleClose,
                        icon: const Icon(Icons.close, color: Colors.white54, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
