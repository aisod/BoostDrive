import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boost_drive_web/parts_marketplace_page.dart';
import 'package:boost_drive_web/rental_marketplace_page.dart';
import 'package:boost_drive_web/all_listings_page.dart';
import 'package:boost_drive_web/messages_page.dart';
import 'package:boost_drive_web/product_detail_page.dart';
import 'package:boost_drive_web/add_listing_page.dart';
import 'package:boost_drive_web/new_arrivals_page.dart';
import 'package:boost_drive_web/company_pages.dart';
import 'package:boost_drive_web/support_pages.dart';
import 'package:boost_drive_web/customer_dashboard_page.dart';
import 'package:boost_drive_web/super_admin_dashboard_page.dart';
import 'package:boost_drive_web/seller_dashboard_page.dart';

import 'package:boost_drive_web/provider_hub_page.dart';
import 'package:boost_drive_web/find_providers_page.dart';
import 'boostdrive_banner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nav_hover_underline.dart';
import 'public_nav_dropdown.dart';
import 'dashboard_router.dart';
import 'suspension_overlay.dart';

class ShopHomePage extends ConsumerStatefulWidget {
  const ShopHomePage({super.key});

  @override
  ConsumerState<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends ConsumerState<ShopHomePage> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _featuredProductsFuture;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  OverlayEntry? _megaMenuEntry;
  String? _activeMegaSection;
  Offset? _menuOffset;
  final GlobalKey _marketplaceKey = GlobalKey();
  final GlobalKey _companyKey = GlobalKey();
  final GlobalKey _supportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _featuredProductsFuture = _productService.getFeaturedProducts();
  }

  @override
  void dispose() {
    // Do not call _closeMegaMenu() here: remove() can throw when overlay is already torn down
    _megaMenuEntry = null;
    _activeMegaSection = null;
    _menuOffset = null;
    super.dispose();
  }

  void _showLoginDialog() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _goHome() {
    if (ModalRoute.of(context)?.settings.name == '/') return;
    Navigator.of(context).pushNamed('/');
  }

  void _toggleThemeMode() {
    final notifier = ref.read(themeModeProvider.notifier);
    final currentMode = ref.read(themeModeProvider);
    notifier.state = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  Widget _buildThemeToggleButton({
    bool compact = false,
    EdgeInsetsGeometry? margin,
  }) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final trackWidth = compact ? 40.0 : 46.0;
    final trackHeight = compact ? 22.0 : 26.0;
    final knobSize = compact ? 16.0 : 20.0;

    return Tooltip(
      message: 'Switch to ${isDarkMode ? 'light' : 'dark'} mode',
      child: Container(
        margin: margin,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _toggleThemeMode,
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
      ),
    );
  }

  void _closeMegaMenu() {
    final entry = _megaMenuEntry;
    _megaMenuEntry = null;
    _activeMegaSection = null;
    _menuOffset = null;
    if (entry != null && mounted) {
      try {
        entry.remove();
      } catch (_) {
        // Ignore if overlay was already torn down (e.g. after route pop)
      }
    }
  }

  void _toggleMegaMenu(String section) {
    final offset = _getMenuOffsetForSection(section);
    setState(() {
      _activeMegaSection = section;
      _menuOffset = offset;
    });

    if (_megaMenuEntry != null) {
      // Already inserted; just let setState rebuild it with new section/position
      return;
    }

    _megaMenuEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Tap-outside to close
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeMegaMenu,
                child: const SizedBox.shrink(),
              ),
            ),
            Positioned(
              top: (_menuOffset?.dy ?? kToolbarHeight + 8),
              left: (_menuOffset?.dx ?? 0) - 12,
              child: Material(
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _MegaMenuPanel(
                    activeSection: _activeMegaSection,
                    onClose: _closeMegaMenu,
                    onTapLink: (title) {
                      _closeMegaMenu();
                      _handleNavLinkTap(title);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    final overlay = Overlay.maybeOf(context);
    if (overlay != null) {
      overlay.insert(_megaMenuEntry!);
    }
  }

  Offset _getMenuOffsetForSection(String section) {
    GlobalKey key;
    switch (section) {
      case 'Company':
        key = _companyKey;
        break;
      case 'Support':
        key = _supportKey;
        break;
      case 'Marketplace':
      default:
        key = _marketplaceKey;
        break;
    }

    final ctx = key.currentContext;
    if (ctx == null) {
      return const Offset(0, kToolbarHeight + 8);
    }
    final box = ctx.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero);
    return Offset(topLeft.dx, topLeft.dy + box.size.height);
  }

  void _handleNavLinkTap(String title) {
    Widget? page;
    switch (title) {
      case 'Buy Parts':
        page = const PartsMarketplacePage();
        break;
      case 'Rent a Car':
        page = const RentalMarketplacePage();
        break;
      case 'Sell Your Vehicle':
        if (ref.read(currentUserProvider) == null) {
          _showLoginDialog();
          return;
        }
        page = const AddListingPage();
        break;
      case 'New Arrivals':
        page = const NewArrivalsPage();
        break;
      case 'About Us':
        page = const AboutPage();
        break;
      case 'Contact':
        page = const ContactPage();
        break;
      case 'Careers':
        page = const CareersPage();
        break;
      case 'Partner Program':
        page = const PartnerProgramPage();
        break;
      case 'Safety Center':
        page = const SafetyCenterPage();
        break;
      case 'Find a Provider':
        final u = ref.read(currentUserProvider);
        if (u == null) {
          page = const FindProvidersPage();
        } else {
          final profile = ref.read(userProfileProvider(u.id)).valueOrNull;
          final isProvider = profile != null && _isProviderRole(profile.role);
          page = isProvider ? ProviderHubPage() : const FindProvidersPage();
        }
        break;
      case 'Terms of Service':
        page = const TermsPage();
        break;
      case 'Privacy Policy':
        page = const PrivacyPolicyPage();
        break;
      case 'FAQ':
        page = const FaqPage();
        break;
    }

    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).value;
    final user = authState?.session?.user;
    
    bool isSuspended = false;
    if (user != null) {
      final userProfile = ref.watch(userProfileProvider(user.id));
      
      isSuspended = userProfile.when(
        data: (p) => p != null && (p.status == 'suspended' || p.status == 'banned'),
        loading: () => false,
        error: (_, __) => false,
      );
    
    // DEBUG: Log profile data to help troubleshoot role mismatch
    if (userProfile.value != null) {
      final profile = userProfile.value!;
      debugPrint("DEBUG: Active User Profile: ID=${profile.uid}, Name=${profile.fullName}, Role='${profile.role}', isBuyer=${profile.isBuyer}, isSeller=${profile.isSeller}");
    } else if (userProfile.hasError) {
       debugPrint("DEBUG: User Profile Error: ${userProfile.error}");
    }

    userProfile.whenData((profile) {
        if (profile != null) {
          // ADMIN GATE: Automatically route admins to the Admin Dashboard
          if (profile.isAdmin || profile.role == 'admin' || profile.role == 'super_admin') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SuperAdminDashboardPage()),
              );
            });
            return;
          }



          // Check if user has no role set and isn't marked as buyer/seller.
          // Don't force role selection for providers even if isBuyer/isSeller flags are inconsistent.
          final role = profile.role.trim().toLowerCase();
          final isCustomerOrSeller = role == 'customer' || role == 'seller';
          final isProviderRole = _isProviderRole(profile.role);
          if (!profile.isBuyer && !profile.isSeller && !isCustomerOrSeller && !isProviderRole) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
              );
            });
          }
        }
      });
    }

    final isMobile = MediaQuery.of(context).size.width < 900;
    if (isMobile && _megaMenuEntry != null) {
      _closeMegaMenu();
    }

    return Stack(
      children: [
        PremiumPageLayout(
          scaffoldKey: _scaffoldKey,
      endDrawer: Drawer(
        width: isMobile ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.width * 0.5,
        backgroundColor: Colors.white,
        child: BoostLoginPage(
          onLoginSuccess: () {
            handleWebLoginSuccess(
              context,
              ref,
              closeDrawer: () => _scaffoldKey.currentState?.closeEndDrawer(),
            );
          },
          onClose: () {
            _scaffoldKey.currentState?.closeEndDrawer();
          },
        ),
      ),
      drawer: isMobile ? Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Orange brand header matching the desktop AppBar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(color: BoostDriveTheme.primaryColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BoostDrive',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5),
                    ),
                    if (user != null)
                      ref.watch(userProfileProvider(user.id)).when(
                        data: (profile) => profile != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  profile.displayName,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              )
                            : const SizedBox(),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                  ],
                ),
              ),
              // Scrollable nav links
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // ── MARKETPLACE ──────────────────────────────────────
                    _DrawerSectionHeader(label: 'Marketplace'),
                    _DrawerNavTile(
                      icon: Icons.settings_input_component_outlined,
                      label: 'Buy Parts',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PartsMarketplacePage()));
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.car_rental_outlined,
                      label: 'Rent a Car',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalMarketplacePage()));
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.sell_outlined,
                      label: 'Sell Your Vehicle',
                      onTap: () {
                        Navigator.pop(context);
                        if (user == null) {
                          _showLoginDialog();
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingPage()));
                        }
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.new_releases_outlined,
                      label: 'New Arrivals',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NewArrivalsPage()));
                      },
                    ),
                    const Divider(height: 24, indent: 16, endIndent: 16),
                    // ── COMPANY ──────────────────────────────────────────
                    _DrawerSectionHeader(label: 'Company'),
                    _DrawerNavTile(
                      icon: Icons.info_outline,
                      label: 'About Us',
                      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())); },
                    ),
                    _DrawerNavTile(
                      icon: Icons.mail_outline,
                      label: 'Contact',
                      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPage())); },
                    ),
                    _DrawerNavTile(
                      icon: Icons.work_outline,
                      label: 'Careers',
                      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CareersPage())); },
                    ),
                    _DrawerNavTile(
                      icon: Icons.handshake_outlined,
                      label: 'Partner Program',
                      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerProgramPage())); },
                    ),
                    const Divider(height: 24, indent: 16, endIndent: 16),
                    // ── SUPPORT ──────────────────────────────────────────
                    _DrawerSectionHeader(label: 'Support'),
                    _DrawerNavTile(
                      icon: Icons.build_outlined,
                      label: 'Find a Provider',
                      onTap: () {
                        Navigator.pop(context);
                        if (user == null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FindProvidersPage()));
                        } else {
                          final profile = ref.read(userProfileProvider(user.id)).valueOrNull;
                          final isProvider = profile != null && _isProviderRole(profile.role);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => isProvider ? ProviderHubPage() : const FindProvidersPage()));
                        }
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.shield_outlined,
                      label: 'Safety Center',
                      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyCenterPage())); },
                    ),
                    _DrawerNavTile(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage())); },
                    ),
                    _DrawerNavTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())); },
                    ),
                    _DrawerNavTile(
                      icon: Icons.help_outline,
                      label: 'FAQ',
                      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqPage())); },
                    ),
                    // ── AUTH-AWARE ITEMS ─────────────────────────────────
                    if (user != null) ...[
                      const Divider(height: 24, indent: 16, endIndent: 16),
                      _DrawerNavTile(
                        icon: Icons.message_outlined,
                        label: 'Messages',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesPage()));
                        },
                      ),
                      _DrawerNavTile(
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                        onTap: () {
                          Navigator.pop(context);
                          final profile = ref.read(userProfileProvider(user.id)).value;
                          if (profile != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => _getDashboardForRole(profile.role)));
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              // Bottom Login / Logout button
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildThemeToggleButton(
                      margin: const EdgeInsets.only(right: 10),
                    ),
                    Expanded(
                      flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (user == null) {
                        _showLoginDialog();
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
                    icon: Icon(user == null ? Icons.login : Icons.logout, size: 18),
                    label: Text(user == null ? 'Login' : 'Log Out', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ) : null,
      appBar: isMobile ? AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: GestureDetector(
          onTap: _goHome,
          child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BoostDrive',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -1, color: Colors.white),
            ),
          ],
          ),
        ),
        actions: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeToggleButton(
                  compact: true,
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: Icon(user == null ? Icons.login : Icons.logout),
                    tooltip: user == null ? 'Login' : 'Log Out',
                    onPressed: () {
                      if (user == null) {
                        _showLoginDialog();
                      } else {
                        ref.read(authServiceProvider).signOut();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ) : null,
      footer: AppFooter(
        onLinkTap: (section, title) {
          _handleNavLinkTap(title);
        },
      ),
      child: Column(
        children: [
          // DASHBOARD ALERTS
          if (user != null)
            Consumer(
              builder: (context, ref, _) {
                final alertsAsync = ref.watch(activeDashboardAlertsStreamProvider(user.id));
                return alertsAsync.when(
                  data: (alerts) {
                    if (alerts.isEmpty) return const SizedBox.shrink();
                    // Just show the latest one to keep layout clean
                    return BoostDriveBanner(
                      alert: alerts.first,
                      onAction: (ticketId) {
                        ref.read(pendingSupportTicketIdProvider.notifier).state = ticketId;
                        final profile = ref.read(userProfileProvider(user.id)).value;
                        if (profile != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => _getDashboardForRole(profile.role)));
                        }
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          EditorialHeroSection(
            title: 'Your Premium Automotive Connection',
            subtitle: 'Buy, sell, and rent vehicles with confidence across Namibia. Drive your dreams forward with BoostDrive.',
            backgroundImages: const [
              'assets/images/landing-page-image.jpg',
              'assets/images/fordranger.jpg',
              'assets/images/gti.jpg',
              'assets/images/toyota.jpg',
            ],
            imagePackage: null,
            topChromeHeight: isMobile
                ? kToolbarHeight + MediaQuery.paddingOf(context).top
                : 0,
            hashtag: "#DRIVEYOURDREAMS",
            onReadMore: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllListingsPage())),
            navBar: _buildEditorialNavBar(user),
          ),
          const SizedBox(height: 40),
          _buildLandingLowerSection(isMobile),
          const SizedBox(height: 80),
        ],
      ),
    ),
    if (isSuspended)
      Positioned.fill(
        child: SuspensionOverlay(
          reason: user != null ? ref.watch(userProfileProvider(user!.id)).valueOrNull?.suspensionReason : null,
                        ),
                      ),
                    ],
    );
  }

  Widget _buildLandingLowerSection(bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF081D2B) : const Color(0xFFF3F4F6),
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 22, vertical: isMobile ? 18 : 26),
        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
            _buildFeaturedMarketplaceHeader(isMobile, isDark),
            const SizedBox(height: 16),
            _buildGrid(isMobile, isDark),
            const SizedBox(height: 30),
            if (isDark) _buildDarkServicesSection(isMobile),
            const SizedBox(height: 28),
            _buildWhyChooseUsSection(isMobile, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedMarketplaceHeader(bool isMobile, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDark ? 'Featured Marketplace' : 'Featured Listings',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 18 : (isDark ? 30 : 40),
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1C1F24),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isDark
                    ? 'Explore our latest vehicles, parts, and rental offers.'
                    : 'Hand-picked premium vehicles and essential parts from our top providers.',
                style: TextStyle(
                  color: isDark ? const Color(0xFF8AA3B8) : const Color(0xFF757982),
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
        ],
      ),
    ),
        TextButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllListingsPage())),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: Text(isDark ? 'View all' : 'View all marketplace'),
          style: TextButton.styleFrom(
            foregroundColor: BoostDriveTheme.primaryColor,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ),
    ],
    );
  }

  Widget _buildGrid(bool isMobile, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 6),
      child: FutureBuilder<List<Product>>(
        future: _featuredProductsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading products: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          }
          final products = snapshot.data!;
          final featuredProducts = products.take(3).toList();
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 3,
              childAspectRatio: isDark ? (isMobile ? 0.92 : 0.9) : (isMobile ? 0.95 : 0.82),
              crossAxisSpacing: isMobile ? 10 : 14,
              mainAxisSpacing: isMobile ? 10 : 14,
            ),
            itemCount: featuredProducts.length,
            itemBuilder: (context, index) => _buildLandingProductCard(
              product: featuredProducts[index],
              isDark: isDark,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductDetailPage(product: featuredProducts[index])),
                );
                if (result == true) {
                  setState(() {
                    _featuredProductsFuture = _productService.getFeaturedProducts();
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLandingProductCard({
    required Product product,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final chipLabel = switch (product.category) {
      'car' => 'FOR SALE',
      'rental' => 'FOR RENT',
      _ => 'SPARES',
    };
    final ctaLabel = switch (product.category) {
      'rental' => 'Book Now',
      'part' => 'Add to Cart',
      _ => 'View Details',
    };
    final cardBg = isDark ? const Color(0xFF0C2636) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF22252A);
    final metaColor = isDark ? const Color(0xFF93A8B8) : const Color(0xFF878C93);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(isDark ? 12 : 24),
          border: Border.all(color: isDark ? const Color(0xFF1C3A4B) : const Color(0xFFE4E6EA)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isDark ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isDark ? 10 : 18),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(product.imageUrl, fit: BoxFit.cover)
                            : Container(color: isDark ? const Color(0xFF173243) : const Color(0xFFF3F4F6)),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF19384A) : const Color(0xFFE7EDF4),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            chipLabel,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFB4C8D7) : const Color(0xFF667085),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: titleColor, fontSize: isDark ? 12 : 34 / 2, fontWeight: FontWeight.w700, height: 1.15),
              ),
              const SizedBox(height: 3),
              Text(
                'N\$ ${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2)}${product.category == 'rental' ? '/day' : ''}',
                style: TextStyle(color: BoostDriveTheme.primaryColor, fontSize: isDark ? 14 : 31 / 2, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                product.subtitle.isEmpty ? product.location : product.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: metaColor, fontSize: 11),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: product.category == 'part' ? BoostDriveTheme.primaryColor : Colors.transparent,
                    foregroundColor: product.category == 'part' ? Colors.white : BoostDriveTheme.primaryColor,
                    side: BorderSide(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.8)),
                    minimumSize: Size(0, isDark ? 32 : 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    textStyle: TextStyle(fontSize: isDark ? 9 : 12, fontWeight: FontWeight.w700),
                  ),
                  child: Text(ctaLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightServicesSection(bool isMobile) {
    final cards = [
      (Icons.verified_user_outlined, 'Secure Transactions', 'Every listing and transaction is verified for your peace of mind.'),
      (Icons.support_agent, 'Expert Support', 'Our team is ready to assist with buying, selling, or renting.'),
      (Icons.location_on_outlined, 'Namibia-wide Network', 'Connecting drivers from Windhoek to Swakopmund and beyond.'),
    ];
    return isMobile
        ? Column(
            children: cards
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildWhyChooseUsCard(
                      icon: item.$1,
                      title: item.$2,
                      body: item.$3,
                      isDark: false,
                    ),
                  ),
                )
                .toList(),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildWhyChooseUsCard(
                        icon: item.$1,
                        title: item.$2,
                        body: item.$3,
                        isDark: false,
                      ),
                    ),
                  ),
                )
                .toList(),
          );
  }

  Widget _buildDarkServicesSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Comprehensive Services',
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: isMobile ? 20 : 29, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          isMobile
              ? Column(
                  children: [
                    _buildDarkServiceImageCard(compact: true),
                    const SizedBox(height: 10),
                    SizedBox(height: 132, child: _buildDarkServiceOrangeCard()),
                  ],
                )
              : SizedBox(
                  height: 236,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildDarkServiceImageCard()),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Expanded(child: _buildDarkServiceOrangeCard()),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildDarkServiceMiniCard(Icons.car_repair, 'Vehicle Parts')),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildDarkServiceMiniCard(Icons.build_circle_outlined, 'Self Service')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseUsSection(bool isMobile, bool isDark) {
    final items = [
      (
        Icons.verified_outlined,
        'Verified Listings',
        'Browse trusted vehicles, parts, and rentals from a marketplace built for confidence.'
      ),
      (
        Icons.support_agent_outlined,
        'Dedicated Support',
        'Get help with buying, selling, rentals, and provider discovery whenever you need guidance.'
      ),
      (
        Icons.bolt_outlined,
        'Fast Discovery',
        'Jump between listings, providers, and categories quickly with a cleaner browsing experience.'
      ),
      (
        Icons.public_outlined,
        'Nationwide Reach',
        'Connect with automotive buyers, sellers, and service providers across Namibia in one place.'
      ),
    ];

    final sectionBg = isDark ? const Color(0xFF0B2332) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1B3C4E) : const Color(0xFFE5E7EB);
    final headingColor = isDark ? Colors.white : const Color(0xFF1F2933);
    final bodyColor = isDark ? const Color(0xFF94A9B8) : const Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(isDark ? 18 : 28),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 24,
        vertical: isMobile ? 22 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose Us',
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 22 : 32,
              fontWeight: FontWeight.w800,
              color: headingColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BoostDrive brings buyers, sellers, renters, and providers together in one polished automotive destination.',
            style: TextStyle(
              color: bodyColor,
              fontSize: isMobile ? 13 : 14,
              height: 1.5,
            ),
          ),
          if (!isDark) ...[
            const SizedBox(height: 22),
            _buildLightServicesSection(isMobile),
          ],
          const SizedBox(height: 22),
          isMobile
              ? Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildWhyChooseUsCard(
                            icon: item.$1,
                            title: item.$2,
                            body: item.$3,
                            isDark: isDark,
                          ),
                        ),
                      )
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _buildWhyChooseUsCard(
                              icon: item.$1,
                              title: item.$2,
                              body: item.$3,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseUsCard({
    required IconData icon,
    required String title,
    required String body,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF102B3B) : const Color(0xFFF9FAFB);
    final titleColor = isDark ? Colors.white : const Color(0xFF20262D);
    final bodyColor = isDark ? const Color(0xFF8FA4B5) : const Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1C3A4B) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BoostDriveTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: BoostDriveTheme.primaryColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: bodyColor,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkServiceImageCard({bool compact = false}) {
    if (compact) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B2232),
              Color(0xFF14364B),
              Color(0xFF081722),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Text(
                'TRUSTED SERVICES',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Find vetted providers for roadside help, parts, and repairs.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindProvidersPage())),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              child: const Text('FIND A PROVIDER'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B2232),
            Color(0xFF14364B),
            Color(0xFF081722),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -40,
            top: -25,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BoostDriveTheme.primaryColor.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Text(
                    'TRUSTED SERVICES',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Find vetted providers\nfor roadside help,\nparts, and repairs.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindProvidersPage())),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(110, 34),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                child: const Text('FIND A PROVIDER'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkServiceOrangeCard() {
    return Container(
      decoration: BoxDecoration(
        color: BoostDriveTheme.primaryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HIRE A PROVIDER', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('A reliable provider for assistance or vehicle repair.', style: TextStyle(color: Colors.white, fontSize: 12)),
          Spacer(),
          Icon(Icons.north_east_rounded, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildDarkServiceMiniCard(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF142D3F),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF9BB3C2), size: 18),
          const Spacer(),
          Text(title, style: const TextStyle(color: Color(0xFFB3C3CE), fontSize: 11)),
        ],
      ),
    );
  }


  Widget _getDashboardForRole(String role) {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final profile = ref.read(userProfileProvider(user.id)).valueOrNull;
      if (profile != null) {
        return dashboardWidgetForProfile(profile);
      }
    }
    return dashboardWidgetForRole(role);
  }

  /// True if the role is a service provider (mechanic, towing, seller, etc.) who sees "Services requested" in nav.
  bool _isProviderRole(String role) {
    final cleaned = role.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');
    if (cleaned.isEmpty) return false;

    // Role can be stored as plain "provider".
    if (cleaned == 'service_provider') return true;

    return cleaned.contains('service provider') ||
        cleaned.contains('service pro') ||
        cleaned.contains('mechanic') ||
        cleaned.contains('towing') ||
        cleaned.contains('logistics') ||
        cleaned.contains('rental');
  }

  /// Customer nav: "Find a Provider" → FindProvidersPage. Provider nav: "Services requested" → ProviderHubPage.
  Widget _buildEditorialNavBar(dynamic user) {
    final List<Widget> navChildren = user == null
        ? [
          _EditorialNavLink(text: 'Marketplace', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllListingsPage())), isDark: true),
          _EditorialNavLink(text: 'Buy parts', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartsMarketplacePage())), isDark: true),
          _EditorialNavLink(text: 'Rent a car', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalMarketplacePage())), isDark: true),
          _EditorialNavLink(text: 'Sell your car', onTap: () => _showLoginDialog(), isDark: true),
          _EditorialNavLink(text: 'New arrivals', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewArrivalsPage())), isDark: true),
          _EditorialNavLink(text: 'Find a Provider', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindProvidersPage())), isDark: true),
            BoostNavHoverDropdown(
              label: 'Company',
              isActive: false,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              items: const [
                BoostNavDropdownItem(label: 'About us', route: '/about'),
                BoostNavDropdownItem(label: 'Contact', route: '/contact'),
                BoostNavDropdownItem(label: 'Careers', route: '/careers'),
                BoostNavDropdownItem(label: 'Partner program', route: '/partner-program'),
              ],
            ),
            BoostNavHoverDropdown(
              label: 'Support',
              isActive: false,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              items: const [
                BoostNavDropdownItem(label: 'Safety center', route: '/safety'),
                BoostNavDropdownItem(label: 'Terms of service', route: '/terms'),
                BoostNavDropdownItem(label: 'Privacy policy', route: '/privacy'),
                BoostNavDropdownItem(label: 'FAQ', route: '/faq'),
              ],
            ),
          ]
        : [
          _EditorialNavLink(text: 'MARKETPLACE', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllListingsPage())), isDark: true),
          Consumer(
            builder: (context, ref, _) {
              final profile = ref.watch(userProfileProvider(user.id)).value;
              final isProvider = profile != null && _isProviderRole(profile.role);
              return _EditorialNavLink(
                text: isProvider ? 'SERVICES REQUESTED' : 'FIND A PROVIDER',
                onTap: () {
                  if (isProvider) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderHubPage()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FindProvidersPage()));
                  }
                },
                isDark: true,
              );
            },
          ),
          _EditorialNavLink(text: 'MESSAGES', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesPage())), isDark: true),
          Consumer(
            builder: (context, ref, _) {
              final profile = ref.watch(userProfileProvider(user.id)).value;
                if (profile == null || _isProviderRole(profile.role)) {
                return const SizedBox.shrink();
                }

                return _EditorialNavLink(
                  text: 'RENTALS',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RentalMarketplacePage()),
                  ),
                  isDark: true,
                );
            },
          ),
          _EditorialNavLink( 
            text: 'DASHBOARD', 
            onTap: () {
               final profile = ref.read(userProfileProvider(user.id)).value;
               if (profile != null) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => _getDashboardForRole(profile.role)));
               }
            }, 
              isDark: true,
          ),
          ];
          
    final List<Widget> trailingChildren = [
      if (user != null)
          Consumer(
            builder: (context, ref, _) {
              return Row(
              mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNotificationBell(ref, user.id),
                const SizedBox(width: 12),
                  _buildProfileIcon(ref, user.id),
                const SizedBox(width: 12),
                ],
              );
            },
          ),
      _buildThemeToggleButton(),
        Container(
        margin: const EdgeInsets.only(left: 12),
          child: ElevatedButton(
            onPressed: () {
              if (user == null) {
                _showLoginDialog();
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
    ];

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _goHome,
              child: Text(
                "BoostDrive",
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: Colors.white,
                ),
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
                children: navChildren,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: trailingChildren,
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildFindProviderOrServicesRequestedNav(WidgetRef ref, BuildContext context, dynamic user) {
    final profile = ref.watch(userProfileProvider(user.id)).value;
    final isProviderRole = profile != null && _isProviderRole(profile.role);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TextButton(
        onPressed: () {
          if (isProviderRole) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderHubPage()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const FindProvidersPage()));
          }
        },
        child: Text(
          isProviderRole ? 'SERVICES REQUESTED' : 'FIND A PROVIDER',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(WidgetRef ref, String uid) {
    final notificationsAsync = ref.watch(userNotificationsStreamProvider(uid));
    
    return notificationsAsync.when(
      data: (list) {
        final unreadCount = list.where((n) => n['is_read'] == false).length;
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => NotificationsOverlay(
                    onNotificationTap: (type, id) {
                      if (type == 'support') {
                        ref.read(pendingSupportTicketIdProvider.notifier).state = id;
                        final profile = ref.read(userProfileProvider(uid)).value;
                        if (profile != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => _getDashboardForRole(profile.role)));
                        }
                      }
                    },
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => IconButton(
        icon: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        onPressed: () => _showNotificationsOverlay(uid),
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.notifications_off, color: Colors.white70),
        onPressed: () => _showNotificationsOverlay(uid),
      ),
    );
  }

  void _showNotificationsOverlay(String uid) {
    showDialog(
      context: context,
      builder: (context) => NotificationsOverlay(
        onNotificationTap: (type, id) {
          if (type == 'support') {
            ref.read(pendingSupportTicketIdProvider.notifier).state = id;
            final profile = ref.read(userProfileProvider(uid)).value;
            if (profile != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => _getDashboardForRole(profile.role)));
            }
          }
        },
      ),
    );
  }



  Widget _buildProfileIcon(WidgetRef ref, String uid) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
               if (profile.role == 'service_provider') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsPage()));
               } else {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => _getDashboardForRole(profile.role)));
               }
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              backgroundImage: profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null,
              child: profile.profileImg.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            ),
          ),
        );
      },
      loading: () => const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      error: (_, _) => const CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
    );
  }
}

// ignore: unused_element
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _ContactItem({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: BoostDriveTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
            Text(content, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// _WebLoginWrapper and its state class have been removed in favor of BoostLoginPage

class _NavTopLabel extends StatelessWidget {
  final String text;
  final bool isActive;
  const _NavTopLabel({required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
        color: Colors.white.withValues(alpha: isActive ? 1 : 0.9),
        decoration: isActive ? TextDecoration.underline : TextDecoration.none,
        decorationColor: Colors.white.withValues(alpha: 0.9),
        decorationThickness: 2,
      ),
    );
  }
}

class _MegaMenuPanel extends StatelessWidget {
  final String? activeSection;
  final VoidCallback onClose;
  final void Function(String title) onTapLink;

  const _MegaMenuPanel({
    required this.activeSection,
    required this.onClose,
    required this.onTapLink,
  });

  @override
  Widget build(BuildContext context) {
    final String section = activeSection ?? 'Marketplace';
    late final String title;
    late final List<String> links;

    switch (section) {
      case 'Company':
        title = 'Company';
        links = const ['About Us', 'Contact', 'Careers', 'Partner Program'];
        break;
      case 'Support':
        title = 'Support';
        links = const ['Find a Provider', 'Safety Center', 'Terms of Service', 'Privacy Policy', 'FAQ'];
        break;
      case 'Marketplace':
      default:
        title = 'Marketplace';
        links = const ['Buy Parts', 'Rent a Car', 'Sell Your Vehicle', 'New Arrivals'];
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7280),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            ...links.map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: GestureDetector(
                  onTap: () => onTapLink(t),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    t,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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

/// Section label (e.g. "Marketplace", "Company") in the mobile drawer.
class _DrawerSectionHeader extends StatelessWidget {
  final String label;
  const _DrawerSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: BoostDriveTheme.primaryColor,
        ),
      ),
    );
  }
}

/// Single nav row in the mobile drawer.
class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerNavTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: BoostDriveTheme.primaryColor),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorialNavLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isDark;
  
  const _EditorialNavLink({required this.text, required this.onTap, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return BoostNavHoverUnderline(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          onTap: onTap,
          child: Text(
            text,
        maxLines: 1,
        softWrap: false,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

