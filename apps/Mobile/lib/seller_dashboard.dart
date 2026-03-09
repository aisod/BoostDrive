import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'providers.dart';

class SellerDashboard extends ConsumerStatefulWidget {
  const SellerDashboard({super.key});

  @override
  ConsumerState<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends ConsumerState<SellerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _accentBlue = const Color(0xFF0095FF);
  final Color _cardBg = const Color(0xFF131D25);
  final Color _borderCol = Colors.white.withOpacity(0.05);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(ref, user.id),
              const SizedBox(height: 32),
              _buildPerformanceSection(ref, user.id),
              const SizedBox(height: 32),
              _buildTabSection(ref, user.id),
              const SizedBox(height: 32),
              _buildServiceRequestsSection(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _accentBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, String uid) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _cardBg,
              backgroundImage: profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null,
              child: profile.profileImg.isEmpty ? const Icon(Icons.person, color: Colors.white54) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BoostDrive Seller',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Metro Salvage & Parts',
                    style: GoogleFonts.manrope(
                      color: BoostDriveTheme.textDim,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search, color: Colors.white70, size: 28),
            ),
            _buildNotificationIcon(true),
          ],
        );
      },
      loading: () => const SizedBox(height: 56),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildNotificationIcon(bool hasUnread) {
    return Stack(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 28),
        ),
        if (hasUnread)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4D),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0D1117), width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPerformanceSection(WidgetRef ref, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Row(
              children: [
                Text(
                  'Last 7 Days',
                  style: GoogleFonts.manrope(
                    color: _accentBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: _accentBlue, size: 20),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPerformanceCard('Total Sales', '\$12,450', '+12%', true),
              const SizedBox(width: 16),
              _buildPerformanceCard('Active Listings', '1,248', '+3%', true),
              const SizedBox(width: 16),
              _buildPerformanceCard('Pending Orders', '14', '0%', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(String label, String value, String trend, bool isPositive) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              color: BoostDriveTheme.textDim,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                trend == '0%' ? Icons.arrow_forward : (isPositive ? Icons.trending_up : Icons.trending_down),
                color: trend == '0%' ? Colors.orange : (isPositive ? const Color(0xFF00C853) : const Color(0xFFFF4D4D)),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: GoogleFonts.manrope(
                  color: trend == '0%' ? Colors.orange : (isPositive ? const Color(0xFF00C853) : const Color(0xFFFF4D4D)),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(WidgetRef ref, String uid) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: _accentBlue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: _accentBlue,
          unselectedLabelColor: BoostDriveTheme.textDim,
          dividerColor: Colors.white.withOpacity(0.05),
          labelStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
          tabs: const [
            Tab(text: 'INVENTORY'),
            Tab(text: 'SERVICE REQUESTS'),
            Tab(text: 'ORDERS'),
          ],
        ),
        const SizedBox(height: 24),
        _buildInventorySearchAndList(ref, uid),
      ],
    );
  }

  Widget _buildInventorySearchAndList(WidgetRef ref, String uid) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 56,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderCol),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white38, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Search SKU, name or VIN...',
                      style: GoogleFonts.manrope(color: Colors.white38, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderCol),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white70, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ref.watch(sellerProductsProvider(uid)).when(
          data: (products) {
            if (products.isEmpty) {
              // Show dummy data to match the design if no real data
              return Column(
                children: [
                  _buildInventoryCard(
                    'V8 Engine Block - 2018 Ford F-150 Lariat',
                    'FRD-5520-X1',
                    '2,499.00',
                    'In Stock (1)',
                    'SALVAGE',
                    const Color(0xFFFF8A00),
                    'https://images.unsplash.com/photo-1597762137734-594e9608f27e?auto=format&fit=crop&q=80&w=200',
                  ),
                  const SizedBox(height: 16),
                  _buildInventoryCard(
                    'LED Headlight Assembly (Right)',
                    'BMW-L-2022-M3',
                    '845.00',
                    'Out of Stock',
                    'NEW OEM',
                    _accentBlue,
                    'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=200',
                  ),
                  const SizedBox(height: 16),
                  _buildInventoryCard(
                    'Alloy Wheel Rim 19" - Set of 4',
                    'WHL-99-TSL',
                    '1,100.00',
                    'Draft',
                    'USED',
                    const Color(0xFFA855F7),
                    null,
                  ),
                ],
              );
            }
            return Column(
              children: products.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildInventoryCard(
                  p.title,
                  p.id.substring(0, 8).toUpperCase(),
                  p.price.toStringAsFixed(2),
                  p.status == 'active' ? 'In Stock' : 'Out of Stock',
                  p.condition.toUpperCase(),
                  p.condition == 'new' ? _accentBlue : (p.condition == 'used' ? const Color(0xFFA855F7) : const Color(0xFFFF8A00)),
                  p.imageUrl,
                  clickCount: p.clickCount ?? 0,
                ),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(
    String title,
    String sku,
    String price,
    String status,
    String tag,
    Color tagColor,
    String? imageUrl, {
    int clickCount = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderCol),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  image: imageUrl != null && imageUrl.isNotEmpty 
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) 
                      : null,
                ),
                child: imageUrl == null || imageUrl.isEmpty 
                    ? const Icon(Icons.image_outlined, color: Colors.white10, size: 32) 
                    : null,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Colors.white38),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: $sku',
                  style: GoogleFonts.manrope(color: BoostDriveTheme.textDim, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '\$$price',
                      style: GoogleFonts.manrope(
                        color: _accentBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.contains('In Stock') 
                            ? const Color(0xFF00C853).withOpacity(0.1) 
                            : (status == 'Draft' ? Colors.orange.withOpacity(0.1) : Colors.white10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.manrope(
                          color: status.contains('In Stock') 
                              ? const Color(0xFF00C853) 
                              : (status == 'Draft' ? Colors.orange : Colors.white38),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 16, color: Colors.white38),
                    const SizedBox(width: 6),
                    Text(
                      'Clicks: $clickCount',
                      style: GoogleFonts.manrope(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Service Requests',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'VIEW ALL',
                style: GoogleFonts.manrope(
                  color: _accentBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.build_rounded, color: _accentBlue, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'INSTALLATION REQUEST',
                    style: GoogleFonts.manrope(
                      color: _accentBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Transmission Swap - Alex Johnson',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Linked Part: 2015 Camry Transmission (Used)',
                style: GoogleFonts.manrope(
                  color: BoostDriveTheme.textDim,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 56),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Accept Task',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
}
