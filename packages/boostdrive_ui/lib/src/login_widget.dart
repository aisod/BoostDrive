import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  }) onSignUp;
  final Function(String otp) onVerifyOtp;
  final VoidCallback? onResendOtp;
  final VoidCallback? onCancelOtp;
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
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;
  Timer? _timer;
  int _secondsRemaining = 0;

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
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
        widget.onSignUp(
          fullName: _nameController.text,
          email: _emailController.text,
          phone: '', // Phone number removed from UI
          password: _passwordController.text,
          role: _selectedRole!,
          username: _usernameController.text,
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
    if (widget.isOtpSent) return _buildOtpView();
    return _isSignUp ? _buildSignUpView() : _buildLoginView();
  }

  Widget _buildLoginView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final headerHeight = totalHeight * 0.4;
        
        return Container(
          color: BoostDriveTheme.backgroundDark,
          child: Column(
            children: [
              // Hero Header
              Container(
                height: headerHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuCuAfnKgvQTFU8mdXJOK2OJrSdpcF6QMKvI6MtCv2T_PuowUTuBUYTxnovRCWOeMgWX20Fdpa6ngazsCa0_-jipGQq37sUi9ZbskUd73-uZkY2403hVqKMhDUMbsBkd0ziAG9ADrjcCgutXcPUyzcwP7yp9jbq_dO_Jma3E8CGlLryK-nu_xr2gv3rVZxLZj3aEas8jNt4q2C2SP0dCSVuSaqeNQnM_AVkU5VYP5KnqN10-3azckFoWgiw7Jkar42nxdR9aCLkX6Ps"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed, color: Colors.white, size: 40),
                          const SizedBox(width: 8),
                          Text(
                            'BoostDrive',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your Complete Automotive Ecosystem',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Login Content
              Expanded(
                child: Container(
                  transform: Matrix4.translationValues(0, -32, 0),
                  decoration: const BoxDecoration(
                    color: BoostDriveTheme.backgroundDark,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Form(
                      key: _loginFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(height: 32),
                          
                          _buildLabel('Email'),
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('Enter your email', Icons.mail_outline),
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
                          ),
                          const SizedBox(height: 20),
                          
                          _buildLabel('Password'),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration('Enter your password', Icons.lock_outline, isPassword: true),
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: widget.onForgotPassword,
                              child: const Text('Forgot Password?', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          
                          if (widget.errorText != null) ...[
                            const SizedBox(height: 24),
                            _buildErrorDisplay(widget.errorText!),
                          ],
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: widget.isLoading ? null : _submit,
                              child: widget.isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                : const Text('Login'),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          const SizedBox(height: 32),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
        );
      },
    );
  }

  Widget _buildOtpView() {
    return Container(
      color: BoostDriveTheme.backgroundDark,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onCancelOtp,
            ),
            title: const Text('Verify Identity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _otpFormKey,
                child: Column(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 80, color: BoostDriveTheme.primaryColor),
                    const SizedBox(height: 32),
                    const Text(
                      'Enter Verification Code',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'We have sent a 6-digit code to your email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If you don\'t see it, please check your spam folder.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 40),
                    
                    TextFormField(
                      controller: _otpController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 24),
                      ),
                      validator: (v) => v == null || v.length != 6 ? 'Enter 6-digit code' : null,
                    ),
                    
                    if (widget.errorText != null) ...[
                      const SizedBox(height: 24),
                      _buildErrorDisplay(widget.errorText!),
                    ],
                    
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: widget.isLoading ? null : _submit,
                        child: widget.isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Verify & Continue'),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: _secondsRemaining == 0 ? widget.onResendOtp : null,
                      child: Text(
                        _secondsRemaining > 0 
                          ? 'Resend code in ${_formatDuration(_secondsRemaining)}'
                          : 'Resend Verification Code',
                        style: TextStyle(
                          color: _secondsRemaining == 0 ? BoostDriveTheme.primaryColor : Colors.white38,
                          fontWeight: FontWeight.bold,
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

  Widget _buildSignUpView() {
    return Container(
      color: BoostDriveTheme.backgroundDark,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _isSignUp = false),
            ),
            title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          ),
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.primaryColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _signUpFormKey,
                child: Column(
                  children: [
                    const Text(
                      'Join BoostDrive',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose your primary role to get started.',
                      style: TextStyle(color: BoostDriveTheme.textDim, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),
                    
                    // Role Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildRoleCard('Customer', 'Owner, Seller or Driver', Icons.directions_car),
                        _buildRoleCard('Service Provider', 'Professional Services', Icons.build),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    _buildLabel('USERNAME (OPTIONAL)'),
                    TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecoration('username123', Icons.alternate_email),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildLabel('FULL NAME'),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('John Doe', Icons.person_outline),
                      style: const TextStyle(color: Colors.white),
                      validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildLabel('EMAIL ADDRESS'),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('john@example.com', Icons.mail_outline),
                      style: const TextStyle(color: Colors.white),
                      validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    
                    _buildLabel('PASSWORD'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('••••••••', Icons.lock_outline, isPassword: true).copyWith(
                        helperText: _isSignUp ? 'Min 8 chars: Upper, Lower, Number & Symbol' : null,
                        helperStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildLabel('CONFIRM PASSWORD'),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
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
                      height: 56,
                      child: ElevatedButton(
                        onPressed: widget.isLoading ? null : _submit,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Create Account'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
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

  Widget _buildLabel(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {bool isPassword = false}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.white24),
      suffixIcon: isPassword 
        ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.white24,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          )
        : null,
    );
  }

  Widget _buildRoleCard(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedRole == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? BoostDriveTheme.primaryColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BoostDriveTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BoostDriveTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: BoostDriveTheme.primaryColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(String label, dynamic icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Center(
          child: icon is IconData 
            ? Icon(icon, color: Colors.white, size: 24)
            : Text(
                icon as String,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
              ),
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
