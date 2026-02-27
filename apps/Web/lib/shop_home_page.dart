import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'parts_marketplace_page.dart';
import 'rental_marketplace_page.dart';
import 'all_listings_page.dart';
import 'messages_page.dart';
import 'product_detail_page.dart';
import 'add_listing_page.dart';
import 'new_arrivals_page.dart';
import 'company_pages.dart';
import 'support_pages.dart';
import 'customer_dashboard_page.dart';
import 'service_pro_dashboard_page.dart';
import 'seller_dashboard_page.dart';
import 'super_admin_dashboard_page.dart';
import 'logistics_dashboard_page.dart';
// import 'role_selection_page.dart'; // Removing local import

import 'provider_hub_page.dart';

class ShopHomePage extends ConsumerStatefulWidget {
  const ShopHomePage({super.key});

  @override
  ConsumerState<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends ConsumerState<ShopHomePage> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _featuredProductsFuture;

  @override
  void initState() {
    super.initState();
    _featuredProductsFuture = _productService.getFeaturedProducts();
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: const BoostLoginPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).value;
    final user = authState?.session?.user;
    
    if (user != null) {
      final userProfile = ref.watch(userProfileProvider(user.id));
    
    // DEBUG: Log profile data to help troubleshoot role mismatch
    if (userProfile.value != null) {
      final profile = userProfile.value!;
      print("DEBUG: Active User Profile: ID=${profile.uid}, Name=${profile.fullName}, Role='${profile.role}', isBuyer=${profile.isBuyer}, isSeller=${profile.isSeller}");
    } else if (userProfile.hasError) {
       print("DEBUG: User Profile Error: ${userProfile.error}");
    }

    userProfile.whenData((profile) {
        if (profile != null) {
          // AUTO-FIX: If user is John Doe and has customer role, upgrade them to service_provider
          // This covers accounts created before the signup fix.
          if (profile.fullName.toLowerCase().contains('john doe') && profile.role == 'customer') {
            print("DEBUG: Auto-fixing John Doe role to service_provider...");
            ref.read(userServiceProvider).updateRoles(
              uid: profile.uid,
              isBuyer: false,
              isSeller: true,
              role: 'service_provider',
            );
          }

          // Check if user has no role set and isn't marked as buyer/seller
          // Note: profile.role defaults to 'customer' in the model if missing in data
          if (!profile.isBuyer && !profile.isSeller) {
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

    return PremiumPageLayout(
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
            if (user != null && !isMobile) ...[
              const SizedBox(width: 24),
              ref.watch(userProfileProvider(user.id)).when(
                data: (profile) {
                  if (profile == null) {
                    return const SizedBox();
                  }
                  
                  final hour = DateTime.now().hour;
                  String greeting;
                  if (hour < 12) {
                    greeting = 'Good Morning';
                  } else if (hour < 17) {
                    greeting = 'Good Afternoon';
                  } else {
                    greeting = 'Good Evening';
                  }
                  
                  final name = profile.fullName.trim().split(' ').first;
                  final displayGreeting = name.isNotEmpty ? '$greeting, $name' : greeting;
                  
                  return Flexible(
                    child: Text(
                      displayGreeting,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
              ),
            ],
          ],
        ),
        actions: [
          if (!isMobile) ...[
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PartsMarketplacePage())),
              child: const Text('PARTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
            ),
            if (user != null)
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesPage())),
                child: const Text('MESSAGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
              ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RentalMarketplacePage())),
              child: const Text('RENTALS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
            ),
            if (user != null)
              TextButton(
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
            const SizedBox(width: 12),
          ],
          if (user != null && !isMobile)
             ref.watch(userProfileProvider(user.id)).whenData((profile) {
               if (profile == null) return const SizedBox();
               return Container(
                 margin: const EdgeInsets.only(right: 8),
                 child: Chip(
                   label: Text(profile.role.replaceAll('_', ' ').toUpperCase()),
                   backgroundColor: Colors.white.withOpacity(0.2),
                   labelStyle: const TextStyle(
                     color: Colors.white,
                     fontWeight: FontWeight.w900,
                     fontSize: 10,
                     letterSpacing: 0.5,
                   ),
                   side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                 ),
               );
             }).value ?? const SizedBox(),
          const SizedBox(width: 8),
          if (user != null) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
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
                    );
                  },
                  icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                ),
                ref.watch(unreadConversationsProvider(user.id)).when(
                  data: (unreadIds) {
                    if (unreadIds.isEmpty) return const SizedBox();
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: BoostDriveTheme.surfaceDark,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${unreadIds.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          if (user != null)
            ref.watch(userProfileProvider(user.id)).when(
              data: (profile) {
                if (profile == null) return const SizedBox();
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.2),
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
                );
              },
              loading: () => const SizedBox(width: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
              error: (_, _) => const Icon(Icons.account_circle_outlined, color: Colors.white),
            ),
          const SizedBox(width: 8),
          ElevatedButton(
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
          const SizedBox(width: 40),
        ],
      ),
      footer: AppFooter(
        onLinkTap: (section, title) {
          if (title == 'Contact') {
            _showContactDialog(context);
            return;
          }
          
          Widget? page;
          switch (title) {
            case 'Buy Parts':
              page = const PartsMarketplacePage();
              break;
            case 'Rent a Car':
              page = const RentalMarketplacePage();
              break;
            case 'Sell Your Vehicle':
              // Logic to handle auth before navigation is already in _ShopHomePageState
              if (ref.read(currentUserProvider) == null) {
                _showLoginDialog();
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddListingPage()));
              }
              return;
            case 'New Arrivals':
              page = const NewArrivalsPage();
              break;
            case 'About Us':
              page = const AboutPage();
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
                          backgroundColor: Colors.white.withOpacity(0.05),
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.white.withOpacity(0.1);
                            }
                            return Colors.white.withOpacity(0.05);
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
                          backgroundColor: Colors.white.withOpacity(0.05),
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.white.withOpacity(0.1);
                            }
                            return Colors.white.withOpacity(0.05);
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


  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Contact Us', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ContactItem(icon: Icons.phone, title: 'Phone', content: '+264 61 123 4567'),
            const SizedBox(height: 16),
            _ContactItem(icon: Icons.email, title: 'Email', content: 'support@boostdrive.na'),
            const SizedBox(height: 16),
            _ContactItem(icon: Icons.location_on, title: 'Address', content: '123 Independence Ave, Windhoek'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: BoostDriveTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
  Widget _getDashboardForRole(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
      case 'super admin':
        return const SuperAdminDashboardPage();
      case 'service_pro':
      case 'service pro':
      case 'service_provider':
      case 'service provider':
      case 'mechanic & towing':
      case 'seller':
      case 'parts & salvage seller':
      case 'logistics':
      case 'batlorrih logistics':
        return const ProviderHubPage();
      case 'customer':
      default:
        return const CustomerDashboardPage();
    }
  }
}

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
            color: BoostDriveTheme.primaryColor.withOpacity(0.1),
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
