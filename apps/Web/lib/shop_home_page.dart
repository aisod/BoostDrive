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
import 'package:boost_drive_web/dashboard_alert_banner.dart';
import 'package:google_fonts/google_fonts.dart';
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
            _scaffoldKey.currentState?.closeEndDrawer();
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
                child: SizedBox(
                  width: double.infinity,
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BoostDrive',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -1, color: Colors.white),
            ),
          ],
        ),
        actions: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(Icons.login),
                    onPressed: () => _showLoginDialog(),
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
                final alertsAsync = ref.watch(activeDashboardAlertsProvider(user.id));
                return alertsAsync.maybeWhen(
                  data: (alerts) {
                    if (alerts.isEmpty) return const SizedBox.shrink();
                    // Just show the latest one to keep layout clean
                    return DashboardAlertBanner(alert: alerts.first);
                  },
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
          EditorialHeroSection(
            title: 'Your Premium Automotive Connection',
            subtitle: 'Buy, sell, and rent vehicles with confidence across Namibia. Drive your dreams forward with BoostDrive.',
            backgroundImage: 'assets/images/landing-page-image.jpg',
            hashtag: "#DRIVEYOURDREAMS",
            onReadMore: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllListingsPage())),
            navBar: _buildEditorialNavBar(user),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 64.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Listings',
                        style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hand-picked vehicles and parts from verified sellers.',
                        style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AllListingsPage()),
                        ),
                        icon: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, color: BoostDriveTheme.primaryColor)),
                        label: const Icon(Icons.arrow_forward, size: 16, color: BoostDriveTheme.primaryColor),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.white.withValues(alpha: 0.1);
                            }
                            return Colors.white.withValues(alpha: 0.05);
                          }),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Listings',
                            style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hand-picked vehicles and parts from verified sellers.',
                            style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AllListingsPage()),
                        ),
                        icon: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, color: BoostDriveTheme.primaryColor)),
                        label: const Icon(Icons.arrow_forward, size: 16, color: BoostDriveTheme.primaryColor),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.white.withValues(alpha: 0.1);
                            }
                            return Colors.white.withValues(alpha: 0.05);
                          }),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                _buildGrid(isMobile),
              ],
            ),
          ),
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

  Widget _buildGrid(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 24),
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
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 450,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: products.length > 4 ? 4 : products.length,
            itemBuilder: (context, index) => BoostProductCard(
              product: products[index],
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailPage(product: products[index])));
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


  Widget _getDashboardForRole(String role) {
    // Make role matching resilient to inconsistent formatting in DB
    // (spaces vs underscores vs hyphens, extra whitespace, etc).
    final cleaned = role.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');

    if (cleaned == 'admin' || cleaned == 'super_admin' || cleaned == 'super admin') {
      return SuperAdminDashboardPage();
    }

    // Seller/shop roles.
    if (cleaned == 'seller' || cleaned.contains('seller')) {
      return SellerDashboardPage();
    }

    // Service provider / mechanic / towing / logistics / rental roles.
    // Some accounts store role as just "provider".
    if (cleaned == 'service_provider') return ProviderHubPage();

    final isServiceProviderRole =
        cleaned.contains('service provider') ||
        cleaned.contains('service pro');

    final isProvider =
        isServiceProviderRole ||
        cleaned.contains('mechanic') ||
        cleaned.contains('towing') ||
        cleaned.contains('logistics') ||
        cleaned.contains('rental');

    if (isProvider) {
      return ProviderHubPage();
    }

  // Fallback: customer dashboard.
    return CustomerDashboardPage();
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
    return Row(
      children: [
        // Brand Logo in Nav
        Padding(
          padding: const EdgeInsets.only(left: 24),
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
        const Spacer(),
        // Role-based Nav Structure
        if (user == null) ...[
          _EditorialNavLink(text: 'Marketplace', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllListingsPage())), isDark: true),
          _EditorialNavLink(text: 'Buy parts', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartsMarketplacePage())), isDark: true),
          _EditorialNavLink(text: 'Rent a car', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalMarketplacePage())), isDark: true),
          _EditorialNavLink(text: 'Sell your car', onTap: () => _showLoginDialog(), isDark: true),
          _EditorialNavLink(text: 'New arrivals', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewArrivalsPage())), isDark: true),
          _EditorialNavLink(text: 'Find a Provider', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindProvidersPage())), isDark: true),
          _EditorialNavDropdown(
            title: 'Company',
            items: [
              _DropdownItem(label: 'About us', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()))),
              _DropdownItem(label: 'Contact', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPage()))),
              _DropdownItem(label: 'Careers', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareersPage()))),
              _DropdownItem(label: 'Partner program', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerProgramPage()))),
            ],
          ),
          _EditorialNavDropdown(
            title: 'Support',
            items: [
              _DropdownItem(label: 'Safety center', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyCenterPage()))),
              _DropdownItem(label: 'Terms of service', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage()))),
              _DropdownItem(label: 'Privacy policy', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()))),
              _DropdownItem(label: 'FAQ', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqPage()))),
            ],
          ),
        ] else ...[
          _EditorialNavLink(text: 'MARKETPLACE', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllListingsPage())), isDark: true),
          _EditorialNavLink(text: 'MESSAGES', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesPage())), isDark: true),
          
          Consumer(
            builder: (context, ref, _) {
              final profile = ref.watch(userProfileProvider(user.id)).value;
              if (profile == null) return const SizedBox.shrink();
              
              final isProvider = _isProviderRole(profile.role);
              if (isProvider) {
                return Row(
                  children: [
                    _EditorialNavLink(text: 'SERVICES REQUESTED', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderHubPage())), isDark: true),
                    _EditorialNavLink(text: 'FINANCE', onTap: () {}, isDark: true),
                  ],
                );
              } else {
                return Row(
                  children: [
                    _EditorialNavLink(text: 'MY LISTINGS', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerDashboardPage())), isDark: true),
                    _EditorialNavLink(text: 'RENTALS', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalMarketplacePage())), isDark: true),
                  ],
                );
              }
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
            isDark: true
          ),
        ],
        
        const Spacer(),
        
        // AUTH CTA (Pill Button)
        Container(
          margin: const EdgeInsets.only(left: 20),
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text(
              user == null ? 'Login' : 'Log Out',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
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

class _DropdownItem {
  final String label;
  final VoidCallback onTap;
  _DropdownItem({required this.label, required this.onTap});
}

class _EditorialNavDropdown extends StatefulWidget {
  final String title;
  final List<_DropdownItem> items;

  const _EditorialNavDropdown({
    required this.title,
    required this.items,
  });

  @override
  State<_EditorialNavDropdown> createState() => _EditorialNavDropdownState();
}

class _EditorialNavDropdownState extends State<_EditorialNavDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 220,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 45),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => _hideOverlay(),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.map((item) => _buildItem(item)).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    setState(() => _isHovered = false);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isHovered) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  Widget _buildItem(_DropdownItem item) {
    return InkWell(
      onTap: () {
        _overlayEntry?.remove();
        _overlayEntry = null;
        item.onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          item.label,
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _showOverlay();
        },
        onExit: (_) => _hideOverlay(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

