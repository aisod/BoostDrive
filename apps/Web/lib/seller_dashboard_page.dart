import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

import 'package:boost_drive_web/edit_listing_page.dart';
import 'package:boost_drive_web/add_listing_page.dart';

/// Seller dashboard where users manage their marketplace listings.
class SellerDashboardPage extends ConsumerStatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  ConsumerState<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

/// State for tabs, scrolling, and seller listing actions.
class _SellerDashboardPageState extends ConsumerState<SellerDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  // Tabs: All, Active, Drafts, Sold/Rented, Rejected
  final List<String> _tabs = ['All', 'Active', 'Drafts', 'Sold/Rented', 'Rejected'];

  @override
  void initState() {
    super.initState();
    // Create tab controller for listing status tabs.
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks.
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read signed-in user; this page requires authentication.
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
        // Show dashboard when seller products are loaded.
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
        // Show spinner while product data is loading.
        loading: () => const Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor)),
        // Show readable error if products fail to load.
        error: (err, _) => Center(child: Text('Error loading listings: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  /// Builds top metrics row and "Add New Listing" button.
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

  /// Reusable stat card widget used in dashboard header.
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

  /// Builds tab bar for listing status filters.
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

  /// Filters products by selected tab and renders list or empty state.
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

  /// Empty-state section shown when current tab has no listings.
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

  /// Full listing card with image, meta, and inline action buttons.
  Widget _buildListingCard(Product p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Rejected banner
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
                // Thumbnail
                Container(
                  width: 200,
                  color: Colors.grey.shade200,
                  child: p.imageUrl.isNotEmpty
                      ? Image.network(p.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.car_crash, color: Colors.grey, size: 48))
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
                            _buildStatusTag(p.status),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                        Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.grey.shade400, size: 18),
                            const SizedBox(width: 6),
                            Text('${p.clickCount ?? 0} Views',
                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 24),
                            Icon(Icons.favorite, color: Colors.red.shade400, size: 18),
                            const SizedBox(width: 6),
                            Text('${p.saveCount ?? 0} Saved',
                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Inline Action Buttons ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Edit
                Expanded(
                  child: _actionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: Colors.blue.shade700,
                    onTap: () => _handleEdit(p),
                  ),
                ),
                const SizedBox(width: 8),

                // Promote — only for active listings
                if (p.status == 'active') ...[  
                  Expanded(
                    child: _actionBtn(
                      icon: Icons.campaign_outlined,
                      label: 'Promote',
                      color: BoostDriveTheme.primaryColor,
                      onTap: () => _handlePromote(p),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Mark Sold/Rented — only if not already sold/rented
                if (p.status != 'sold' && p.status != 'rented') ...[  
                  Expanded(
                    child: _actionBtn(
                      icon: Icons.check_circle_outline,
                      label: 'Mark Sold',
                      color: Colors.green.shade700,
                      onTap: () => _handleMarkSold(p),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Delete (compact icon button, always visible)
                IconButton(
                  tooltip: 'Delete Listing',
                  onPressed: () => _handleDelete(p),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable outlined action button for listing card actions.
  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Returns a status badge with color and label based on listing status.
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

  /// Opens listing edit page.
  void _handleEdit(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditListingPage(product: p)),
    );
  }

  /// Shows promote information dialog (feature notice and details).
  void _handlePromote(Product p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.campaign, color: BoostDriveTheme.primaryColor),
            const SizedBox(width: 12),
            Text('Promote Listing', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${p.title}"', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: BoostDriveTheme.primaryColor)),
            const SizedBox(height: 16),
            Text(
              'Boost your listing to reach more buyers on BoostDrive. Promoted listings appear at the top of search results and on the featured section.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BoostDriveTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: BoostDriveTheme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Promotion payments coming soon. You will be notified when this feature is live.',
                      style: TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  /// Lets seller mark listing as sold or rented, then updates backend status.
  void _handleMarkSold(Product p) async {
    final confirm = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mark as Sold or Rented?', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: Text(
          'How was "${p.title}" fulfilled? This will remove it from the active marketplace.',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.montserrat(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'rented'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.blue.shade700, side: BorderSide(color: Colors.blue.shade300)),
            child: Text('Mark Rented', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'sold'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
            child: Text('Mark Sold', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == null || !mounted) return;

    try {
      await ref.read(productServiceProvider).updateListingStatus(p.id, confirm);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${p.title}" marked as ${confirm}!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  /// Confirms and deletes listing from backend.
  void _handleDelete(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Listing?', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
        content: Text(
          'Are you sure you want to permanently delete "${p.title}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            child: Text('Delete', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ref.read(productServiceProvider).deleteProduct(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${p.title}" deleted.'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}
