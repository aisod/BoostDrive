import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:boost_drive_web/messages_page.dart';

import 'edit_listing_page.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  late Product _currentProduct;
  bool _hasChanges = false;
  String? _existingConversationId;
  bool _hasTrackedClick = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _checkExistingConversation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackListingClick());
  }

  Future<void> _trackListingClick() async {
    if (_hasTrackedClick) return;
    _hasTrackedClick = true;

    // Don't count the seller viewing their own listing
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _currentProduct.sellerId != null && user.id == _currentProduct.sellerId) {
      return;
    }

    final updated = await ref.read(productServiceProvider).trackListingClick(_currentProduct.id);
    if (!mounted || updated == null) return;
    setState(() {
      _currentProduct = _currentProduct.copyWith(clickCount: updated);
    });
  }

  Future<void> _checkExistingConversation() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _currentProduct.sellerId == null) return;

    final conversationId = await ref.read(messageServiceProvider).findExistingConversation(
      productId: _currentProduct.id,
      buyerId: user.id,
      sellerId: _currentProduct.sellerId!,
    );

    if (mounted) {
      setState(() {
        _existingConversationId = conversationId;
      });
    }
  }

  void _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently delete this listing?', style: TextStyle(color: BoostDriveTheme.textDim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(productServiceProvider).deleteProduct(_currentProduct.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing deleted successfully')));
          Navigator.pop(context, true); // Return to home with refresh signal
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  void _handleEdit() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (context) => EditListingPage(product: _currentProduct)),
    );

    if (result is Product && mounted) {
      setState(() {
        _currentProduct = result;
      });
      // We also want to let the home page know something changed
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
      appBar: AppBar(
        title: Text(_currentProduct.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 400,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: _currentProduct.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        _currentProduct.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.broken_image, size: 100),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentProduct.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentProduct.subtitle,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: BoostDriveTheme.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'N\$ ${_currentProduct.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: BoostDriveTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined, size: 16, color: BoostDriveTheme.textDim),
                        const SizedBox(width: 6),
                        Text(
                          'Clicks: ${_currentProduct.clickCount ?? 0}',
                          style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Condition'),
                  Text(_currentProduct.condition.toUpperCase(), style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Location'),
                  Text(_currentProduct.location, style: const TextStyle(fontSize: 16)),
                  if (_currentProduct.fitment != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Vehicle Fitment'),
                    Text(
                      '${_currentProduct.fitment!['make']} ${_currentProduct.fitment!['model']} (${_currentProduct.fitment!['year']})',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                  if (_currentProduct.description.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Description'),
                    Text(
                      _currentProduct.description,
                      style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
                    ),
                  ],
                  const SizedBox(height: 40),
                  
                  if (isOwner) 
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleEdit,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Listing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleDelete,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withValues(alpha: 0.1),
                              foregroundColor: Colors.redAccent,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          if (_existingConversationId != null) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MessagesPage(initialConversationId: _existingConversationId),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Colors.white10),
                                  ),
                                ),
                                child: const Text(
                                  'View Conversation',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => _handleAction(context, ref),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BoostDriveTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                _currentProduct.category == 'rental' 
                                  ? 'Rent Now' 
                                  : (_existingConversationId != null ? 'Message Seller Again' : 'Message Seller'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
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
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: BoostDriveTheme.textDim,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
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

    if (!mounted) return;
    if (payOnline == null) return;

    if (payOnline) {
      // ignore: use_build_context_synchronously
      _startOnlinePayment(context, ref, user);
    } else {
      if (_currentProduct.category == 'rental') {
        // ignore: use_build_context_synchronously
        _handleRental(context, ref, user);
      } else {
        // ignore: use_build_context_synchronously
        _handleMessaging(context, ref, user);
      }
    }
  }

  void _startOnlinePayment(BuildContext context, WidgetRef ref, User user) {
    showDialog(
      context: context,
      builder: (context) => BoostPaymentDialog(
        amount: _currentProduct.price,
        productName: _currentProduct.title,
        onConfirm: (cardDetails) async {
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);
          navigator.pop(); // Close payment dialog

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

            if (!mounted) return;
            navigator.pop(); // Remove loading

            if (success) {
              // ignore: use_build_context_synchronously
              _showPaymentSuccess(context);
            } else {
              messenger.showSnackBar(
                const SnackBar(content: Text('Payment failed. Please try again.'), backgroundColor: Colors.red),
              );
            }
          } catch (e) {
            if (!mounted) return;
            navigator.pop(); // Remove loading
            messenger.showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
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

  void _handleMessaging(BuildContext context, WidgetRef ref, User user) async {
    final messageService = ref.read(messageServiceProvider);
    final TextEditingController messageController = TextEditingController(
      text: 'Hi, I\'m interested in this ${_currentProduct.title}. Is it still available?',
    );

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Message Seller',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start a conversation with the seller to discuss details and arrangement.',
              style: TextStyle(color: BoostDriveTheme.textDim),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BoostDriveTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Message'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor),
        ),
      );

      try {
        // Validation: Ensure product has a seller
        if (_currentProduct.sellerId == null || _currentProduct.sellerId!.isEmpty) {
          throw Exception('This product has no seller ID assigned in the database. Please update the listing.');
        }

        // Validation: Prevent self-messaging
        if (_currentProduct.sellerId == user.id) {
          throw Exception('You cannot message yourself about your own listing.');
        }

        final sellerId = _currentProduct.sellerId!;
        
        final conversationId = await messageService.getOrCreateConversation(
          productId: _currentProduct.id,
          buyerId: user.id,
          seller_id: sellerId,
        );

        await messageService.sendMessage(
          conversationId: conversationId,
          senderId: user.id,
          content: messageController.text,
        );

        if (context.mounted) {
          setState(() {
            _existingConversationId = conversationId;
          });
          Navigator.pop(context); // Remove loading
        }

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: BoostDriveTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.send_rounded, color: Colors.green, size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'Message Sent!',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your message has been delivered. You can continue the chat in your Messages hub.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BoostDriveTheme.textDim),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessagesPage(initialConversationId: conversationId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BoostDriveTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Go to Inbox'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('Acknowledged'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) Navigator.pop(context); // Remove loading
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _handleRental(BuildContext context, WidgetRef ref, User user) async {
    final bookingService = ref.read(bookingServiceProvider);
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Confirm Rental',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve booked this vehicle for rent. Do you want to proceed with ${_currentProduct.title}?',
              style: const TextStyle(color: BoostDriveTheme.textDim),
            ),
            const SizedBox(height: 12),
            const Text(
              'NOTE: Payment confirms booking.',
              style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Total Price:', style: TextStyle(color: Colors.white70)),
                  Text(
                    'N\$ ${_currentProduct.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BoostDriveTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor),
        ),
      );

      try {
        final success = await bookingService.createBooking(
          productId: _currentProduct.id,
          customerId: user.id,
          type: _currentProduct.category,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 1)),
          totalPrice: _currentProduct.price,
        );

        if (context.mounted) Navigator.pop(context); // Remove loading

        if (success != null && context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: BoostDriveTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'Booking Pending!',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Payment detected. Your rental is being finalized. Our team will contact you for pickup details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BoostDriveTheme.textDim),
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
                      child: const Text('Great!'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) Navigator.pop(context); // Remove loading
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
