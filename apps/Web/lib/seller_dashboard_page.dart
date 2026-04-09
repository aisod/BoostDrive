import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

import 'package:boost_drive_web/add_listing_page.dart';

class SellerDashboardPage extends ConsumerStatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  ConsumerState<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends ConsumerState<SellerDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  // Tabs: All, Active, Drafts, Sold/Rented, Rejected
  final List<String> _tabs = ['All', 'Active', 'Drafts', 'Sold/Rented', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Please log in', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Dark-themed background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'My Listings',
          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ref.watch(sellerProductsProvider(user.id)).when(
        data: (products) {
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderStats(products),
                const SizedBox(height: 48),
                _buildTabs(),
                const SizedBox(height: 32),
                _buildFilteredListings(products),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor)),
        error: (err, _) => Center(child: Text('Error loading listings: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildHeaderStats(List<Product> products) {
    int activeCount = products.where((p) => p.status == 'active').length;
    int pendingCount = products.where((p) => p.status == 'pending').length;
    int totalViews = products.fold(0, (sum, p) => sum + (p.clickCount ?? 0));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Overview',
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildStatBox('Active Listings', activeCount.toString(), Icons.inventory_2_outlined),
                  const SizedBox(width: 24),
                  _buildStatBox('Pending Approval', pendingCount.toString(), Icons.hourglass_empty),
                  const SizedBox(width: 24),
                  _buildStatBox('Total Views / Leads', totalViews.toString(), Icons.trending_up),
                ],
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingPage()));
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add New Listing',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: BoostDriveTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: BoostDriveTheme.primaryColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: BoostDriveTheme.primaryColor,
        indicatorWeight: 4,
        labelColor: BoostDriveTheme.primaryColor,
        unselectedLabelColor: Colors.white60,
        tabs: _tabs.map((t) => Tab(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(t, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildFilteredListings(List<Product> products) {
    String currentTab = _tabs[_tabController.index];
    
    List<Product> filtered = products.where((p) {
      if (currentTab == 'All') return true;
      if (currentTab == 'Active') return p.status == 'active';
      if (currentTab == 'Drafts') return p.status == 'draft';
      if (currentTab == 'Sold/Rented') return p.status == 'sold' || p.status == 'rented';
      if (currentTab == 'Rejected') return p.status == 'rejected';
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(currentTab);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return _buildListingCard(filtered[index]);
      },
    );
  }

  Widget _buildEmptyState(String currentTab) {
    return Container(
      padding: const EdgeInsets.all(64),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            currentTab == 'Rejected' ? Icons.warning_amber_rounded : Icons.store_mall_directory_outlined, 
            size: 80, 
            color: BoostDriveTheme.primaryColor.withValues(alpha: 0.5)
          ),
          const SizedBox(height: 24),
          Text(
            currentTab == 'All' || currentTab == 'Active' 
              ? "You haven't listed anything yet!"
              : "No $currentTab listings found.",
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Start selling your spare parts or vehicles to the BoostDrive community today.",
            style: const TextStyle(color: Colors.white60, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
             onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingPage()));
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: BoostDriveTheme.primaryColor,
               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
             child: Text(
               'Create Your First Listing',
               style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Product p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White cards on dark background as requested
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // If rejected, show feedback loop banner at the very top of the card
          if (p.status == 'rejected')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your listing was rejected because: ${p.rejectionReason ?? "It violated marketplace guidelines. Please review and update."}',
                      style: GoogleFonts.montserrat(color: Colors.red.shade900, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail Image
                Container(
                  width: 200,
                  color: Colors.grey.shade200,
                  child: p.imageUrl.isNotEmpty
                    ? Image.network(p.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.car_crash, color: Colors.grey, size: 48))
                    : const Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
                ),
                
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.category.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  color: Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            
                            // Status Tag
                            _buildStatusTag(p.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Title & Price
                        Text(
                          p.title,
                          style: GoogleFonts.montserrat(
                            color: Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'N\$ ${p.price.toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(
                            color: BoostDriveTheme.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        
                        const Spacer(),
                        const SizedBox(height: 16),
                        
                        // Performance Metrics (Views & Saves)
                        Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.grey.shade400, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${p.clickCount ?? 0} Views',
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 24),
                            Icon(Icons.favorite, color: Colors.red.shade400, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${p.saveCount ?? 0} Saved',
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Inline Action Menu
                Container(
                  width: 64,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black54),
                    onSelected: (action) => _handleCardAction(action, p),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Edit')])),
                      if (p.status != 'sold' && p.status != 'rented')
                        const PopupMenuItem(value: 'sold', child: Row(children: [Icon(Icons.check_circle_outline, size: 20), SizedBox(width: 12), Text('Mark as Sold/Rented')])),
                      if (p.status == 'active')
                        const PopupMenuItem(value: 'promote', child: Row(children: [Icon(Icons.campaign, size: 20, color: BoostDriveTheme.primaryColor), SizedBox(width: 12), Text('Promote', style: TextStyle(color: BoostDriveTheme.primaryColor))])),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
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

  Widget _buildStatusTag(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        bg = BoostDriveTheme.primaryColor.withValues(alpha: 0.15);
        fg = BoostDriveTheme.primaryColor;
        label = 'ACTIVE';
        break;
      case 'pending':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = 'PENDING';
        break;
      case 'rejected':
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        label = 'REJECTED';
        break;
      case 'sold':
      case 'rented':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = status.toUpperCase();
        break;
      case 'draft':
      default:
        bg = Colors.blueGrey.shade100;
        fg = Colors.blueGrey.shade800;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  void _handleCardAction(String action, Product p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action "$action" triggered for ${p.title}. (Mocked action)')),
    );
  }
}
