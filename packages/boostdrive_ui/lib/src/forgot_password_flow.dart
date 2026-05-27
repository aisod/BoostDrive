import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'auth_design_tokens.dart';
import 'auth_ui_components.dart';
import 'dashboard_theme_toggle.dart';
import 'reset_password_page.dart';

const double _kForgotMargin = 20;
const double _kForgotRadiusCard = 24;
const double _kForgotRadiusControl = 12;

/// Full-screen forgot password flow (email → OTP) — Stitch Kinetic Precision.
class ForgotPasswordFlowPage extends ConsumerStatefulWidget {
  const ForgotPasswordFlowPage({
    super.key,
    this.onPasswordResetComplete,
    required this.getFriendlyError,
  });

  /// Called after the user saves a new password (web: close drawer + open dashboard).
  final VoidCallback? onPasswordResetComplete;
  final String Function(dynamic error) getFriendlyError;

  @override
  ConsumerState<ForgotPasswordFlowPage> createState() => _ForgotPasswordFlowPageState();
}

class _ForgotPasswordFlowPageState extends ConsumerState<ForgotPasswordFlowPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _error;
  Timer? _resendTimer;
  int _resendSecondsRemaining = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = 180);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSecondsRemaining > 0) {
        setState(() => _resendSecondsRemaining--);
      } else {
        timer.cancel();
        _resendTimer = null;
      }
    });
  }

  String _formatResendDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _resendCode() async {
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _otpController.clear();
        });
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = widget.getFriendlyError(e);
          _isLoading = false;
        });
      }
    }
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
      if (mounted) {
        setState(() {
          _isOtpSent = true;
          _isLoading = false;
        });
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = widget.getFriendlyError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyAndSubmit() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter 6-digit code');
      return;
    }

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
      final authService = ref.read(authServiceProvider);
      final success = await authService.verifyPasswordResetOtp(email, otp);
      if (!success) {
        throw Exception('Invalid verification code');
      }

      ref.read(passwordResetPendingProvider.notifier).state = true;

      if (!mounted) return;

      if (kIsWeb) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (resetContext) => ResetPasswordPage(
              onPasswordChanged: () {
                ref.read(passwordResetPendingProvider.notifier).state = false;
                widget.onPasswordResetComplete?.call();
              },
            ),
          ),
        );
      } else {
        Navigator.pop(context);
        widget.onPasswordResetComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = widget.getFriendlyError(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AuthDesignTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: _ForgotPasswordAppBar(tokens: tokens),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (tokens.isDark) _DarkBackdrop() else const _LightAtmosphere(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(_kForgotMargin, 8, _kForgotMargin, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      if (!tokens.isDark && !_isOtpSent) ...[
                        _LightHeroImage(),
                        const SizedBox(height: 24),
                      ],
                      _ForgotPasswordCard(
                        tokens: tokens,
                        isOtpSent: _isOtpSent,
                        email: _emailController.text.trim(),
                        emailController: _emailController,
                        otpController: _otpController,
                        error: _error,
                        isLoading: _isLoading,
                        onSendCode: _sendCode,
                        onVerify: _verifyAndSubmit,
                        onCancel: () => Navigator.pop(context),
                        onResendCode: _resendCode,
                        resendSecondsRemaining: _resendSecondsRemaining,
                        formatResendDuration: _formatResendDuration,
                      ),
                      if (!tokens.isDark && !_isOtpSent) ...[
                        const SizedBox(height: 24),
                        _SecurityFooter(tokens: tokens),
                      ] else if (tokens.isDark && !_isOtpSent) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Need help? Contact support from your profile settings.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: tokens.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ForgotPasswordAppBar({required this.tokens});

  final AuthDesignTokens tokens;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: tokens.isDark
          ? tokens.surface.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.85),
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: tokens.isDark ? 0.3 : 0.06),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: tokens.isDark ? tokens.primaryContainer : tokens.onSurfaceVariant,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, color: tokens.primaryContainer, size: 22),
          const SizedBox(width: 8),
          Text(
            'BOOSTDRIVE',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: tokens.primaryContainer,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: DashboardThemeToggle(compact: true, onColoredHeader: false),
        ),
      ],
    );
  }
}

class _LightAtmosphere extends StatelessWidget {
  const _LightAtmosphere();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        Positioned(
          top: -96,
          right: -96,
          child: Container(
            width: 384,
            height: 384,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF6600).withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.25,
          left: -96,
          child: Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF009CFC).withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkBackdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          AuthDesignTokens.forgotPasswordBackdropImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF09151B)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF09151B).withValues(alpha: 0.92),
                const Color(0xFF09151B).withValues(alpha: 0.95),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LightHeroImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.05,
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              AuthDesignTokens.forgotPasswordHeroImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE2E8F0)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFFF6600).withValues(alpha: 0.2),
                    Colors.transparent,
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

class _ForgotPasswordCard extends StatelessWidget {
  const _ForgotPasswordCard({
    required this.tokens,
    required this.isOtpSent,
    required this.email,
    required this.emailController,
    required this.otpController,
    required this.error,
    required this.isLoading,
    required this.onSendCode,
    required this.onVerify,
    required this.onCancel,
    this.onResendCode,
    this.resendSecondsRemaining = 0,
    this.formatResendDuration,
  });

  final AuthDesignTokens tokens;
  final bool isOtpSent;
  final String email;
  final TextEditingController emailController;
  final TextEditingController otpController;
  final String? error;
  final bool isLoading;
  final VoidCallback onSendCode;
  final VoidCallback onVerify;
  final VoidCallback onCancel;
  final Future<void> Function()? onResendCode;
  final int resendSecondsRemaining;
  final String Function(int totalSeconds)? formatResendDuration;

  @override
  Widget build(BuildContext context) {
    final cardDecoration = tokens.isDark
        ? BoxDecoration(
            color: const Color(0xFF162128).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(_kForgotRadiusCard),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          )
        : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kForgotRadiusCard),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          );

    return Container(
      width: double.infinity,
      decoration: cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (tokens.isDark)
            Positioned(
              top: -32,
              right: -32,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.primaryContainer.withValues(alpha: 0.1),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(isOtpSent ? 32 : 24),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isOtpSent ? 'Verify Code' : 'Reset Password',
            textAlign: tokens.isDark ? TextAlign.start : TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: tokens.isDark ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: tokens.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (isOtpSent)
            AuthOtpEmailSubtitle(
              tokens: tokens,
              email: email,
              textAlign: tokens.isDark ? TextAlign.start : TextAlign.center,
            )
          else
            Text(
              'Enter your email address to receive a verification code.',
              textAlign: tokens.isDark ? TextAlign.start : TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: tokens.isDark ? tokens.onSurfaceVariant : const Color(0xFF475569),
                height: 1.5,
              ),
            ),
          SizedBox(height: isOtpSent ? 32 : 24),
          if (!isOtpSent)
            _ForgotPasswordEmailField(
              tokens: tokens,
              controller: emailController,
            )
          else
            AuthOtpInput(tokens: tokens, controller: otpController),
          if (error != null) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(tokens: tokens, message: error!),
          ],
          SizedBox(height: isOtpSent ? 40 : 20),
          _PrimaryActionButton(
            label: isLoading
                ? (isOtpSent ? 'Verifying...' : 'Sending...')
                : (isOtpSent ? 'Verify' : 'Send Code'),
            isLoading: isLoading,
            onPressed: isLoading ? null : (isOtpSent ? onVerify : onSendCode),
          ),
          const SizedBox(height: 12),
          if (tokens.isDark)
            _SecondaryOutlineButton(label: 'Cancel', onPressed: isLoading ? null : onCancel)
          else
            TextButton(
              onPressed: isLoading ? null : onCancel,
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          if (isOtpSent && onResendCode != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: (resendSecondsRemaining == 0 && !isLoading)
                    ? () => onResendCode!()
                    : null,
                child: Text(
                  isLoading
                      ? 'Sending new code...'
                      : resendSecondsRemaining > 0
                          ? 'Resend code in ${formatResendDuration?.call(resendSecondsRemaining) ?? '${resendSecondsRemaining}s'}'
                          : "Didn't receive a code? Resend",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: (resendSecondsRemaining == 0 && !isLoading)
                        ? tokens.primaryContainer
                        : tokens.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
          if (isOtpSent) ...[
            const SizedBox(height: 48),
            Center(child: AuthTachometerHint(tokens: tokens)),
          ],
        ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordEmailField extends StatelessWidget {
  const _ForgotPasswordEmailField({
    required this.tokens,
    required this.controller,
  });

  final AuthDesignTokens tokens;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final fill = tokens.isDark ? const Color(0xFF101B22) : const Color(0xFFF1F5F9);
    final border = tokens.isDark ? const Color(0xFF1A262E) : const Color(0xFFCBD5E1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Email Address',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
              color: tokens.isDark ? tokens.onSurfaceVariant : const Color(0xFF334155),
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: GoogleFonts.manrope(fontSize: 16, color: tokens.onSurface),
          decoration: InputDecoration(
            hintText: tokens.isDark ? 'name@example.com' : 'driver@boostdrive.com',
            hintStyle: GoogleFonts.manrope(
              color: tokens.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            prefixIcon: Icon(
              Icons.mail_outline,
              color: tokens.primaryContainer.withValues(alpha: tokens.isDark ? 0.6 : 1),
              size: 22,
            ),
            filled: true,
            fillColor: fill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kForgotRadiusControl),
              borderSide: BorderSide(color: border, width: tokens.isDark ? 2 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kForgotRadiusControl),
              borderSide: const BorderSide(color: Color(0xFFFF6600), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6600),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFFFF6600).withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kForgotRadiusControl),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.02,
                ),
              ),
      ),
    );
  }
}

class _SecondaryOutlineButton extends StatelessWidget {
  const _SecondaryOutlineButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE3BFB2),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kForgotRadiusControl),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter({required this.tokens});

  final AuthDesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          'Your security is our top priority.',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.03,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
