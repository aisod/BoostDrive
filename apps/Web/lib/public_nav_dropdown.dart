import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nav_hover_underline.dart';

class BoostNavDropdownItem {
  final String label;
  final String route;

  const BoostNavDropdownItem({
    required this.label,
    required this.route,
  });
}

class BoostNavHoverDropdown extends StatefulWidget {
  final String label;
  final bool isActive;
  final List<BoostNavDropdownItem> items;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double menuWidth;

  const BoostNavHoverDropdown({
    super.key,
    required this.label,
    required this.isActive,
    required this.items,
    this.fontSize = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.menuWidth = 200,
  });

  @override
  State<BoostNavHoverDropdown> createState() => _BoostNavHoverDropdownState();
}

class _BoostNavHoverDropdownState extends State<BoostNavHoverDropdown> {
  static _BoostNavHoverDropdownState? _openDropdown;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _hoveringAnchor = false;
  bool _hoveringMenu = false;

  @override
  void dispose() {
    // Tear down overlay only — never setState during dispose (element may be defunct).
    _detachOverlay();
    super.dispose();
  }

  void _detachOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_openDropdown == this) {
      _openDropdown = null;
    }
  }

  void _removeOverlay() {
    _detachOverlay();
    if (mounted) setState(() {});
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    if (_openDropdown != null && _openDropdown != this) {
      _openDropdown!._removeOverlay();
    }
    _openDropdown = this;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: Offset.zero,
            child: MouseRegion(
              onEnter: (_) {
                _hoveringMenu = true;
              },
              onExit: (_) {
                _hoveringMenu = false;
                _scheduleClose();
              },
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: SizedBox(
                  width: widget.menuWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Invisible bridge so pointer can travel from nav link to menu.
                      const SizedBox(height: 6),
                      ...widget.items.map(_buildItem),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  void _scheduleClose() {
    Future.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      if (!_hoveringAnchor && !_hoveringMenu) {
        _removeOverlay();
      }
    });
  }

  void _onItemSelected(String route) {
    _removeOverlay();
    if (!mounted) return;
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.of(context).pushNamed(route);
  }

  Widget _buildItem(BoostNavDropdownItem item) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemSelected(item.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            item.label,
            style: GoogleFonts.montserrat(
              color: const Color(0xFF221C20),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _overlayEntry != null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: BoostNavHoverUnderline(
        isActive: widget.isActive || isOpen,
        padding: widget.padding,
        onTap: _showOverlay,
        onHoverChanged: (hovered) {
          _hoveringAnchor = hovered;
          if (hovered) {
            _showOverlay();
          } else {
            _scheduleClose();
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.montserrat(
                color: Colors.white.withValues(alpha: widget.isActive || isOpen ? 1 : 0.84),
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: widget.fontSize + 3,
              color: Colors.white.withValues(alpha: widget.isActive || isOpen ? 1 : 0.84),
            ),
          ],
        ),
      ),
    );
  }
}
