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
        backgroundColor: BoostDriveTheme.backgroundDark,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.white10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text(
                    'BoostDrive',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                  if (user != null)
                    ref.watch(userProfileProvider(user.id)).when(
                      data: (profile) => Text(profile?.fullName ?? '', style: const TextStyle(color: Colors.white70)),
                      loading: () => const SizedBox(),
                      error: (_, _) => const SizedBox(),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_input_component, color: BoostDriveTheme.primaryColor),
              title: const Text('PARTS', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PartsMarketplacePage())),
            ),
            if (user != null)
              ListTile(
                leading: const Icon(Icons.message_outlined, color: BoostDriveTheme.primaryColor),
                title: const Text('MESSAGES', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesPage())),
              ),
            ListTile(
              leading: const Icon(Icons.car_rental, color: BoostDriveTheme.primaryColor),
              title: const Text('RENTALS', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RentalMarketplacePage())),
            ),
            if (user != null)
              ListTile(
                leading: const Icon(Icons.dashboard_outlined, color: BoostDriveTheme.primaryColor),
                title: const Text('DASHBOARD', style: TextStyle(color: Colors.white)),
                onTap: () {
                  final profile = ref.read(userProfileProvider(user.id)).value;
                  if (profile != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => _getDashboardForRole(profile.role)),
                    );
                  }
                },
              ),
          ],
        ),
      ) : null,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        titleSpacing: isMobile ? 0 : 24, // Use 0 on mobile to be next to drawer icon, 24 on desktop
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
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
                if (!isMobile) ...[
                  if (user == null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => _toggleMegaMenu('Marketplace'),
                          child: TextButton(
                            key: _marketplaceKey,
                            onPressed: () => _toggleMegaMenu('Marketplace'),
                            child: _NavTopLabel(text: 'Marketplace', isActive: _activeMegaSection == 'Marketplace'),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => _toggleMegaMenu('Company'),
                          child: TextButton(
                            key: _companyKey,
                            onPressed: () => _toggleMegaMenu('Company'),
                            child: _NavTopLabel(text: 'Company', isActive: _activeMegaSection == 'Company'),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => _toggleMegaMenu('Support'),
                          child: TextButton(
                            key: _supportKey,
                            onPressed: () => _toggleMegaMenu('Support'),
                            child: _NavTopLabel(text: 'Support', isActive: _activeMegaSection == 'Support'),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindProvidersPage())),
                            child: const _NavTopLabel(text: 'Find a Provider', isActive: false),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PartsMarketplacePage())),
                            child: const Text('PARTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesPage())),
                            child: const Text('MESSAGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RentalMarketplacePage())),
                            child: const Text('RENTALS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
                          ),
                        ),
                        // Show "Find a Provider" only for customers.
                        // If the profile is still loading, hide it to prevent provider/account mismatch flicker.
                        ref.watch(userProfileProvider(user.id)).when(
                          data: (profile) {
                            final role = profile?.role ?? '';
                            final isProvider = profile != null && _isProviderRole(role);
                            if (isProvider) return const SizedBox.shrink();
                            return _buildFindProviderOrServicesRequestedNav(ref, context, user);
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: TextButton(
                              onPressed: () {
                                final profile = ref.read(userProfileProvider(user.id)).value;
                                if (profile != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => _getDashboardForRole(profile.role)),
                                  );
                                }
                              },
                              child: const Text('DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                            ),
                          ),
                        const SizedBox(width: 12),
                      ],
                    ),
                ],
                const SizedBox(width: 8),
                if (user != null) ...[
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            onPressed: () {
                              ref.invalidate(userNotificationsProvider(user.id));
                              showDialog(
                                context: context,
                                builder: (context) => NotificationsOverlay(
                                  onNotificationTap: (type, id) {
                                    if (type == 'message') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MessagesPage(initialConversationId: id),
                                        ),
                                      );
                                    } else if (type == 'delivery') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ServiceTrackingPage(orderId: id),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ).then((_) {
                                ref.invalidate(userNotificationsProvider(user.id));
                              });
                            },
                            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final unreadMsgs = ref.watch(unreadConversationsProvider(user.id)).maybeWhen(
                              data: (ids) => ids.length,
                              orElse: () => 0,
                            );
                            final unreadSys = ref.watch(userNotificationsProvider(user.id)).maybeWhen(
                              data: (notifs) => notifs.where((n) => n['is_read'] == false).length,
                              orElse: () => 0,
                            );
                            final total = unreadMsgs + unreadSys;
                            if (total == 0) return const SizedBox.shrink();
                            return Positioned(
                              right: 4,
                              top: 4,
                              child: IgnorePointer(
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                  child: Text(
                                    total > 99 ? '99+' : '$total',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (user != null)
                  ref.watch(userProfileProvider(user.id)).when(
                    data: (profile) {
                      if (profile == null) return const SizedBox();
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
                        ),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            backgroundImage: profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null,
                            child: profile.profileImg.isEmpty
                                ? Text(
                                    getInitials(profile.fullName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(width: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                    error: (_, _) => const Icon(Icons.account_circle_outlined, color: Colors.white),
                  ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton(
                    onPressed: () {
                      if (user == null) {
                        _showLoginDialog();
                      } else {
                        ref.read(authServiceProvider).signOut();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 44),
                      backgroundColor: user == null ? Colors.white : Colors.white10,
                      foregroundColor: user == null ? BoostDriveTheme.primaryColor : Colors.white,
                    ),
                    child: Text(user == null ? 'Login' : 'Log Out'),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
      footer: AppFooter(
        onLinkTap: (section, title) {
          _handleNavLinkTap(title);
        },
      ),
      child: Column(
        children: [
          HeroSection(
            title: 'Your Complete Automotive Ecosystem',
            subtitle: 'The premier destination to buy, sell, and rent vehicles in Namibia. Drive your dreams forward with BoostDrive.',
            // backgroundImage removed to prevent overlap with PremiumPageLayout global background
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PartsMarketplacePage())),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 64),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Shop Spare Parts'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 64),
                  side: const BorderSide(color: Colors.white30, width: 2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('+ Add New Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (user == null) {
                    _showLoginDialog();
                  } else {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddListingPage()),
                    );
                    
                    if (result == true) {
                      // Refresh the featured products
                      setState(() {
                        _featuredProductsFuture = _productService.getFeaturedProducts();
                      });
                    }
                  }
                },
              ),
            ],
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
                      const Text(
                        'All Listings',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Listings',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          SizedBox(height: 8),
                          Text(
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
