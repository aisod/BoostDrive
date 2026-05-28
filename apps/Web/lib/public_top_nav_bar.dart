import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boost_drive_web/authenticated_top_nav.dart';
import 'nav_hover_underline.dart';
import 'public_nav_dropdown.dart';

class BoostDrivePublicTopNavBar extends ConsumerWidget implements PreferredSizeWidget {
  final String activeRoute;
  final VoidCallback onAuthTap;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const BoostDrivePublicTopNavBar({
    super.key,
    required this.activeRoute,
    required this.onAuthTap,
    this.scaffoldKey,
  });

  static const List<_NavItemData> _guestItems = [
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

  List<Widget> _buildGuestNavLinks(BuildContext context, dynamic user) {
    return [
      ..._guestItems.map(
        (item) => _DesktopNavLink(
          label: item.label,
          isActive: activeRoute == item.route,
          fontSize: 15,
          horizontalPadding: 16,
          verticalPadding: 14,
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
      _DesktopNavDropdown(
        label: 'Company',
        isActive: _companyItems.any((item) => item.route == activeRoute),
        items: _companyItems,
        fontSize: 15,
        horizontalPadding: 16,
        verticalPadding: 14,
      ),
      _DesktopNavDropdown(
        label: 'Support',
        isActive: _supportItems.any((item) => item.route == activeRoute),
        items: _supportItems,
        fontSize: 15,
        horizontalPadding: 16,
        verticalPadding: 14,
      ),
    ];
  }

  List<Widget> _buildGuestTrailingActions(BuildContext context, WidgetRef ref, {required bool compact}) {
    return [
      _ThemeModeSwitch(compact: compact),
      SizedBox(width: compact ? 8 : 12),
      compact
          ? Padding(
              padding: const EdgeInsets.only(right: 14),
              child: TextButton(
                onPressed: onAuthTap,
                style: TextButton.styleFrom(
                  foregroundColor: BoostDriveTheme.primaryColor,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            )
          : Container(
              margin: const EdgeInsets.only(left: 0),
              child: ElevatedButton(
                onPressed: onAuthTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: BoostDriveTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  'Login',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final user = ref.watch(currentUserProvider);
    final isGuest = user == null;

    if (!isGuest) {
      return BoostDriveAuthenticatedTopNav(
        activeItem: authenticatedNavHighlightForRoute(activeRoute),
        scaffoldKey: scaffoldKey,
      );
    }

    if (isMobile) {
      return AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: scaffoldKey != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => scaffoldKey!.currentState?.openDrawer(),
              )
            : null,
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
        actions: _buildGuestTrailingActions(context, ref, compact: true),
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildGuestNavLinks(context, user),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildGuestTrailingActions(context, ref, compact: false),
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
        maxLines: 1,
        softWrap: false,
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
    return BoostNavHoverDropdown(
      label: label,
      isActive: isActive,
      fontSize: fontSize,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      items: items
          .map((item) => BoostNavDropdownItem(label: item.label, route: item.route))
          .toList(),
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
