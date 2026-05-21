import 'package:flutter/material.dart';

class BoostNavHoverUnderline extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final EdgeInsetsGeometry padding;
  final Color underlineColor;
  final double underlineHeight;
  final double underlineSpacing;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHoverChanged;
  final MouseCursor cursor;

  const BoostNavHoverUnderline({
    super.key,
    required this.child,
    this.isActive = false,
    this.padding = EdgeInsets.zero,
    this.underlineColor = Colors.white,
    this.underlineHeight = 1.2,
    this.underlineSpacing = 0,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
    this.onTap,
    this.onHoverChanged,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<BoostNavHoverUnderline> createState() => _BoostNavHoverUnderlineState();
}

class _BoostNavHoverUnderlineState extends State<BoostNavHoverUnderline> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
    widget.onHoverChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final showHighlight = widget.isActive || _isHovered;

    // Stack sizes to the label; Positioned.fill animates a center-expanding pill
    // without IntrinsicWidth (which breaks inside horizontal scroll rows).
    final content = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: showHighlight ? 1 : 0),
                  duration: widget.duration,
                  curve: widget.curve,
                  builder: (context, value, _) {
                    final shadowAlpha = 0.18 * value;
                    const backgroundColor = Color(0x14FFFFFF);
                    return Center(
                      child: Opacity(
                        opacity: value <= 0.001 ? 0 : 1,
                        child: SizedBox(
                          width: constraints.maxWidth * value,
                          height: constraints.maxHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color.lerp(Colors.transparent, backgroundColor, value),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: widget.underlineColor,
                                width: widget.underlineHeight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.underlineColor.withValues(alpha: shadowAlpha),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ],
    );

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: widget.onTap == null
          ? content
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: content,
            ),
    );
  }
}
