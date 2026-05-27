import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'auth_design_tokens.dart';
import 'auth_ui_components.dart';

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
  final Future<void> Function()? onResendOtp;
  final VoidCallback? onCancelOtp;
  final VoidCallback? onClose;
  final VoidCallback? onForgotPassword;
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
  bool _isResending = false;

  final List<Map<String, String>> _primaryServiceOptions = const [
    {'key': 'mechanic', 'label': 'Mechanics'},
    {'key': 'towing', 'label': 'Towing'},
    {'key': 'electrical', 'label': 'Electrical'},
    {'key': 'tires', 'label': 'Tires'},
  ];

  String? _primaryServiceCategoryKey = 'mechanic';
  String? _selectedRole;

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
    setState(() => _secondsRemaining = 180);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
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

  bool get _isServiceProviderSignUp => _selectedRole == 'Service Provider';

  String _formatNamibiaBusinessPhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('264')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
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
        widget.onLogin(_emailController.text, _passwordController.text);
      }
    }
  }

  void _handleClose() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
      return;
    }
    Navigator.of(context).maybePop();
  }

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

  @override
  Widget build(BuildContext context) {
    final tokens = AuthDesignTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: widget.isOtpSent
          ? _buildOtpView(tokens)
          : (_isSignUp ? _buildSignUpView(tokens) : _buildLoginView(tokens)),
    );
  }

  Widget _buildLoginHero(AuthDesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'BOOSTDRIVE',
          style: GoogleFonts.montserrat(
            color: tokens.isDark ? tokens.primaryContainer : tokens.primaryFixedDim,
            fontSize: tokens.isDark ? 32 : 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your Premium Automotive Connection',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: tokens.isDark ? 48 : 40,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpHero(AuthDesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'BOOSTDRIVE',
          style: GoogleFonts.montserrat(
            color: tokens.isDark ? tokens.primaryContainer : tokens.primaryFixedDim,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'DRIVE THE FUTURE.',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: tokens.isDark ? 48 : 40,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Namibia's ultimate automotive destination for high-performance vehicles, verified services, and elite auctions.",
          style: GoogleFonts.montserrat(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpHero(AuthDesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'BOOSTDRIVE',
          style: GoogleFonts.manrope(
            color: tokens.isDark ? tokens.primaryContainer : tokens.primaryFixedDim,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The premium destination for Namibian automotive excellence.',
          style: GoogleFonts.manrope(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginView(AuthDesignTokens tokens) {
    return AuthSplitLayout(
      tokens: tokens,
      heroImageUrl: AuthDesignTokens.loginHeroImage,
      heroContent: _buildLoginHero(tokens),
      onClose: widget.onClose != null || kIsWeb ? _handleClose : null,
      formContent: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthPageHeader(
              tokens: tokens,
              title: 'Welcome Back',
              subtitle: 'Login to your account to continue your journey.',
            ),
            AuthFieldLabel(tokens: tokens, label: 'Email Address'),
            AuthTextField(
              tokens: tokens,
              controller: _emailController,
              hint: 'name@example.com',
              icon: Icons.mail_outline,
              validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: AuthFieldLabel(tokens: tokens, label: 'Password')),
                TextButton(
                  onPressed: widget.onForgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.montserrat(
                      color: tokens.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            AuthTextField(
              tokens: tokens,
              controller: _passwordController,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              showVisibilityToggle: true,
              onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
            ),
            if (widget.errorText != null) ...[
              const SizedBox(height: 16),
              AuthErrorBanner(tokens: tokens, message: widget.errorText!),
            ],
            const SizedBox(height: 28),
            AuthPrimaryButton(
              tokens: tokens,
              label: 'Sign In',
              isLoading: widget.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 32),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: GoogleFonts.montserrat(color: tokens.onSurfaceVariant, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = true),
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.montserrat(
                        color: tokens.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpView(AuthDesignTokens tokens) {
    return AuthSplitLayout(
      tokens: tokens,
      heroImageUrl: AuthDesignTokens.signUpHeroImage,
      heroContent: _buildSignUpHero(tokens),
      onClose: widget.onClose != null || kIsWeb ? _handleClose : null,
      formContent: Form(
        key: _signUpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthPageHeader(
              tokens: tokens,
              title: 'Create Account',
              subtitle: "Join the community of Namibia's automotive elite.",
            ),
            Text(
              'Select Account Type',
              style: GoogleFonts.montserrat(
                color: tokens.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildRoleCard(tokens, 'Customer / Seller', 'Buy & sell vehicle parts', Icons.person)),
                const SizedBox(width: 12),
                Expanded(child: _buildRoleCard(tokens, 'Service Provider', 'Registered Businesses', Icons.build)),
              ],
            ),
            const SizedBox(height: 24),
            AuthFieldLabel(
              tokens: tokens,
              label: _isServiceProviderSignUp ? 'Business Trading Name' : 'Full Name',
            ),
            AuthTextField(
              tokens: tokens,
              controller: _nameController,
              hint: 'John Doe',
              icon: Icons.person_outline,
              pillShape: false,
              validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
            ),
            if (_isServiceProviderSignUp) ...[
              const SizedBox(height: 20),
              AuthFieldLabel(tokens: tokens, label: 'Business Phone Number'),
              AuthTextField(
                tokens: tokens,
                controller: _businessPhoneController,
                hint: '61 555 0036',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                prefixText: '+264 ',
                pillShape: false,
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) return 'Business phone number is required';
                  if (digits.length < 9) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AuthFieldLabel(tokens: tokens, label: 'Primary Service'),
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
                        onSelected: (_) => setState(() => _primaryServiceCategoryKey = key),
                        selectedColor: tokens.primaryContainer.withValues(alpha: 0.2),
                        backgroundColor: tokens.surfaceContainer,
                        labelStyle: GoogleFonts.montserrat(
                          color: selected ? tokens.primary : tokens.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: selected ? tokens.primaryContainer : tokens.outlineVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            AuthFieldLabel(tokens: tokens, label: 'Email Address'),
            AuthTextField(
              tokens: tokens,
              controller: _emailController,
              hint: 'john@example.com',
              icon: Icons.mail_outline,
              pillShape: false,
              validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
            ),
            const SizedBox(height: 20),
            AuthFieldLabel(tokens: tokens, label: 'Password'),
            AuthTextField(
              tokens: tokens,
              controller: _passwordController,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              showVisibilityToggle: true,
              onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
              pillShape: false,
              validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
            ),
            const SizedBox(height: 20),
            AuthFieldLabel(tokens: tokens, label: 'Confirm Password'),
            AuthTextField(
              tokens: tokens,
              controller: _confirmPasswordController,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              pillShape: false,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            if (widget.errorText != null) ...[
              const SizedBox(height: 16),
              AuthErrorBanner(tokens: tokens, message: widget.errorText!),
            ],
            const SizedBox(height: 28),
            AuthPrimaryButton(
              tokens: tokens,
              label: 'Create Account',
              isLoading: widget.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Text(
              'By signing up, you agree to our Terms of Service and Privacy Policy.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: tokens.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: tokens.outlineVariant),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: GoogleFonts.montserrat(color: tokens.onSurfaceVariant, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = false),
                    child: Text(
                      'Login',
                      style: GoogleFonts.montserrat(
                        color: tokens.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(AuthDesignTokens tokens, String title, String subtitle, IconData icon) {
    final isSelected = _selectedRole == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? tokens.primaryContainer.withValues(alpha: 0.12) : tokens.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? tokens.primaryContainer : tokens.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? tokens.primaryContainer : tokens.onSurfaceVariant, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.montserrat(
                color: tokens.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                color: tokens.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpView(AuthDesignTokens tokens) {
    return AuthSplitLayout(
      tokens: tokens,
      heroImageUrl: AuthDesignTokens.otpHeroImage,
      heroContent: _buildOtpHero(tokens),
      onClose: widget.onCancelOtp,
      formContent: Form(
        key: _otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthPageHeader(
              tokens: tokens,
              title: 'Verify Your Email',
              subtitle: 'Enter the 6-digit code sent to your email.',
            ),
            AuthOtpInput(
              tokens: tokens,
              controller: _otpController,
              validator: (v) => (v ?? '').length < 6 ? 'Invalid code' : null,
            ),
            if (widget.errorText != null) ...[
              const SizedBox(height: 16),
              AuthErrorBanner(tokens: tokens, message: widget.errorText!),
            ],
            const SizedBox(height: 40),
            AuthPrimaryButton(
              tokens: tokens,
              label: 'Verify',
              trailingIcon: Icons.verified_user_outlined,
              isLoading: widget.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: (_secondsRemaining == 0 &&
                        !_isResending &&
                        !widget.isLoading &&
                        widget.onResendOtp != null)
                    ? () async {
                        setState(() => _isResending = true);
                        try {
                          await widget.onResendOtp!();
                          if (mounted) {
                            _otpController.clear();
                            _startTimer();
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isResending = false);
                          }
                        }
                      }
                    : null,
                child: Text(
                  _isResending || widget.isLoading
                      ? 'Sending new code...'
                      : _secondsRemaining > 0
                          ? 'Resend code in ${_formatDuration(_secondsRemaining)}'
                          : "Didn't receive a code? Resend",
                  style: GoogleFonts.montserrat(
                    color: (_secondsRemaining == 0 && !_isResending && !widget.isLoading)
                        ? tokens.primary
                        : tokens.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
