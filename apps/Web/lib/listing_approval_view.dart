import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_fonts/google_fonts.dart';

class ListingApprovalView extends ConsumerStatefulWidget {
  const ListingApprovalView({super.key});

  @override
  ConsumerState<ListingApprovalView> createState() => _ListingApprovalViewState();
}

class _ListingApprovalViewState extends ConsumerState<ListingApprovalView> {
  Product? _selectedListing;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_selectedListing != null) {
      return _buildReviewer(_selectedListing!);
    }

    final pendingListingsAsync = ref.watch(pendingListingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Marketplace Listings',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            pendingListingsAsync.when(
              data: (list) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${list.length} PENDING',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: pendingListingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'All listings cleared!',
                          style: GoogleFonts.montserrat(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: listings.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) => _buildListingRow(listings[index]),
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

  Widget _buildListingRow(Product p) {
    return InkWell(
      onTap: () => setState(() => _selectedListing = p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
                image: p.imageUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(p.imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: p.imageUrl.isEmpty ? const Icon(Icons.image, color: Colors.grey) : null,
            ),
            const SizedBox(width: 24),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'N\$ ${p.price.toStringAsFixed(2)} • ${p.category.toUpperCase()}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Date
            Text(
              p.createdAt != null ? '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}' : 'Recent',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(width: 48),
            // Action
            TextButton(
              onPressed: () => setState(() => _selectedListing = p),
              child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
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
                                color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
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
                        Text(
                          'Seller ID: ${p.sellerId ?? "Unknown"}',
                          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
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
                          itemBuilder: (context, index) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                              image: DecorationImage(image: NetworkImage(p.imageUrls[index]), fit: BoxFit.cover),
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
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'ADMIN ACTIONS',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black45, letterSpacing: 1),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : () => _handleApproval(p, 'active'),
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
                            onPressed: _isLoading ? null : () => _showRejectionDialog(p),
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

  void _handleApproval(Product p, String status, {String? reason}) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(productServiceProvider).updateListingStatus(p.id, status, rejectionReason: reason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'active' ? 'Listing Approved!' : 'Listing Rejected'),
            backgroundColor: status == 'active' ? Colors.green : Colors.red,
          ),
        );
        setState(() {
          _selectedListing = null;
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

  void _showRejectionDialog(Product p) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Provide a reason for the seller:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Blurry images, missing parts details...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
                return;
              }
              Navigator.pop(context);
              _handleApproval(p, 'rejected', reason: reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
  }
}
