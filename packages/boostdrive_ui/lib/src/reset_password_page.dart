import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'auth_design_tokens.dart';
import 'auth_ui_components.dart';
import 'dashboard_theme_toggle.dart';

const double _kResetMargin = 20;
const double _kResetRadiusCard = 24;
const double _kResetRadiusControl = 12;

/// Set-new-password screen after OTP verification (Kinetic Precision).
class ResetPasswordPage extends ConsumerStatefulWidget {
  final VoidCallback onPasswordChanged;
  final bool popOnSuccess;

  const ResetPasswordPage({
    super.key,
    required this.onPasswordChanged,
    this.popOnSuccess = true,
  });

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    if (widget.popOnSuccess && Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    ref.read(passwordResetPendingProvider.notifier).state = false;
    await ref.read(authServiceProvider).signOut();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorText = null;
      });

      try {
        await ref.read(authServiceProvider).updatePassword(_passwordController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          if (widget.popOnSuccess && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          widget.onPasswordChanged();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorText = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AuthDesignTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: _ResetPasswordAppBar(tokens: tokens),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (tokens.isDark) const _ResetDarkBackdrop() else const _ResetLightAtmosphere(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(_kResetMargin, 8, _kResetMargin, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: _ResetPasswordCard(
                      tokens: tokens,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      obscurePassword: _obscurePassword,
                      onToggleVisibility: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      errorText: _errorText,
                      isLoading: _isLoading,
                      onSubmit: _submit,
                      onCancel: _handleCancel,
                    ),
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

class _ResetPasswordAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ResetPasswordAppBar({required this.tokens});

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
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: DashboardThemeToggle(compact: true, onColoredHeader: false),
        ),
      ],
    );
  }
}

class _ResetLightAtmosphere extends StatelessWidget {
  const _ResetLightAtmosphere();

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
        Center(
          child: Opacity(
            opacity: 0.05,
            child: Container(
              width: size.width * 1.4,
              height: size.height * 1.4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFF6600), Colors.transparent],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetDarkBackdrop extends StatelessWidget {
  const _ResetDarkBackdrop();

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

class _ResetPasswordCard extends StatelessWidget {
  const _ResetPasswordCard({
    required this.tokens,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.onToggleVisibility,
    required this.errorText,
    required this.isLoading,
    required this.onSubmit,
    required this.onCancel,
  });

  final AuthDesignTokens tokens;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final VoidCallback onToggleVisibility;
  final String? errorText;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cardDecoration = tokens.isDark
        ? BoxDecoration(
            color: const Color(0xFF162128).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(_kResetRadiusCard),
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
            borderRadius: BorderRadius.circular(_kResetRadiusCard),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 24,
                offset: const Offset(0, 8),
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
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_reset,
                  size: 48,
                  color: tokens.primaryContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  'Create New Password',
                  textAlign: tokens.isDark ? TextAlign.start : TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: tokens.isDark ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: tokens.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your new password below.',
                  textAlign: tokens.isDark ? TextAlign.start : TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: tokens.isDark ? tokens.onSurfaceVariant : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _ResetPasswordField(
                  tokens: tokens,
                  label: 'NEW PASSWORD',
                  controller: passwordController,
                  obscureText: obscurePassword,
                  onToggleVisibility: onToggleVisibility,
                  hint: 'New Password',
                  validator: (v) =>
                      v == null || v.length < 8 ? 'Password must be at least 8 characters' : null,
                ),
                const SizedBox(height: 20),
                _ResetPasswordField(
                  tokens: tokens,
                  label: 'CONFIRM PASSWORD',
                  controller: confirmPasswordController,
                  obscureText: obscurePassword,
                  onToggleVisibility: onToggleVisibility,
                  hint: 'Confirm Password',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(tokens: tokens, message: errorText!),
                ],
                const SizedBox(height: 32),
                AuthPrimaryButton(
                  tokens: tokens,
                  label: 'Save New Password',
                  compact: true,
                  isLoading: isLoading,
                  onPressed: onSubmit,
                ),
                const SizedBox(height: 12),
                if (tokens.isDark)
                  _ResetCancelOutlineButton(
                    onPressed: isLoading ? null : onCancel,
                  )
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
                const SizedBox(height: 48),
                Center(child: AuthTachometerHint(tokens: tokens)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordField extends StatelessWidget {
  const _ResetPasswordField({
    required this.tokens,
    required this.label,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.hint,
    this.validator,
  });

  final AuthDesignTokens tokens;
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final fill = tokens.isDark ? const Color(0xFF101B22) : const Color(0xFFF8FAFC);
    final border = tokens.isDark ? const Color(0xFF1A262E) : const Color(0xFFCBD5E1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
              color: tokens.isDark ? tokens.onSurfaceVariant : const Color(0xFF334155),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.manrope(fontSize: 16, color: tokens.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(
              color: tokens.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: tokens.primaryContainer.withValues(alpha: tokens.isDark ? 0.6 : 1),
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: tokens.onSurfaceVariant.withValues(alpha: 0.7),
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: fill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kResetRadiusControl),
              borderSide: BorderSide(color: border, width: tokens.isDark ? 2 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kResetRadiusControl),
              borderSide: const BorderSide(color: Color(0xFFFF6600), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kResetRadiusControl),
              borderSide: BorderSide(color: tokens.error.withValues(alpha: 0.7)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kResetRadiusControl),
              borderSide: BorderSide(color: tokens.error.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetCancelOutlineButton extends StatelessWidget {
  const _ResetCancelOutlineButton({required this.onPressed});

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
            borderRadius: BorderRadius.circular(_kResetRadiusControl),
          ),
        ),
        child: Text(
          'Cancel',
          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
