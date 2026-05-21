import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_design_tokens.dart';

class AuthSplitLayout extends StatelessWidget {
  final AuthDesignTokens tokens;
  final String heroImageUrl;
  final Widget heroContent;
  final Widget formContent;
  final VoidCallback? onClose;
  final Widget? topRightOverlay;

  const AuthSplitLayout({
    super.key,
    required this.tokens,
    required this.heroImageUrl,
    required this.heroContent,
    required this.formContent,
    this.onClose,
    this.topRightOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 900;

        if (isStacked) {
          return ColoredBox(
            color: tokens.background,
            child: Column(
              children: [
                SizedBox(
                  height: constraints.maxHeight * 0.35,
                  width: double.infinity,
                  child: _HeroPanel(
                    tokens: tokens,
                    imageUrl: heroImageUrl,
                    child: heroContent,
                    compact: true,
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: tokens.isDark ? tokens.surfaceContainerLow : tokens.surfaceContainerLow,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                          child: formContent,
                        ),
                        if (onClose != null)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _CloseButton(onPressed: onClose!, tokens: tokens),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ColoredBox(
          color: tokens.background,
          child: Row(
            children: [
              Expanded(
                child: _HeroPanel(
                  tokens: tokens,
                  imageUrl: heroImageUrl,
                  child: heroContent,
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: tokens.isDark ? tokens.surfaceContainerLow : tokens.surfaceContainerLow,
                  child: Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: formContent,
                          ),
                        ),
                      ),
                      if (topRightOverlay != null)
                        Positioned(top: 16, right: 16, child: topRightOverlay!),
                      if (onClose != null)
                        Positioned(
                          top: 24,
                          right: 24,
                          child: _CloseButton(onPressed: onClose!, tokens: tokens),
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
}

class _HeroPanel extends StatelessWidget {
  final AuthDesignTokens tokens;
  final String imageUrl;
  final Widget child;
  final bool compact;

  const _HeroPanel({
    required this.tokens,
    required this.imageUrl,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(color: tokens.surfaceContainerHighest),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                tokens.isDark
                    ? const Color(0xE6050F16)
                    : const Color(0xCC191C1C),
                tokens.isDark
                    ? const Color(0x66050F16)
                    : const Color(0x4D191C1C),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          left: compact ? 20 : 40,
          right: compact ? 20 : 40,
          bottom: compact ? 24 : 40,
          child: child,
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final AuthDesignTokens tokens;

  const _CloseButton({required this.onPressed, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.close, color: tokens.onSurface.withValues(alpha: 0.7)),
      style: IconButton.styleFrom(
        backgroundColor: tokens.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class AuthPageHeader extends StatelessWidget {
  final AuthDesignTokens tokens;
  final String title;
  final String subtitle;

  const AuthPageHeader({
    super.key,
    required this.tokens,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: tokens.onSurface,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: tokens.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  final AuthDesignTokens tokens;
  final String label;

  const AuthFieldLabel({super.key, required this.tokens, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: tokens.onSurface,
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final AuthDesignTokens tokens;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final bool showVisibilityToggle;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;
  final String? prefixText;
  final String? Function(String?)? validator;
  final bool pillShape;

  const AuthTextField({
    super.key,
    required this.tokens,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.showVisibilityToggle = false,
    this.onToggleVisibility,
    this.keyboardType,
    this.prefixText,
    this.validator,
    this.pillShape = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = pillShape ? 999.0 : 16.0;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.montserrat(
        color: tokens.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        prefixStyle: GoogleFonts.montserrat(color: tokens.onSurfaceVariant, fontSize: 16),
        prefixIcon: Icon(icon, color: tokens.onSurfaceVariant.withValues(alpha: 0.6), size: 20),
        suffixIcon: showVisibilityToggle
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: tokens.onSurfaceVariant.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: tokens.isDark ? tokens.surfaceContainerHighest : tokens.surfaceContainerHighest,
        hintStyle: GoogleFonts.montserrat(
          color: tokens.onSurfaceVariant.withValues(alpha: 0.45),
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: tokens.isDark ? Colors.transparent : tokens.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: tokens.isDark ? Colors.transparent : tokens.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: tokens.primaryContainer, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: tokens.error.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final AuthDesignTokens tokens;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;

  const AuthPrimaryButton({
    super.key,
    required this.tokens,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primaryContainer,
          foregroundColor: tokens.onPrimaryContainer,
          elevation: tokens.isDark ? 4 : 2,
          shadowColor: tokens.primaryContainer.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: tokens.onPrimaryContainer,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final AuthDesignTokens tokens;
  final String message;

  const AuthErrorBanner({super.key, required this.tokens, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: tokens.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(
                color: tokens.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthOtpInput extends StatefulWidget {
  final AuthDesignTokens tokens;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const AuthOtpInput({
    super.key,
    required this.tokens,
    required this.controller,
    this.validator,
  });

  @override
  State<AuthOtpInput> createState() => _AuthOtpInputState();
}

class _AuthOtpInputState extends State<AuthOtpInput> {
  late final List<TextEditingController> _digitControllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _digitControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    final existing = widget.controller.text;
    for (var i = 0; i < 6 && i < existing.length; i++) {
      _digitControllers[i].text = existing[i];
    }
  }

  @override
  void dispose() {
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _syncParent() {
    widget.controller.text = _digitControllers.map((c) => c.text).join();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final chars = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (var i = 0; i < chars.length && index + i < 6; i++) {
        _digitControllers[index + i].text = chars[i];
      }
      final next = (index + chars.length).clamp(0, 5);
      _focusNodes[next].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    _syncParent();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 52,
                  height: 64,
                  child: TextField(
                    controller: _digitControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: widget.tokens.onSurface,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: widget.tokens.surfaceContainer,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.tokens.outlineVariant, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.tokens.outlineVariant, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.tokens.primaryContainer, width: 2),
                      ),
                    ),
                    onChanged: (v) => _onChanged(index, v),
                    onTap: () => _digitControllers[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _digitControllers[index].text.length,
                    ),
                    onSubmitted: (_) {
                      if (index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  state.errorText ?? '',
                  style: GoogleFonts.montserrat(color: widget.tokens.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
