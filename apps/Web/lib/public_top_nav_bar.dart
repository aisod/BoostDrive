import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nav_hover_underline.dart';

class BoostDrivePublicTopNavBar extends ConsumerWidget implements PreferredSizeWidget {
  final String activeRoute;
  final VoidCallback onAuthTap;

  const BoostDrivePublicTopNavBar({
    super.key,
    required this.activeRoute,
    required this.onAuthTap,
  });

  // Keep the original field name for hot-reload compatibility.
  static const List<_NavItemData> _items = [
    _NavItemData(label: 'Marketplace', route: '/marketplace'),
    _NavItemData(label: 'Buy parts', route: '/buy-parts'),
    _NavItemData(label: 'Rent a car', route: '/rent-a-car'),
    _NavItemData(label: 'Sell your car', route: '/sell-your-car'),
    _NavItemData(label: 'New arrivals', route: '/new-arrivals'),
    _NavItemData(label: 'Find a Provider', route: '/find-provider'),
  ];

  static const List<_NavItemData> _companyItems = [
    _NavItemData(label: 'About us', route: '/about'),
    _NavItemData(label: 'Contact', route: '/contact'),
    _NavItemData(label: 'Careers', route: '/careers'),
    _NavItemData(label: 'Partner program', route: '/partner-program'),
  ];

  static const List<_NavItemData> _supportItems = [
    _NavItemData(label: 'Safety center', route: '/safety'),
    _NavItemData(label: 'Terms of service', route: '/terms'),
    _NavItemData(label: 'Privacy policy', route: '/privacy'),
    _NavItemData(label: 'FAQ', route: '/faq'),
  ];

  @override
  Size get preferredSize => const Size.fromHeight(72);

  void _goHome(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name == '/') return;
    Navigator.of(context).pushNamed('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final user = ref.watch(currentUserProvider);
    final isGuest = user == null;

    if (isMobile) {
      return AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        titleSpacing: 16,
        title: GestureDetector(
          onTap: () => _goHome(context),
          child: const Text(
            'BoostDrive',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.8,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          const SizedBox(width: 4),
          const _ThemeModeSwitch(compact: true),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: TextButton(
              onPressed: () {
                if (user == null) {
                  onAuthTap();
                } else {
                  ref.read(authServiceProvider).signOut();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: BoostDriveTheme.primaryColor,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: const StadiumBorder(),
              ),
              child: Text(
                user == null ? 'Login' : 'Log Out',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    return Material(
      color: BoostDriveTheme.primaryColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _goHome(context),
                    child: Text(
                      'BoostDrive',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ..._items.map(
                                  (item) => _DesktopNavLink(
                                    label: item.label,
                                    isActive: activeRoute == item.route,
                                    fontSize: 16,
                                    horizontalPadding: 16,
                                    verticalPadding: 20,
                                    onTap: () {
                                      if (item.route == '/sell-your-car' && user == null) {
                                        onAuthTap();
                                        return;
                                      }
                                      if (activeRoute == item.route) return;
                                      Navigator.of(context).pushNamed(item.route);
                                    },
                                  ),
                                ),
                                if (isGuest) ...[
                                  _DesktopNavDropdown(
                                    label: 'Company',
                                    isActive: _companyItems.any((item) => item.route == activeRoute),
                                    items: _companyItems,
                                    fontSize: 16,
                                    horizontalPadding: 16,
                                    verticalPadding: 20,
                                  ),
                                  _DesktopNavDropdown(
                                    label: 'Support',
                                    isActive: _supportItems.any((item) => item.route == activeRoute),
                                    items: _supportItems,
                                    fontSize: 16,
                                    horizontalPadding: 16,
                                    verticalPadding: 20,
                                  ),
                                ],
                              ],
                            ),
                          )
                  ),
                ),
                const SizedBox(width: 12),
                const _ThemeModeSwitch(),
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: ElevatedButton(
                  onPressed: () {
                    if (user == null) {
                      onAuthTap();
                    } else {
                      ref.read(authServiceProvider).signOut();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: BoostDriveTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    user == null ? 'Login' : 'Log Out',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopNavLink extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;

  const _DesktopNavLink({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return BoostNavHoverUnderline(
      isActive: isActive,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: Colors.white.withValues(alpha: isActive ? 1 : 0.84),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DesktopNavDropdown extends StatelessWidget {
  final String label;
  final bool isActive;
  final List<_NavItemData> items;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;

  const _DesktopNavDropdown({
    required this.label,
    required this.isActive,
    required this.items,
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: label,
      offset: const Offset(0, 34),
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (route) {
        if (route == ModalRoute.of(context)?.settings.name) return;
        Navigator.of(context).pushNamed(route);
      },
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item.route,
              child: Text(
                item.label,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF221C20),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
      child: BoostNavHoverUnderline(
        isActive: isActive,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white.withValues(alpha: isActive ? 1 : 0.84),
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: fontSize + 3,
              color: Colors.white.withValues(alpha: isActive ? 1 : 0.84),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSwitch extends ConsumerWidget {
  final bool compact;

  const _ThemeModeSwitch({this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final trackWidth = compact ? 40.0 : 46.0;
    final trackHeight = compact ? 22.0 : 26.0;
    final knobSize = compact ? 16.0 : 20.0;

    return Tooltip(
      message: 'Switch to ${isDarkMode ? 'light' : 'dark'} mode',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            final notifier = ref.read(themeModeProvider.notifier);
            notifier.state = isDarkMode ? ThemeMode.light : ThemeMode.dark;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: trackWidth,
            height: trackHeight,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDarkMode ? BoostDriveTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.18) : const Color(0xFF221C20),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: BoostDriveTheme.primaryColor.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white : const Color(0xFF221C20),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final String route;

  const _NavItemData({
    required this.label,
    required this.route,
  });
}
