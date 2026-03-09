import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'login_widget.dart';
import 'theme.dart';
import 'reset_password_page.dart';

class BoostLoginPage extends ConsumerStatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onClose;

  const BoostLoginPage({super.key, this.onLoginSuccess, this.onClose});

  @override
  ConsumerState<BoostLoginPage> createState() => _BoostLoginPageState();
}

class _BoostLoginPageState extends ConsumerState<BoostLoginPage> {
  bool _isLoading = false;
  String? _errorText;
  String? _verificationId;
  String? _pendingName;
  String? _pendingRole;
  bool _isPasswordReset = false;
  bool _isSignUp = false;

  String _getFriendlyErrorMessage(dynamic e) {
    if (e == null) return 'Unknown error occurred';
    final rawMessage = e.toString();
    final message = rawMessage.toLowerCase();
    
    // Handle JSON-serialized error messages (often from Supabase 500/400 errors)
    if (rawMessage.contains('"message":') || rawMessage.contains('"code":')) {
      try {
        final Map<String, dynamic> errorMap = jsonDecode(rawMessage);
        final msg = errorMap['message']?.toString() ?? '';
        final code = errorMap['code']?.toString() ?? '';
        
        if (msg.contains('sending magic link email') || 
            msg.contains('sending confirmation email') ||
            code == 'unexpected_failure') {
          return "We couldn't send the confirmation email. Please check that your email address is correct and try again.";
        }
        
        if (msg.isNotEmpty) return msg;
      } catch (_) {
        // Fallback to standard handling if JSON is malformed
      }
    }
    
    // 400 Bad Request – often from auth (e.g. token refresh failed, invalid grant)
    if (message.contains('400') || message.contains('bad request')) {
      if (message.contains('refresh') || message.contains('token') || message.contains('grant')) {
        return 'Your session may have expired. Please sign out and sign in again.';
      }
      return 'Request was invalid. Please try again or sign in again.';
    }
    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (message.contains('email or phone')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('password should contain') || message.contains('weak_password')) {
      return 'Password is too weak. It must be at least 8 characters and include uppercase, lowercase, numbers, and symbols.';
    }
    if (message.contains('user already exists') || message.contains('already registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('network') || message.contains('connection') ||
        message.contains('failed to fetch') || message.contains('clientexception') ||
        message.contains('connection_timed_out') || message.contains('name_not_resolved')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    if (message.contains('otp') || message.contains('verification code')) {
      return 'Incorrect or expired verification code.';
    }
    
    // Fallback for other Supabase/Auth exceptions
    if (e is AuthException) {
      return e.message;
    }

    if (e is PostgrestException) {
      return 'Database error: ${e.message}';
    }
    
    // Handle RetryableFetchException (often 500 or network errors from Supabase)
    if (rawMessage.contains('AuthRetryableFetchException')) {
      if (message.contains('sending confirmation email') || message.contains('unexpected_failure')) {
        return 'The email service is currently reaching its limit or improperly configured in Supabase. Please check your SMTP settings in the Supabase Dashboard.';
      }
      if (message.contains('failed to fetch') || message.contains('clientexception') ||
          message.contains('connection_timed_out') || message.contains('name_not_resolved')) {
        return 'Unable to connect. Please check your internet connection and try again.';
      }
      return 'Server connection error. Please try again in a few moments.';
    }

    if (rawMessage.length < 100) return rawMessage;
    
    return 'Something went wrong. Please try again later.';
  }

  void _login(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
      _isSignUp = false;
    });

    try {
      final authService = ref.read(authServiceProvider);
      // Use signInWithUsernameOrEmail to handle both email and username inputs
      await authService.signInWithUsernameOrEmail(identifier: email, password: password);
      
      if (widget.onLoginSuccess != null) {
        _showSuccessDialog('Login Successful', 'Welcome back to BoostDrive!', onDismiss: widget.onLoginSuccess);
      } else if (mounted) {
        _showSuccessDialog('Login Successful', 'Welcome back to BoostDrive!', onDismiss: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = _getFriendlyErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  void _signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? username,
  }) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
      _isSignUp = true;
      _pendingName = fullName;
      _pendingRole = role;
    });

    try {
      final normalizedRole = role.toLowerCase().replaceAll(' ', '_');
      final userService = ref.read(userServiceProvider);
      final duplicateError = await userService.checkDuplicateAccount(
        email: email,
        phone: phone,
      );

      if (duplicateError != null) {
        if (mounted) {
          setState(() {
            _errorText = duplicateError;
            _isLoading = false;
          });
        }
        return;
      }

      final authService = ref.read(authServiceProvider);
      final response = await authService.signUpWithEmailPassword(
        email: email,
        password: password,
        phone: phone,
        username: username,
        fullName: fullName,
        role: normalizedRole,
      );
      
      if (mounted) {
        if (response.session != null) {
          // Immediate sign in (Confirmation OFF)
          // Sync profile and roles
          final user = response.user!;
          await authService.updateProfile(userId: user.id, fullName: fullName);
          
          final normalizedRole = role.toLowerCase().replaceAll(' ', '_');
          bool isBuyer = normalizedRole == 'customer';
          bool isSeller = normalizedRole == 'customer' || normalizedRole == 'service_provider';
          
          await userService.updateRoles(
            uid: user.id,
            isBuyer: isBuyer,
            isSeller: isSeller,
            role: normalizedRole,
          );

          setState(() => _isLoading = false);
          if (widget.onLoginSuccess != null) {
            _showSuccessDialog(
              'Account Created', 
              'Your account has been successfully created.', 
              onDismiss: widget.onLoginSuccess
            );
          }
        } else {
          setState(() {
            _verificationId = email; // Store email for OTP verification
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = _getFriendlyErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  void _verifyOtp(String otp) async {
    if (_verificationId == null) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      bool success = false;
      
      final identifier = _verificationId?.trim() ?? '';
      
      // Determine if we should verify as email or phone based on the identifier format
      if (identifier.contains('@')) {
        success = await authService.verifyEmailCode(identifier, otp);
      } else if (identifier.isNotEmpty) {
        // Ensure phone number starts with + for Supabase
        String phoneId = identifier;
        if (!phoneId.startsWith('+')) {
           // We use the same formatting as AuthService to be consistent
           phoneId = authService.formatPhoneNumber(phoneId);
        }
        success = await authService.verifySmsCode(phoneId, otp);
      }
      
      if (success) {
        if (_isPasswordReset) {
          if (mounted) {
            // Navigate to Reset Password Page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordPage(
                  onPasswordChanged: () {
                    // Reset UI state
                    setState(() {
                      _verificationId = null;
                      _isPasswordReset = false;
                      _errorText = null;
                      _isLoading = false;
                    });
                    
                    if (widget.onLoginSuccess != null) {
                      widget.onLoginSuccess!();
                    } else if (mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            );
          }
          return;
        }

        final user = ref.read(currentUserProvider);
        if (user != null) {
          // Update profile with name
          if (_pendingName != null) {
            await authService.updateProfile(
              userId: user.id,
              fullName: _pendingName,
            );
          }
          
          // Update roles
          if (_pendingRole != null) {
            final normalizedRole = _pendingRole!.toLowerCase().replaceAll(' ', '_');
            final userSerivce = ref.read(userServiceProvider);
            bool isBuyer = normalizedRole == 'customer';
            bool isSeller = normalizedRole == 'customer' || normalizedRole == 'service_provider';
            await userSerivce.updateRoles(
              uid: user.id,
              isBuyer: isBuyer,
              isSeller: isSeller,
              role: normalizedRole,
            );
          }
        }
        
        if (widget.onLoginSuccess != null) {
          _showSuccessDialog('Account Created', 'Your account has been successfully created.', onDismiss: widget.onLoginSuccess);
        } else if (mounted) {
          _showSuccessDialog('Account Created', 'Your account has been successfully created.', onDismiss: () {
             if (Navigator.canPop(context)) {
               Navigator.pop(context);
             }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorText = "Invalid verification code";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = _getFriendlyErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  void _resendCode() {
    if (_verificationId != null) {
      final authService = ref.read(authServiceProvider);
      // Determine if we're resending for signup, recovery, or login
      OtpType type;
      if (_isPasswordReset) {
        type = OtpType.recovery;
      } else if (_isSignUp) {
        type = OtpType.signup;
      } else {
        type = OtpType.email;
      }
      
      authService.resendOtp(
        type: type,
        email: _verificationId!.contains('@') ? _verificationId : null,
        phone: !_verificationId!.contains('@') ? _verificationId : null,
      ).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification code resent!')),
          );
        }
      }).catchError((e) {
        if (mounted) setState(() => _errorText = _getFriendlyErrorMessage(e));
      });
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ForgotPasswordFlow(
        onSuccess: (email, otp) async {
          _verificationId = email;
          _isPasswordReset = true;
          _verifyOtp(otp);
        },
        getFriendlyError: _getFriendlyErrorMessage,
      ),
    );
  }

  void _signInWithGoogle() async {
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (!kIsWeb && mounted) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          _showSuccessDialog('Login Successful', 'Successfully signed in with Google.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorText = _getFriendlyErrorMessage(e));
    }
  }

  void _signInWithApple() async {
    try {
      await ref.read(authServiceProvider).signInWithApple();
      if (!kIsWeb && mounted) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          _showSuccessDialog('Login Successful', 'Successfully signed in with Apple.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorText = _getFriendlyErrorMessage(e));
    }
  }

  void _showSuccessDialog(String title, String message, {VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.green.withOpacity(0.5), width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (onDismiss != null) onDismiss();
                },
                child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Row(
        children: [
          // Left Side: Image
          Expanded(
            flex: 1,
            child: Container(
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
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Right Side: Login Widget
          Expanded(
            flex: 1,
            child: Container(
              color: BoostDriveTheme.backgroundDark,
              child: Stack(
                children: [
                  const Positioned(
                    top: 10,
                    right: 70,
                    child: SizedBox(
                      height: 48,
                      width: 48,
                      child: HtmlElementView(viewType: 'recaptcha-container'),
                    ),
                  ),
                  BoostLoginWidget(
                    onLogin: _login,
                    onSignUp: _signUp,
                    onVerifyOtp: _verifyOtp,
                    onResendOtp: _resendCode,
                    onCancelOtp: () {
                      setState(() {
                        _verificationId = null;
                        _errorText = null;
                        _isLoading = false;
                      });
                    },
                    onClose: widget.onClose,
                    onForgotPassword: _showForgotPasswordDialog,
                    onGoogleSignIn: _signInWithGoogle,
                    onAppleSignIn: _signInWithApple,
                    isLoading: _isLoading,
                    isOtpSent: _verificationId != null,
                    errorText: _errorText,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          BoostLoginWidget(
            onLogin: _login,
            onSignUp: _signUp,
            onVerifyOtp: _verifyOtp,
            onResendOtp: _resendCode,
            onCancelOtp: () {
              setState(() {
                _verificationId = null;
                _errorText = null;
                _isLoading = false;
              });
            },
            onClose: widget.onClose,
            onForgotPassword: _showForgotPasswordDialog,
            onGoogleSignIn: _signInWithGoogle,
            onAppleSignIn: _signInWithApple,
            isLoading: _isLoading,
            isOtpSent: _verificationId != null,
            errorText: _errorText,
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordFlow extends ConsumerStatefulWidget {
  final Function(String email, String otp) onSuccess;
  final String Function(dynamic) getFriendlyError;

  const _ForgotPasswordFlow({
    required this.onSuccess,
    required this.getFriendlyError,
  });

  @override
  ConsumerState<_ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends ConsumerState<_ForgotPasswordFlow> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).sendPasswordResetOtp(email);
      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = widget.getFriendlyError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyAndSubmit() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter 6-digit code');
      return;
    }

    Navigator.pop(context);
    widget.onSuccess(_emailController.text.trim(), otp);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BoostDriveTheme.backgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        _isOtpSent ? 'Verify Code' : 'Reset Password',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isOtpSent 
                  ? 'Enter the 6-digit code sent to ${_emailController.text}'
                  : 'Enter your email address to receive a verification code.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              
              if (!_isOtpSent)
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.white24),
                  ),
                )
              else
                TextFormField(
                  controller: _otpController,
                  style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(color: Colors.white10),
                    counterText: '',
                  ),
                ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: BoostDriveTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _isLoading ? null : (_isOtpSent ? _verifyAndSubmit : _sendCode),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_isOtpSent ? 'Verify' : 'Send Code'),
        ),
      ],
    );
  }
}
