import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boost_drive_web/dashboard_router.dart';
import 'package:boost_drive_web/messages_page.dart';
import 'package:boost_drive_web/public_nav_auth_widgets.dart';
import 'nav_hover_underline.dart';

/// Primary nav highlight for logged-in customer/seller chrome.
enum AuthenticatedNavHighlight {
  marketplace,
  findProvider,
  messages,
  myListings,
  rentals,
  dashboard,
}

/// Maps a public page route name to the nav highlight (if any).
AuthenticatedNavHighlight? authenticatedNavHighlightForRoute(String route) {
  switch (route) {
    case '/marketplace':
    case '/buy-parts':
    case '/sell-your-car':
    case '/new-arrivals':
      return AuthenticatedNavHighlight.marketplace;
    case '/rent-a-car':
      return AuthenticatedNavHighlight.rentals;
    case '/find-provider':
      return AuthenticatedNavHighlight.findProvider;
    default:
      return null;
  }
}

/// Orange logged-in top bar: MARKETPLACE · FIND A PROVIDER · MESSAGES · RENTALS · DASHBOARD + bell · profile · theme · Log Out.
class BoostDriveAuthenticatedTopNav extends ConsumerWidget implements PreferredSizeWidget {
  final AuthenticatedNavHighlight? activeItem;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool showMenuButton;

  const BoostDriveAuthenticatedTopNav({
    super.key,
    this.activeItem,
    this.scaffoldKey,
    this.showMenuButton = false,
  });

  static const double barHeight = 72;

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  void _goHome(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name == '/') return;
    Navigator.of(context).pushNamed('/');
  }

  void _openMarketplace(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name == '/marketplace') return;
    Navigator.of(context).pushNamed('/marketplace');
  }

  void _openMessages(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagesPage()));
  }

  void _openRentals(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name == '/rent-a-car') return;
    Navigator.of(context).pushNamed('/rent-a-car');
  }

  void _openDashboard(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final profile = ref.read(userProfileProvider(user.id)).value;
    if (profile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => dashboardWidgetForProfile(profile)),
    );
  }

  void _openMobileNavMenu(
    BuildContext context,
    WidgetRef ref, {
    required UserProfile? profile,
    required bool showSellerLinks,
    required bool isServiceProvider,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Navigation menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: Material(
              color: Colors.white,
              elevation: 12,
              child: SizedBox(
                width: 300,
                height: MediaQuery.sizeOf(dialogContext).height,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                        color: BoostDriveTheme.primaryColor,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Menu',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            _MobileNavMenuTile(
                              label: 'Marketplace',
                              isActive: activeItem == AuthenticatedNavHighlight.marketplace,
                              onTap: () {
                                Navigator.pop(dialogContext);
                                _openMarketplace(context);
                              },
                            ),
                            if (!isServiceProvider)
                              _MobileNavMenuTile(
                                label: 'Find a Provider',
                                isActive: activeItem == AuthenticatedNavHighlight.findProvider,
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  if (profile != null) {
                                    openFindProviderOrHub(context, ref, profile);
                                  } else if (ModalRoute.of(context)?.settings.name != '/find-provider') {
                                    Navigator.of(context).pushNamed('/find-provider');
                                  }
                                },
                              ),
                            _MobileNavMenuTile(
                              label: 'Messages',
                              isActive: activeItem == AuthenticatedNavHighlight.messages,
                              onTap: () {
                                Navigator.pop(dialogContext);
                                _openMessages(context);
                              },
                            ),
                            if (showSellerLinks)
                              _MobileNavMenuTile(
                                label: 'Rentals',
                                isActive: activeItem == AuthenticatedNavHighlight.rentals,
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  _openRentals(context);
                                },
                              ),
                            _MobileNavMenuTile(
                              label: 'Dashboard',
                              isActive: activeItem == AuthenticatedNavHighlight.dashboard,
                              onTap: () {
                                Navigator.pop(dialogContext);
                                _openDashboard(context, ref);
                              },
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final isMobile = MediaQuery.sizeOf(context).width < 900;
    final profile = ref.watch(userProfileProvider(user.id)).value;
    final showSellerLinks = profile != null && isMarketplaceSeller(profile);
    // Service providers use the portal sidebar; no Find a Provider / Services Requested link.
    final isServiceProvider =
        profile != null && (profile.isProvider || isWebProviderRole(profile.role));

    return Material(
      color: BoostDriveTheme.primaryColor,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: barHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
            child: Row(
              children: [
                if (showMenuButton && scaffoldKey != null)
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    tooltip: 'Menu',
                    onPressed: () => scaffoldKey!.currentState?.openDrawer(),
                  ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _goHome(context),
                    child: Text(
                      'BoostDrive',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w900,
                        fontSize: isMobile ? 22 : 24,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AuthNavLink(
                              label: 'MARKETPLACE',
                              isActive: activeItem == AuthenticatedNavHighlight.marketplace,
                              onTap: () => _openMarketplace(context),
                            ),
                            if (!isServiceProvider)
                              _AuthNavLink(
                                label: 'FIND A PROVIDER',
                                isActive: activeItem == AuthenticatedNavHighlight.findProvider,
                                onTap: () {
                                  if (profile != null) {
                                    openFindProviderOrHub(context, ref, profile);
                                  } else if (ModalRoute.of(context)?.settings.name != '/find-provider') {
                                    Navigator.of(context).pushNamed('/find-provider');
                                  }
                                },
                              ),
                            _AuthNavLink(
                              label: 'MESSAGES',
                              isActive: activeItem == AuthenticatedNavHighlight.messages,
                              onTap: () => _openMessages(context),
                            ),
                            if (showSellerLinks)
                              _AuthNavLink(
                                label: 'RENTALS',
                                isActive: activeItem == AuthenticatedNavHighlight.rentals,
                                onTap: () => _openRentals(context),
                              ),
                            _AuthNavLink(
                              label: 'DASHBOARD',
                              isActive: activeItem == AuthenticatedNavHighlight.dashboard,
                              onTap: () => _openDashboard(context, ref),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (isMobile)
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    tooltip: 'Navigation menu',
                    onPressed: () => _openMobileNavMenu(
                      context,
                      ref,
                      profile: profile,
                      showSellerLinks: showSellerLinks,
                      isServiceProvider: isServiceProvider,
                    ),
                  ),
                PublicNavNotificationBell(userId: user.id, compact: isMobile),
                PublicNavProfileAvatar(userId: user.id, compact: isMobile),
                const SizedBox(width: 8),
                const _AuthThemeToggle(compact: false),
                const SizedBox(width: 8),
                Padding(
                  padding: EdgeInsets.only(right: isMobile ? 8 : 0),
                  child: ElevatedButton(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: BoostDriveTheme.primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 26,
                        vertical: isMobile ? 10 : 16,
                      ),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      'Log Out',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 12 : 15,
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

class _AuthNavLink extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AuthNavLink({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BoostNavHoverUnderline(
      isActive: isActive,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      onTap: onTap,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Colors.white.withValues(alpha: isActive ? 1 : 0.9),
        ),
      ),
    );
  }
}

class _MobileNavMenuTile extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MobileNavMenuTile({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isActive,
      selectedTileColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.08),
      title: Text(
        label,
        style: GoogleFonts.montserrat(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          color: isActive ? BoostDriveTheme.primaryColor : const Color(0xFF221C20),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _AuthThemeToggle extends ConsumerWidget {
  final bool compact;

  const _AuthThemeToggle({this.compact = false});

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
