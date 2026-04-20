import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'product_detail_page.dart';

class _SellerInfoCell extends ConsumerWidget {
  final String? sellerId;
  const _SellerInfoCell({required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sellerId?.isEmpty ?? true) {
      return const Text('System', style: TextStyle(color: Colors.black54));
    }
    
    return ref.watch(userProfileProvider(sellerId!)).when(
      data: (profile) {
        if (profile == null) return const Text('Unknown User', style: TextStyle(color: Colors.black54));
        
        final isVerified = profile.verificationStatus == 'approved' || profile.verificationStatus == 'verified';
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                profile.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            if (isVerified)
              const Tooltip(
                message: 'Verified Provider',
                child: Icon(Icons.verified, color: Colors.blue, size: 16),
              )
            else
              Tooltip(
                message: 'New or Unverified Seller',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withAlpha(128)),
                  ),
                  child: const Text('NEW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Text('Error', style: TextStyle(color: Colors.red)),
    );
  }
}

class ListingApprovalView extends ConsumerStatefulWidget {
  const ListingApprovalView({super.key});

  @override
  ConsumerState<ListingApprovalView> createState() => _ListingApprovalViewState();
}

class _ListingApprovalViewState extends ConsumerState<ListingApprovalView> {
  Product? _selectedListing;
  bool _isLoading = false;
  
  Set<String> _selectedListingIds = {};
  
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _statusFilter = 'Pending';
  String _categoryFilter = 'All';
  String _priceFilter = 'All';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> _rejectionReasons = [
    'Blurry or low-quality photos',
    'Price seems unrealistic (Potential Fraud)',
    'Incorrect Category',
    'Prohibited or dangerous item',
    'Other'
  ];

  String _normalizedListingStatus(Product p) {
    final raw = p.status.toLowerCase().trim();
    if (raw == 'available' || raw == 'active' || raw == 'approved') return 'approved';
    if (raw == 'rejected' || raw == 'declined') return 'rejected';
    if (raw == 'pending' || raw == 'awaiting_approval' || raw == 'submitted' || raw.isEmpty) return 'pending';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedListing != null) {
      return _buildReviewer(_selectedListing!);
    }

    final adminListingsAsync = ref.watch(adminListingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Listing Approval Dashboard',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            adminListingsAsync.when(
              data: (list) {
                final pendingCount = list.where((p) => _normalizedListingStatus(p) == 'pending').length;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pendingCount PENDING',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildToolbar(),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withAlpha(12)),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: adminListingsAsync.when(
              data: (listings) {
                // Apply Filters
                var filtered = listings;
                
                if (_statusFilter != 'All') {
                  final s = _statusFilter.toLowerCase();
                  filtered = filtered.where((p) => _normalizedListingStatus(p) == s).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered.where((p) => p.title.toLowerCase().contains(q) || (p.sellerId?.toLowerCase().contains(q) ?? false)).toList();
                }
                if (_categoryFilter != 'All') {
                  filtered = filtered.where((p) => p.category.toLowerCase() == _categoryFilter.toLowerCase()).toList();
                }
                if (_priceFilter != 'All') {
                  filtered = filtered.where((p) {
                    if (_priceFilter == 'Under N\$500') return p.price < 500;
                    if (_priceFilter == 'N\$500 - N\$2000') return p.price >= 500 && p.price <= 2000;
                    if (_priceFilter == 'Over N\$2000') return p.price > 2000;
                    return true;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withAlpha(50)),
                        const SizedBox(height: 16),
                        Text(
                          'No listings match your criteria!',
                          style: GoogleFonts.montserrat(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildTableHeader(filtered),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) => _buildListingRow(filtered[index]),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withAlpha(12)),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search title or ID...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 16),
          // Status Filter
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _statusFilter,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              items: ['All', 'Pending', 'Approved', 'Rejected']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) => setState(() => _statusFilter = val!),
            ),
          ),
          const SizedBox(width: 16),
          // Category Filter
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _categoryFilter,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              items: ['All', 'car', 'part', 'rental']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) => setState(() => _categoryFilter = val!),
            ),
          ),
          const SizedBox(width: 16),
          // Price Filter
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _priceFilter,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              items: ['All', 'Under N\$500', 'N\$500 - N\$2000', 'Over N\$2000']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) => setState(() => _priceFilter = val!),
            ),
          ),
          const SizedBox(width: 8),
          // Clear Button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _statusFilter = 'Pending';
                _categoryFilter = 'All';
                _priceFilter = 'All';
              });
            },
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Clear Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<Product> visibleListings) {
    final bool allSelected = _selectedListingIds.length == visibleListings.length && visibleListings.isNotEmpty;
    
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            activeColor: BoostDriveTheme.primaryColor,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedListingIds = visibleListings.map((e) => e.id).toSet();
                } else {
                  _selectedListingIds.clear();
                }
              });
            },
          ),
          const SizedBox(width: 12),
          const Expanded(flex: 3, child: Text('PRODUCT DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54))),
          const Expanded(flex: 2, child: Text('SELLER INFO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54))),
          const Expanded(flex: 1, child: Text('DATE SUBMITTED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54))),
          const SizedBox(width: 100), // Action area
          
          // Bulk Actions
          if (_selectedListingIds.isNotEmpty) ...[
            TextButton.icon(
              onPressed: _isLoading ? null : () => _handleBulkApprove(),
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 18),
              label: Text('Bulk Approve (${_selectedListingIds.length})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _isLoading ? null : () => _handleBulkReject(),
              icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
              label: const Text('Bulk Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListingRow(Product p) {
    final bool isSelected = _selectedListingIds.contains(p.id);

    return InkWell(
      onTap: () => setState(() => _selectedListing = p),
      hoverColor: Colors.orange.withAlpha(12),
      child: Container(
        color: isSelected ? Colors.orange.withAlpha(12) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              activeColor: BoostDriveTheme.primaryColor,
              onChanged: (val) {
                setState(() {
                  if (val == true) _selectedListingIds.add(p.id);
                  else _selectedListingIds.remove(p.id);
                });
              },
            ),
            const SizedBox(width: 12),
            // Thumbnail & Info (Flex 3)
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (p.imageUrls.isNotEmpty) _showQuickLook(p.imageUrls.first);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade100,
                        image: p.imageUrls.isNotEmpty
                            ? DecorationImage(image: NetworkImage(p.imageUrls.first), fit: BoxFit.cover)
                            : null,
                      ),
                      child: p.imageUrls.isEmpty ? const Icon(Icons.image, color: Colors.grey, size: 20) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'N\$ ${p.price.toStringAsFixed(2)} • ${p.category.toUpperCase()}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'raw status: ${p.status}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Seller Info (Flex 2)
            Expanded(
              flex: 2,
              child: _SellerInfoCell(sellerId: p.sellerId),
            ),
            // Date Submitted (Flex 1)
            Expanded(
              flex: 1,
              child: Text(
                p.createdAt != null ? '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}' : 'Recent',
                style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 16),
            // Action
            SizedBox(
              width: 84,
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedListing = p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: BoostDriveTheme.primaryColor,
                  side: const BorderSide(color: BoostDriveTheme.primaryColor),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewer(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _selectedListing = null),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Queue', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Details Column
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withAlpha(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: BoostDriveTheme.primaryColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.category.toUpperCase(),
                                style: const TextStyle(
                                  color: BoostDriveTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Text(
                              'N\$ ${p.price.toStringAsFixed(2)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: BoostDriveTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          p.title,
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Seller:  ', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                            _SellerInfoCell(sellerId: p.sellerId),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'DESCRIPTION',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black45, letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.description.isEmpty ? 'No description provided.' : p.description,
                          style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                        ),
                        const SizedBox(height: 48),
                        const Text(
                          'LISTING MEDIA',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black45, letterSpacing: 1),
                        ),
                        const SizedBox(height: 24),
                        if (p.imageUrls.isEmpty)
                          const Text('No images uploaded.', style: TextStyle(color: Colors.black54)),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: p.imageUrls.length,
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () => _showQuickLook(p.imageUrls[index]),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black.withAlpha(12)),
                                image: DecorationImage(image: NetworkImage(p.imageUrls[index]), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              // Decision Column
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withAlpha(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'ADMIN ACTIONS',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black45, letterSpacing: 1),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)));
                            },
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('PREVIEW IN MARKETPLACE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blueAccent,
                              side: const BorderSide(color: Colors.blueAccent),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                          if (p.status.toLowerCase() == 'pending') ...[
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleApproval(p.id, 'available'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('APPROVE LISTING', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _isLoading ? null : () => _showRejectionDialog(p.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('REJECT LISTING', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text(
                              'Approving this will make the listing immediately visible in the public marketplace.',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            Builder(
                              builder: (context) {
                                final s = p.status.toLowerCase();
                                final isApproved = s == 'available' || s == 'active';
                                final isRejected = s == 'rejected';
                                
                                final color = isApproved ? Colors.green : (isRejected ? Colors.red : Colors.grey);
                                final icon = isApproved ? Icons.check_circle : (isRejected ? Icons.cancel : Icons.info_outline);
                                final label = isApproved ? 'LISTING APPROVED' : (isRejected ? 'LISTING REJECTED' : 'STATUS: ${s.toUpperCase()}');

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: color),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(icon, color: color, size: 32),
                                      const SizedBox(height: 12),
                                      Text(
                                        label,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                                      ),
                                      if (p.rejectionReason != null && isRejected) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Reason: ${p.rejectionReason}',
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
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
    );
  }

  void _handleApproval(String productId, String status, {String? reason}) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(productServiceProvider).updateListingStatus(productId, status, rejectionReason: reason);
      ref.invalidate(adminListingsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'available' ? 'Listing Approved!' : 'Listing Rejected'),
            backgroundColor: status == 'available' ? Colors.green : Colors.red,
          ),
        );
        setState(() {
          if (_selectedListing?.id == productId) _selectedListing = null;
          _selectedListingIds.remove(productId);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleBulkApprove() async {
    setState(() => _isLoading = true);
    int success = 0;
    try {
      for (final id in _selectedListingIds) {
        await ref.read(productServiceProvider).updateListingStatus(id, 'available');
        success++;
      }
      ref.invalidate(adminListingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$success listings approved bulk!'), backgroundColor: Colors.green));
        setState(() { _selectedListingIds.clear(); _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bulk approve error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleBulkReject() async {
    final reason = await _promptForRejectionReason();
    if (reason == null) return; // User cancelled

    setState(() => _isLoading = true);
    int success = 0;
    try {
      for (final id in _selectedListingIds) {
        await ref.read(productServiceProvider).updateListingStatus(id, 'rejected', rejectionReason: reason);
        success++;
      }
      ref.invalidate(adminListingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$success listings rejected batch!'), backgroundColor: Colors.red));
        setState(() { _selectedListingIds.clear(); _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bulk reject error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showQuickLook(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8, maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 0, right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptForRejectionReason() async {
    String selectedReason = _rejectionReasons.first;
    final customLogicController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reject Listings', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select a reason for rejecting the selected items:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedReason,
                isExpanded: true,
                items: _rejectionReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) {
                  setDialogState(() { selectedReason = val!; });
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              if (selectedReason == 'Other') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: customLogicController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter custom reason...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final reason = selectedReason == 'Other' ? customLogicController.text.trim() : selectedReason;
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
                  return;
                }
                Navigator.pop(ctx, reason);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('REJECT'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectionDialog(String productId) async {
    final reason = await _promptForRejectionReason();
    if (reason != null && mounted) {
      _handleApproval(productId, 'rejected', reason: reason);
    }
  }
}
