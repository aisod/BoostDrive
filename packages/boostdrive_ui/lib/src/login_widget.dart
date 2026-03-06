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
                        image: DecorationImage(
                          image: NetworkImage("https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=2070&auto=format&fit=crop"),
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
                                const Icon(Icons.speed, color: Colors.white, size: 32),
                                const SizedBox(width: 8),
                                Text(
                                  'BoostDrive',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your Complete Automotive Ecosystem',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
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
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                                const SizedBox(height: 24),
                                
                                _buildLabel('Email'),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: _inputDecoration('Enter your email', Icons.mail_outline),
                                  style: const TextStyle(color: Colors.black),
                                  validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
                                ),
                                const SizedBox(height: 16),
                                
                                _buildLabel('Password'),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: _inputDecoration('Enter your password', Icons.lock_outline, isPassword: true),
                                  style: const TextStyle(color: Colors.black),
                                  validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
                                ),
                                
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: widget.onForgotPassword,
                                    child: const Text('Forgot Password?', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                
                                if (widget.errorText != null) ...[
                                  const SizedBox(height: 16),
                                  _buildErrorDisplay(widget.errorText!),
                                ],
                                
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: widget.isLoading ? null : _submit,
                                    child: widget.isLoading 
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                      : const Text('Login'),
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

        // Web-specific side panel layout (Full Split Screen)
        return Material(
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: const Color(0xFFF56A1B), // Vibrant orange background
            child: Row(
              children: [
                // Left Side: Dynamic Visuals
                Expanded(
                  flex: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage("https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=2070&auto=format&fit=crop"), // High-res Land Rover/Luxury vehicle style
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 60,
                        left: 40,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Complete\nAutomotive Ecosystem.',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Drive Smarter.',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right Side: Actionable Modal Card
                Expanded(
                  flex: 1,
                  child: Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // The Modal Card
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 400),
                                child: Card(
                                  elevation: 20,
                                  shadowColor: Colors.black.withOpacity(0.3),
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Form(
                                      key: _loginFormKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Logo
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.speed, color: Color(0xFFF56A1B), size: 32),
                                              const SizedBox(width: 12),
                                              Text(
                                                'BoostDrive',
                                                style: GoogleFonts.manrope(
                                                  color: const Color(0xFF1A1D1E),
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 32),
                                          Text(
                                            'Welcome Back',
                                            style: GoogleFonts.manrope(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF1A1D1E),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Sign in to your BoostDrive account',
                                            style: TextStyle(color: Colors.black54, fontSize: 14),
                                          ),
                                          const SizedBox(height: 32),
                                          
                                          _buildLabel('Email'),
                                          TextFormField(
                                            controller: _emailController,
                                            decoration: _inputDecoration('you@boostdrive.co', Icons.mail_outline),
                                            style: const TextStyle(color: Colors.black87),
                                            validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
                                          ),
                                          const SizedBox(height: 20),
                                          
                                          _buildLabel('Password'),
                                          TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            decoration: _inputDecoration('••••••••', Icons.lock_outline, isPassword: true),
                                            style: const TextStyle(color: Colors.black87),
                                            validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
                                          ),
                                          
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: widget.onForgotPassword,
                                              child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                          
                                          if (widget.errorText != null) ...[
                                            const SizedBox(height: 16),
                                            _buildErrorDisplay(widget.errorText!),
                                          ],
                                          
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF0066FF), // Vibrant blue
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                elevation: 0,
                                              ),
                                              onPressed: widget.isLoading ? null : _submit,
                                              child: widget.isLoading 
                                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                                : const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                      const SizedBox(width: 12),
                                                      const Icon(Icons.check, size: 18),
                                                    ],
                                                  ),
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Text("Don't have an account?", style: TextStyle(color: Colors.black54)),
                                              TextButton(
                                                onPressed: () => setState(() => _isSignUp = true),
                                                child: const Text('Sign Up', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Dealer Registration
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 400),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: TextButton(
                                    onPressed: () {}, // Dealer registration logic
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_outline, color: Colors.white, size: 18),
                                        SizedBox(width: 12),
                                        Text('Register as a Dealer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Admin Login
                              TextButton(
                                onPressed: () {},
                                child: const Text('Admin Login', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Close Button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          onPressed: _handleClose,
                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black12,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                      
                      // Copyright Info
                      const Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            '© 2026 BoostDrive, all rights reserved.',
                            style: TextStyle(color: Colors.white, fontSize: 11),
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
      },
    );
  }

  Widget _buildSignUpView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = kIsWeb;

        // Mobile-specific or small screen layout
        if (!isWeb || constraints.maxWidth <= 800) {
          return Container(
            color: BoostDriveTheme.backgroundDark,
            child: Column(
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: const SizedBox.shrink(),
                        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
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
                            style: const TextStyle(color: Colors.black),
                          ),
                          const SizedBox(height: 20),
                          
                          _buildLabel('FULL NAME'),
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration('John Doe', Icons.person_outline),
                            style: const TextStyle(color: Colors.black),
                            validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 20),
                          
                          _buildLabel('EMAIL ADDRESS'),
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('john@example.com', Icons.mail_outline),
                            style: const TextStyle(color: Colors.black),
                            validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                          ),
                          const SizedBox(height: 20),
                          
                          _buildLabel('PASSWORD'),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.black),
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
                            style: const TextStyle(color: Colors.black),
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

        // Web-specific side panel layout
        return Container(
          color: Colors.white,
          child: Row(
            children: [
              // Left Side: Hero Image
              if (constraints.maxWidth > 800)
                Expanded(
                  flex: 1,
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuCuAfnKgvQTFU8mdXJOK2OJrSdpcF6QMKvI6MtCv2T_PuowUTuBUYTxnovRCWOeMgWX20Fdpa6ngazsCa0_-jipGQq37sUi9ZbskUd73-uZkY2403hVqKMhDUMbsBkd0ziAG9ADrjcCgutXcPUyzcwP7yp9jbq_dO_Jma3E8CGlLryK-nu_xr2gv3rVZxLZj3aEas8jNt4q2C2SP0dCSVuSaqeNQnM_AVkU5VYP5KnqN10-3azckFoWgiw7Jkar42nxdR9aCLkX6Ps"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 40,
                        child: Row(
                          children: [
                            const Icon(Icons.speed, color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            Text(
                              'BoostDrive',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Right Side: Sign Up Form
              Expanded(
                flex: 1,
                child: Container(
                  color: const Color(0xFFF8F9FB),
                  child: Stack(
                    children: [
                      // Header with Close Button
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: _handleClose,
                                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  shape: const CircleBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(40, 100, 40, 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(color: Colors.black.withOpacity(0.05)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Form(
                                  key: _signUpFormKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Get Started',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1A1D1E),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Join the BoostDrive community',
                                        style: TextStyle(color: Colors.black54, fontSize: 14),
                                      ),
                                      const SizedBox(height: 32),
                                      
                      // Role Selection
                      Column(
                        children: [
                          _buildWebRoleCard('Customer', 'Owner, Seller or Driver', Icons.directions_car),
                          const SizedBox(height: 16),
                          _buildWebRoleCard('Service Provider', 'Professional Services', Icons.build),
                        ],
                      ),
                                      const SizedBox(height: 32),
                                      
                                      _buildLabel('Full Name'),
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: _inputDecoration('John Doe', Icons.person_outline),
                                        style: const TextStyle(color: Colors.black87),
                                        validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      _buildLabel('Email Address'),
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: _inputDecoration('john@example.com', Icons.mail_outline),
                                        style: const TextStyle(color: Colors.black87),
                                        validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      _buildLabel('Password'),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        decoration: _inputDecoration('••••••••', Icons.lock_outline, isPassword: true),
                                        style: const TextStyle(color: Colors.black87),
                                        validator: (v) => v == null || v.length < 8 ? 'Min 8 characters' : null,
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
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 0,
                                          ),
                                          onPressed: widget.isLoading ? null : _submit,
                                          child: widget.isLoading 
                                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                            : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 24),
                                Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text("Already have an account?", style: TextStyle(color: Colors.black54)),
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    final isWeb = kIsWeb;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.manrope(
          color: isWeb ? const Color(0xFF64748B) : BoostDriveTheme.textDim,
          fontSize: isWeb ? 11 : 10,
          fontWeight: isWeb ? FontWeight.w700 : FontWeight.w800,
          letterSpacing: isWeb ? 1.2 : 1.0,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {bool isPassword = false}) {
    final isWeb = kIsWeb;
    if (!isWeb) {
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

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BoostDriveTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: isPassword 
        ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          )
        : null,
    );
  }

  Widget _buildRoleCard(String title, String subtitle, IconData icon) {
    final isWeb = kIsWeb;
    bool isSelected = _selectedRole == title;

    if (!isWeb) {
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

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? BoostDriveTheme.primaryColor.withOpacity(0.05) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BoostDriveTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? BoostDriveTheme.primaryColor : const Color(0xFF64748B), size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? BoostDriveTheme.primaryColor : const Color(0xFF1A1D1E),
                fontWeight: FontWeight.bold,
                fontSize: 13,
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? BoostDriveTheme.primaryColor : Colors.black.withOpacity(0.1),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? BoostDriveTheme.primaryColor : const Color(0xFF64748B), size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? BoostDriveTheme.primaryColor : const Color(0xFF1A1D1E),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
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
