import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'cart_page.dart';

import 'edit_listing_page.dart';
import 'chat_page.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  late Product _currentProduct;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
  }

  void _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to permanently delete this listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(productServiceProvider).deleteProduct(_currentProduct.id);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing deleted')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  void _handleEdit() async {
    final result = await Navigator.push<dynamic>(
      context, 
      MaterialPageRoute(builder: (context) => EditListingPage(product: _currentProduct))
    );
    if (result is Product && mounted) {
      setState(() {
        _currentProduct = result;
      });
      _hasChanges = true;
    } else if (result == true && mounted) {
      _hasChanges = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user;
    final isOwner = _currentProduct.sellerId == user?.id;

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''), 
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 350,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: _currentProduct.imageUrls.isNotEmpty ? _currentProduct.imageUrls.length : 1,
                    itemBuilder: (context, index) {
                      if (_currentProduct.imageUrls.isEmpty) {
                         return Container(color: Colors.grey[900], child: const Icon(Icons.image_not_supported, size: 50));
                      }
                      return Image.network(
                        _currentProduct.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      );
                    },
                  ),
                  if (_currentProduct.imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _currentProduct.imageUrls.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentProduct.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentProduct.subtitle,
                    style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'N\$ ${_currentProduct.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentProduct.condition.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: BoostDriveTheme.textDim, size: 18),
                      const SizedBox(width: 8),
                      Text(_currentProduct.location, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  
                  if (_currentProduct.fitment != null) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle('Vehicle Fitment'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.car_repair, color: BoostDriveTheme.primaryColor),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_currentProduct.fitment!['make']} ${_currentProduct.fitment!['model']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Year: ${_currentProduct.fitment!['year']}',
                                style: const TextStyle(color: BoostDriveTheme.textDim),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_currentProduct.description.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle('Description'),
                    const SizedBox(height: 12),
                    Text(
                      _currentProduct.description,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BoostDriveTheme.surfaceDark,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: SafeArea(
          child: isOwner 
            ? Row(
                children: [
                   Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      onPressed: () => _openChat(context),
                      icon: const Icon(Icons.chat_bubble_outline, color: BoostDriveTheme.primaryColor),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAction(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BoostDriveTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _currentProduct.category == 'rental' ? 'Book Now' : 'Add to Cart',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  void _openChat(BuildContext context) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to message the seller')));
      return;
    }

    if (_currentProduct.sellerId == user.id) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot message yourself')));
       return;
    }

    try {
      final messageService = ref.read(messageServiceProvider);
      final conversationId = await messageService.getOrCreateConversation(
        productId: _currentProduct.id,
        buyerId: user.id,
        seller_id: _currentProduct.sellerId!,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: conversationId,
              productTitle: _currentProduct.title,
              buyerId: user.id,
              sellerId: _currentProduct.sellerId!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: BoostDriveTheme.textDim,
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to continue.')),
      );
      return;
    }

    final bool? payOnline = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Payment Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'How would you like to proceed with this listing?',
          style: TextStyle(color: BoostDriveTheme.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Arrange Personally', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
            child: const Text('Pay Securely Online'),
          ),
        ],
      ),
    );

    if (payOnline == null) return;

    if (payOnline) {
      _startOnlinePayment(context, ref, user);
    } else {
      _handleManualAction(context, ref, user);
    }
  }

  void _startOnlinePayment(BuildContext context, WidgetRef ref, User user) {
    showDialog(
      context: context,
      builder: (context) => BoostPaymentDialog(
        amount: _currentProduct.price,
        productName: _currentProduct.title,
        onConfirm: (cardDetails) async {
          Navigator.pop(context); // Close payment dialog
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor),
            ),
          );

          try {
            final paymentService = ref.read(paymentServiceProvider);
            final success = await paymentService.processPayment(
              productId: _currentProduct.id,
              customerId: user.id,
              amount: _currentProduct.price,
              paymentMethod: 'card',
              cardDetails: cardDetails,
            );

            if (mounted) Navigator.pop(context); // Remove loading

            if (success && mounted) {
              _showPaymentSuccess(context);
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment failed. Please try again.'), backgroundColor: Colors.red),
              );
            }
          } catch (e) {
            if (mounted) Navigator.pop(context); // Remove loading
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _showPaymentSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.verified_user_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'You have successfully paid N\$ ${_currentProduct.price.toStringAsFixed(2)} for ${_currentProduct.title}. A receipt has been sent to your email.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: BoostDriveTheme.textDim),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BoostDriveTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Understood'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleManualAction(BuildContext context, WidgetRef ref, User user) async {
    // Rental specific logic
    if (_currentProduct.category == 'rental') {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: BoostDriveTheme.primaryColor,
                onPrimary: Colors.white,
                surface: BoostDriveTheme.surfaceDark,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        ref.read(cartProvider.notifier).addItem(
          _currentProduct, 
          startDate: picked.start, 
          endDate: picked.end
        );
        if (context.mounted) {
          _showAddedSnackBar(context);
        }
      }
    } else {
      // Standard Product
      ref.read(cartProvider.notifier).addItem(_currentProduct);
      _showAddedSnackBar(context);
    }
  }

  void _showAddedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to Cart'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            // We can't easily navigate to CartPage from here without context issues if we pop?
            // Just pushing onto stack is fine.
             Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const CartPage())
            );
          },
        ),
      ),
    );
  }
}
