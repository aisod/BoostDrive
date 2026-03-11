import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_fonts/google_fonts.dart';

class SellerDashboardPage extends ConsumerStatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  ConsumerState<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends ConsumerState<SellerDashboardPage> with SingleTickerProviderStateMixin {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSellerHeader(ref, user.id),
          const SizedBox(height: 48),
          _buildPerformanceSection(ref, user.id),
          const SizedBox(height: 48),
          _buildTabSection(ref, user.id),
          const SizedBox(height: 48),
          _buildServiceRequestsSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSellerHeader(WidgetRef ref, String uid) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: _cardBg,
              backgroundImage: profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null,
              child: profile.profileImg.isEmpty ? const Icon(Icons.person, color: Colors.white54, size: 32) : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BoostDrive Seller',
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Metro Salvage & Parts • Top Rated Performance',
                    style: GoogleFonts.manrope(
                      color: BoostDriveTheme.textDim,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search, color: Colors.white70, size: 32),
            ),
            const SizedBox(width: 12),
            _buildNotificationIcon(true),
            const SizedBox(width: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 24),
              label: const Text('Add New Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(220, 64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildNotificationIcon(bool hasUnread) {
    return Stack(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 32),
        ),
        if (hasUnread)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4D),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0D1117), width: 2.5),
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
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderCol),
              ),
              child: Row(
                children: [
                  Text(
                    'Last 7 Days',
                    style: GoogleFonts.manrope(
                      color: _accentBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, color: _accentBlue, size: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildPerformanceCard('Total Sales', '\$12,450', '+12%', true)),
            const SizedBox(width: 24),
            Expanded(child: _buildPerformanceCard('Active Listings', '1,248', '+3%', true)),
            const SizedBox(width: 24),
            Expanded(child: _buildPerformanceCard('Pending Orders', '14', '0%', false)),
            const SizedBox(width: 24),
            Expanded(child: _buildPerformanceCard('Store Views', '2.8k', '+8%', true)),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(String label, String value, String trend, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              color: BoostDriveTheme.textDim,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                trend == '0%' ? Icons.arrow_forward : (isPositive ? Icons.trending_up : Icons.trending_down),
                color: trend == '0%' ? Colors.orange : (isPositive ? const Color(0xFF00C853) : const Color(0xFFFF4D4D)),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                trend,
                style: GoogleFonts.manrope(
                  color: trend == '0%' ? Colors.orange : (isPositive ? const Color(0xFF00C853) : const Color(0xFFFF4D4D)),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
        Row(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: _accentBlue,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: _accentBlue,
              unselectedLabelColor: BoostDriveTheme.textDim,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1,
              ),
              tabs: const [
                Tab(text: 'INVENTORY'),
                Tab(text: 'SERVICE REQUESTS'),
                Tab(text: 'ORDERS'),
              ],
            ),
          ],
        ),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 32),
        _buildInventorySearchAndGrid(ref, uid),
      ],
    );
  }

  Widget _buildInventorySearchAndGrid(WidgetRef ref, String uid) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: 64,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderCol),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white38, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      'Search SKU, name or VIN...',
                      style: GoogleFonts.manrope(color: Colors.white38, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderCol),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white70, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ref.watch(sellerProductsProvider(uid)).when(
          data: (products) {
            if (products.isEmpty) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 2.8,
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
                  _buildInventoryCard(
                    'LED Headlight Assembly (Right)',
                    'BMW-L-2022-M3',
                    '845.00',
                    'Out of Stock',
                    'NEW OEM',
                    _accentBlue,
                    'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=200',
                  ),
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
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 2.8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return _buildInventoryCard(
                  p.title,
                  p.id.substring(0, 8).toUpperCase(),
                  p.price.toStringAsFixed(2),
                  p.status == 'active' ? 'In Stock' : 'Out of Stock',
                  p.condition.toUpperCase(),
                  p.condition == 'new' ? _accentBlue : (p.condition == 'used' ? const Color(0xFFA855F7) : const Color(0xFFFF8A00)),
                  p.imageUrl,
                  clickCount: p.clickCount ?? 0,
                );
              },
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _borderCol),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  image: imageUrl != null && imageUrl.isNotEmpty 
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) 
                      : null,
                ),
                child: imageUrl == null || imageUrl.isEmpty 
                    ? const Icon(Icons.image_outlined, color: Colors.white10, size: 40) 
                    : null,
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Colors.white38, size: 24),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'SKU: $sku',
                  style: GoogleFonts.manrope(color: BoostDriveTheme.textDim, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '\$$price',
                      style: GoogleFonts.manrope(
                        color: _accentBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status.contains('In Stock') 
                            ? const Color(0xFF00C853).withOpacity(0.1) 
                            : (status == 'Draft' ? Colors.orange.withOpacity(0.1) : Colors.white10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.manrope(
                          color: status.contains('In Stock') 
                              ? const Color(0xFF00C853) 
                              : (status == 'Draft' ? Colors.orange : Colors.white38),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined, color: Colors.white38, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Clicks: $clickCount',
                      style: GoogleFonts.manrope(
                        color: Colors.white38,
                        fontSize: 13,
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
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'VIEW ALL',
                style: GoogleFonts.manrope(
                  color: _accentBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _borderCol),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.build_rounded, color: _accentBlue, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSTALLATION REQUEST',
                      style: GoogleFonts.manrope(
                        color: _accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transmission Swap - Alex Johnson',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Linked Part: 2015 Camry Transmission (Used)',
                      style: GoogleFonts.manrope(
                        color: BoostDriveTheme.textDim,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(160, 64),
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 64),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Accept Task',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16),
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
