import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boost_drive_web/dashboard_router.dart';
import 'package:boost_drive_web/messages_page.dart';
import 'package:boost_drive_web/public_nav_auth_widgets.dart';
class PublicNavDrawer extends ConsumerWidget {
  final String activeRoute;
  final VoidCallback onAuthTap;

  const PublicNavDrawer({
    super.key,
    required this.activeRoute,
    required this.onAuthTap,
  });

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.of(context).pushNamed(route);
  }

  void _pushPage(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = user != null ? ref.watch(userProfileProvider(user.id)).value : null;
    final isGuest = user == null;
    final sellerExtras = profile != null && isMarketplaceSeller(profile);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: BoostDriveTheme.primaryColor,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'BoostDrive',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (user != null) ...[
                    PublicNavNotificationBell(userId: user.id, compact: true),
                    PublicNavProfileAvatar(userId: user.id, compact: true),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const _DrawerSectionHeader(label: 'Marketplace'),
                  _DrawerNavTile(
                    label: 'Marketplace',
                    isActive: activeRoute == '/marketplace',
                    onTap: () => _go(context, '/marketplace'),
                  ),
                  if (!isGuest) ...[
                    if (profile == null ||
                        !(profile.isProvider || isWebProviderRole(profile.role)))
                      _DrawerNavTile(
                        label: 'Find a Provider',
                        isActive: activeRoute == '/find-provider',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed('/find-provider');
                        },
                      ),
                    _DrawerNavTile(
                      label: 'Messages',
                      isActive: false,
                      onTap: () => _pushPage(context, const MessagesPage()),
                    ),
                    if (sellerExtras)
                      _DrawerNavTile(
                        label: 'Rentals',
                        isActive: activeRoute == '/rent-a-car',
                        onTap: () => _go(context, '/rent-a-car'),
                      ),
                    _DrawerNavTile(
                      label: 'Dashboard',
                      isActive: false,
                      onTap: () {
                        if (profile != null) {
                          _pushPage(context, dashboardWidgetForProfile(profile));
                        }
                      },
                    ),
                    const Divider(height: 24, indent: 16, endIndent: 16),
                  ],
                  if (isGuest) ...[
                    _DrawerNavTile(
                      label: 'Buy parts',
                      isActive: activeRoute == '/buy-parts',
                      onTap: () => _go(context, '/buy-parts'),
                    ),
                    _DrawerNavTile(
                      label: 'Rent a car',
                      isActive: activeRoute == '/rent-a-car',
                      onTap: () => _go(context, '/rent-a-car'),
                    ),
                    _DrawerNavTile(
                      label: 'Sell your car',
                      isActive: activeRoute == '/sell-your-car',
                      onTap: () {
                        Navigator.pop(context);
                        if (user == null) {
                          onAuthTap();
                        } else {
                          _go(context, '/sell-your-car');
                        }
                      },
                    ),
                    _DrawerNavTile(
                      label: 'New arrivals',
                      isActive: activeRoute == '/new-arrivals',
                      onTap: () => _go(context, '/new-arrivals'),
                    ),
                    const Divider(height: 24, indent: 16, endIndent: 16),
                    const _DrawerSectionHeader(label: 'Company'),
                    _DrawerNavTile(
                      label: 'About us',
                      isActive: activeRoute == '/about',
                      onTap: () => _go(context, '/about'),
                    ),
                    _DrawerNavTile(
                      label: 'Contact',
                      isActive: activeRoute == '/contact',
                      onTap: () => _go(context, '/contact'),
                    ),
                    _DrawerNavTile(
                      label: 'Careers',
                      isActive: activeRoute == '/careers',
                      onTap: () => _go(context, '/careers'),
                    ),
                    _DrawerNavTile(
                      label: 'Partner program',
                      isActive: activeRoute == '/partner-program',
                      onTap: () => _go(context, '/partner-program'),
                    ),
                    const Divider(height: 24, indent: 16, endIndent: 16),
                    const _DrawerSectionHeader(label: 'Support'),
                    _DrawerNavTile(
                      label: 'Find a Provider',
                      isActive: activeRoute == '/find-provider',
                      onTap: () => _go(context, '/find-provider'),
                    ),
                    _DrawerNavTile(
                      label: 'Safety center',
                      isActive: activeRoute == '/safety',
                      onTap: () => _go(context, '/safety'),
                    ),
                    _DrawerNavTile(
                      label: 'Terms of service',
                      isActive: activeRoute == '/terms',
                      onTap: () => _go(context, '/terms'),
                    ),
                    _DrawerNavTile(
                      label: 'Privacy policy',
                      isActive: activeRoute == '/privacy',
                      onTap: () => _go(context, '/privacy'),
                    ),
                    _DrawerNavTile(
                      label: 'FAQ',
                      isActive: activeRoute == '/faq',
                      onTap: () => _go(context, '/faq'),
                    ),
                  ] else ...[
                    _DrawerNavTile(
                      label: 'Buy parts',
                      isActive: activeRoute == '/buy-parts',
                      onTap: () => _go(context, '/buy-parts'),
                    ),
                    _DrawerNavTile(
                      label: 'Rent a car',
                      isActive: activeRoute == '/rent-a-car',
                      onTap: () => _go(context, '/rent-a-car'),
                    ),
                    _DrawerNavTile(
                      label: 'New arrivals',
                      isActive: activeRoute == '/new-arrivals',
                      onTap: () => _go(context, '/new-arrivals'),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (user == null) {
                      onAuthTap();
                    } else {
                      ref.read(authServiceProvider).signOut();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user == null ? BoostDriveTheme.primaryColor : Colors.red.shade50,
                    foregroundColor: user == null ? Colors.white : Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    user == null ? 'Login' : 'Log Out',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  final String label;

  const _DrawerSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: BoostDriveTheme.primaryColor,
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
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
