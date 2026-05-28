import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

import 'package:boost_drive_web/add_listing_page.dart';
import 'package:boost_drive_web/dashboard_shell.dart';
import 'package:boost_drive_web/edit_listing_page.dart';
import 'package:boost_drive_web/user_support_view.dart';

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
  DashboardPortalSection _portalSection = DashboardPortalSection.dashboard;
  
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

    final profile = ref.watch(userProfileProvider(user.id)).value;
    final displayName = profile?.fullName ?? 'Seller';

    return DashboardAppShell(
      activeTab: DashboardNavTab.listings,
      sidebar: SellerDashboardSidebar(
        activeSection: _portalSection,
        onSectionSelected: (s) => setState(() => _portalSection = s),
        onAddListing: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingPage())),
        onSettings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsPage())),
      ),
      child: DashboardPageContainer(
        child: _buildPortalBody(user.id, displayName),
      ),
    );
  }

  Widget _buildPortalBody(String userId, String displayName) {
    switch (_portalSection) {
      case DashboardPortalSection.orders:
        return const DashboardPortalPlaceholder(
          title: 'Orders',
          message: 'Order management views will appear here. Your existing order data and workflows are unchanged.',
          icon: Icons.shopping_cart_outlined,
        );
      case DashboardPortalSection.serviceHistory:
        return const DashboardPortalPlaceholder(
          title: 'Service History',
          message: 'Service history for your seller account will appear here.',
          icon: Icons.history,
        );
      case DashboardPortalSection.analytics:
        return _buildAnalyticsPlaceholder();
      case DashboardPortalSection.support:
        return DashboardCard(
          padding: const EdgeInsets.all(8),
          child: UserSupportView(userId: userId, userType: 'seller', embedded: true),
        );
      case DashboardPortalSection.settings:
        return DashboardPortalPlaceholder(
          title: 'Settings',
          message: 'Use the Settings link in the sidebar to open profile settings.',
          icon: Icons.settings_outlined,
        );
      case DashboardPortalSection.dashboard:
        return ref.watch(sellerProductsProvider(userId)).when(
          data: (products) {
            final palette = DashboardPalette.of(context);
            return ColoredBox(
              color: palette.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderStats(products),
                  const SizedBox(height: 24),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  _buildFilteredListings(products),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading listings: $err', style: TextStyle(color: DashboardPalette.of(context).error))),
        );
    }
  }

  Widget _buildAnalyticsPlaceholder() {
    final palette = DashboardPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeader(
          title: 'Analytics',
          subtitle: 'Track listing performance and engagement.',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 700;
            final cards = [
              DashboardStatCard(label: 'Total Views', value: '—', icon: Icons.visibility_outlined),
              DashboardStatCard(label: 'Inquiries', value: '—', icon: Icons.mail_outline),
              DashboardStatCard(label: 'Conversion', value: '—', icon: Icons.percent),
            ];
            if (narrow) {
              return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList());
            }
            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
                const SizedBox(width: 16),
                Expanded(child: cards[2]),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        DashboardCard(
          elevated: true,
          padding: const EdgeInsets.all(32),
          child: Text(
            'Detailed analytics charts will appear here. Listing metrics continue to use your existing data sources.',
            style: DashboardTypography.bodyMd(palette),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStats(List<Product> products) {
    final palette = DashboardPalette.of(context);
    final activeCount = products.where((p) => p.status == 'active').length;
    final pendingCount = products.where((p) => p.status == 'pending').length;
    final totalViews = products.fold(0, (sum, p) => sum + (p.clickCount ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeader(
          title: 'My Listings',
          subtitle: 'Manage your active vehicle listings and leads.',
          trailing: DashboardPillButton(
            label: 'Add New Listing',
            icon: Icons.add_circle_outline,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingPage())),
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;
            final stats = [
              DashboardStatCard(label: 'Active Listings', value: '$activeCount', icon: Icons.check_circle_outline),
              DashboardStatCard(label: 'Pending Approval', value: '$pendingCount', icon: Icons.pending_actions_outlined, iconTint: palette.tertiaryFixed),
              DashboardStatCard(label: 'Total Views / Leads', value: '$totalViews', icon: Icons.trending_up),
            ];
            if (isNarrow) {
              return Column(children: stats.map((s) => Padding(padding: const EdgeInsets.only(bottom: 16), child: s)).toList());
            }
            return Row(
              children: [
                Expanded(child: stats[0]),
                const SizedBox(width: 16),
                Expanded(child: stats[1]),
                const SizedBox(width: 16),
                Expanded(child: stats[2]),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final palette = DashboardPalette.of(context);
    return ColoredBox(
      color: palette.background,
      child: TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: palette.primaryBright,
      indicatorWeight: 3,
      labelColor: palette.primary,
      unselectedLabelColor: palette.body,
      dividerColor: palette.cardBorder.withValues(alpha: 0.35),
      tabs: _tabs
          .map(
            (t) => Tab(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(t, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
              ),
            ),
          )
          .toList(),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        if (isMobile) {
          const spacing = 12.0;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.68,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildListingCardCompact(filtered[index]),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) => _buildListingCardWide(filtered[index]),
        );
      },
    );
  }

  /// Empty-state section shown when current tab has no listings.
  Widget _buildEmptyState(String currentTab) {
    final palette = DashboardPalette.of(context);
    return DashboardCard(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            currentTab == 'Rejected' ? Icons.warning_amber_rounded : Icons.store_mall_directory_outlined,
            size: 72,
            color: palette.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 20),
          Text(
            currentTab == 'All' || currentTab == 'Active'
                ? "You haven't listed anything yet!"
                : 'No $currentTab listings found.',
            style: GoogleFonts.montserrat(color: palette.title, fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Start selling your spare parts or vehicles to the BoostDrive community today.',
            style: GoogleFonts.montserrat(color: palette.body, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          DashboardPillButton(
            label: 'Create Your First Listing',
            icon: Icons.add,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingPage())),
          ),
        ],
      ),
    );
  }

  /// Compact listing tile for mobile two-column grid (no horizontal overflow).
  Widget _buildListingCardCompact(Product p) {
    final palette = DashboardPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder.withValues(alpha: 0.45)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
        onTap: () => _handleEdit(p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (p.status == 'rejected')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.red.shade50,
                child: Text(
                  'Rejected',
                  style: GoogleFonts.montserrat(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: palette.surfaceContainer,
                child: p.imageUrl.isNotEmpty
                    ? Image.network(
                        p.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.directions_car, color: palette.muted, size: 32),
                      )
                    : Icon(Icons.image_not_supported, color: palette.muted, size: 32),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.category.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: palette.muted,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildStatusTag(p.status, compact: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.title,
                    style: GoogleFonts.montserrat(
                      color: palette.title,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'N\$ ${p.price.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                      color: palette.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 12, color: palette.muted),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${p.clickCount ?? 0}',
                          style: GoogleFonts.montserrat(fontSize: 10, color: palette.body, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.favorite_border, size: 12, color: palette.muted),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${p.saveCount ?? 0}',
                          style: GoogleFonts.montserrat(fontSize: 10, color: palette.body, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.more_vert, size: 20, color: palette.body),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _handleEdit(p);
                            case 'promote':
                              _handlePromote(p);
                            case 'sold':
                              _handleMarkSold(p);
                            case 'delete':
                              _handleDelete(p);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          if (p.status == 'active')
                            const PopupMenuItem(value: 'promote', child: Text('Promote')),
                          if (p.status != 'sold' && p.status != 'rented')
                            const PopupMenuItem(value: 'sold', child: Text('Mark Sold')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Full-width listing card for desktop (horizontal layout).
  Widget _buildListingCardWide(Product p) {
    final palette = DashboardPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
        boxShadow: palette.cardShadowLow,
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
  Widget _buildStatusTag(String status, {bool compact = false}) {
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
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12, vertical: compact ? 3 : 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: compact ? 8 : 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
