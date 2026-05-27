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
import 'forgot_password_flow.dart';

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
  String? _pendingBusinessContactNumber;
  String? _pendingPrimaryServiceCategory;
  String? _pendingUsername;
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
    // 404 from Supabase auth (e.g. "Received an empty response with status code 404")
    if (message.contains('status code 404') || (message.contains(' 404') && message.contains('empty response'))) {
      return 'We could not reach the BoostDrive server. Please try again in a few minutes.';
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
    if (message.contains('rate limit') ||
        message.contains('too many') ||
        message.contains('over_email_send_rate_limit') ||
        message.contains('over_sms_send_rate_limit')) {
      return 'Too many code requests. Please wait a few minutes before resending.';
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

  void _finishAuthenticatedSession({
    String successTitle = 'Login Successful',
    String successMessage = 'Welcome back to BoostDrive!',
  }) {
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
      return;
    }

    _showSuccessDialog(successTitle, successMessage, onDismiss: () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
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
      _finishAuthenticatedSession();
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
    String? primaryServiceCategory,
  }) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
      _isSignUp = true;
      _pendingName = fullName;
      _pendingRole = role;
      _pendingBusinessContactNumber = role.toLowerCase().contains('service_provider') ? phone : null;
      _pendingPrimaryServiceCategory = primaryServiceCategory;
      _pendingUsername = username;
    });

    try {
      final originalNormalizedRole = role.toLowerCase().replaceAll(' ', '_');
      final isCustomerSeller = originalNormalizedRole == 'customer_/_seller';
      final dbRole = isCustomerSeller ? 'customer' : originalNormalizedRole;

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
        role: dbRole,
      );
      
      if (mounted) {
        if (response.session != null) {
          // Immediate sign in (Confirmation OFF)
          // Sync profile and roles
          final user = response.user!;
          if (dbRole == 'service_provider') {
            await authService.updateProfile(
              userId: user.id,
              fullName: fullName, // stored into full_name (used as shop display name)
              username: username,
              businessContactNumber: phone,
              tradingName: fullName,
              primaryServiceCategory: primaryServiceCategory,
            );
          } else {
            await authService.updateProfile(
              userId: user.id,
              fullName: fullName,
              username: username,
            );
          }
          
          bool isBuyer = isCustomerSeller || dbRole == 'customer';
          // Providers should NOT be treated as sellers.
          bool isSeller = isCustomerSeller || dbRole == 'seller';
          
          await userService.updateRoles(
            uid: user.id,
            isBuyer: isBuyer,
            isSeller: isSeller,
            role: dbRole,
          );

          setState(() => _isLoading = false);
          _finishAuthenticatedSession(
            successTitle: 'Account Created',
            successMessage: 'Your account has been successfully created.',
          );
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
        success = _isPasswordReset
            ? await authService.verifyPasswordResetOtp(identifier, otp)
            : await authService.verifyEmailCode(identifier, otp);
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
          ref.read(passwordResetPendingProvider.notifier).state = true;

          if (mounted) {
            setState(() {
              _verificationId = null;
              _isPasswordReset = false;
              _errorText = null;
              _isLoading = false;
            });

            if (kIsWeb) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ResetPasswordPage(
                    onPasswordChanged: () {
                      ref.read(passwordResetPendingProvider.notifier).state = false;
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
          }
          return;
        }

        final user = ref.read(currentUserProvider);
        if (user != null) {
          // Update profile with name
          if (_pendingName != null) {
            if (_pendingRole != null && _pendingRole!.toLowerCase().replaceAll(' ', '_') == 'service_provider') {
              await authService.updateProfile(
                userId: user.id,
                fullName: _pendingName,
                username: _pendingUsername,
                businessContactNumber: _pendingBusinessContactNumber,
                tradingName: _pendingName,
                primaryServiceCategory: _pendingPrimaryServiceCategory,
              );
            } else {
              await authService.updateProfile(
                userId: user.id,
                fullName: _pendingName,
                username: _pendingUsername,
              );
            }
          }
          
          // Update roles
          if (_pendingRole != null) {
            final originalNormalizedRole = _pendingRole!.toLowerCase().replaceAll(' ', '_');
            final isCustomerSeller = originalNormalizedRole == 'customer_/_seller';
            final dbRole = isCustomerSeller ? 'customer' : originalNormalizedRole;
            final userSerivce = ref.read(userServiceProvider);
            bool isBuyer = isCustomerSeller || dbRole == 'customer';
            // Providers should NOT be treated as sellers.
            bool isSeller = isCustomerSeller || dbRole == 'seller';
            await userSerivce.updateRoles(
              uid: user.id,
              isBuyer: isBuyer,
              isSeller: isSeller,
              role: dbRole,
            );
          }
        }
        
        if (widget.onLoginSuccess != null) {
          _finishAuthenticatedSession(
            successTitle: 'Account Created',
            successMessage: 'Your account has been successfully created.',
          );
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

  Future<void> _resendCode() async {
    final identifier = _verificationId?.trim();
    if (identifier == null || identifier.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(authServiceProvider).resendVerificationCode(
        identifier: identifier,
        isSignUp: _isSignUp,
        isPasswordReset: _isPasswordReset,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent!')),
        );
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

  void _showForgotPasswordDialog() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ForgotPasswordFlowPage(
          onPasswordResetComplete: () {
            if (widget.onLoginSuccess != null) {
              widget.onLoginSuccess!();
            }
          },
          getFriendlyError: _getFriendlyErrorMessage,
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, {VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.green.withValues(alpha: 0.5), width: 2),
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
      return Stack(
        fit: StackFit.expand,
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
            isLoading: _isLoading,
            isOtpSent: _verificationId != null,
            errorText: _errorText,
          ),
          const Positioned(
            top: 10,
            right: 70,
            child: SizedBox(
              height: 48,
              width: 48,
              child: HtmlElementView(viewType: 'recaptcha-container'),
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
            isLoading: _isLoading,
            isOtpSent: _verificationId != null,
            errorText: _errorText,
          ),
        ],
      ),
    );
  }
}
