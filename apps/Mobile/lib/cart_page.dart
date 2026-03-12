// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _isLoading = false;

  Future<void> _handleCheckout() async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to checkout.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final total = ref.read(cartProvider.notifier).grandTotal;

    final bool? payOnline = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Payment Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'How would you like to pay for your cart total?',
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

    if (payOnline == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (payOnline) {
      _startOnlinePayment(context, ref, user, total);
    } else {
      _finishManualCheckout(context, ref, user, total, cartItems);
    }
  }

  void _startOnlinePayment(BuildContext context, WidgetRef ref, User user, double total) {
    showDialog(
      context: context,
      builder: (context) => BoostPaymentDialog(
        amount: total,
        productName: 'Cart Total (${ref.read(cartProvider).length} items)',
        onConfirm: (cardDetails) async {
          if (!mounted) return;
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
              productId: 'cart_multiple',
              customerId: user.id,
              amount: total,
              paymentMethod: 'card',
              cardDetails: cardDetails,
            );

            if (!mounted) return;
            navigator.pop(); // Remove loading

            if (success) {
              ref.read(cartProvider.notifier).clearCart();
              if (mounted) _showPaymentSuccess(context, total);
            } else {
              messenger.showSnackBar(
                const SnackBar(content: Text('Payment failed. Please try again.'), backgroundColor: Colors.red),
              );
              setState(() => _isLoading = false);
            }
          } catch (e) {
            if (!mounted) return;
            navigator.pop(); // Remove loading
            messenger.showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  void _showPaymentSuccess(BuildContext context, double total) {
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
              'You have successfully paid N\$ ${total.toStringAsFixed(2)} for your cart items. A receipt has been sent to your email.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: BoostDriveTheme.textDim),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close cart
                },
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

  Future<void> _finishManualCheckout(BuildContext context, WidgetRef ref, User user, double total, List<CartItem> cartItems) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final checkoutService = ref.read(checkoutServiceProvider);
      await checkoutService.placeOrder(user.id, cartItems, total);

      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: BoostDriveTheme.surfaceDark,
          title: const Text('Order Placed!', style: TextStyle(color: Colors.white)),
          content: const Text('Thank you for your order. We will contact you shortly regarding delivery/pickup.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                navigator.pop(); // Close dialog
                navigator.pop(); // Close cart
              },
              child: const Text('OK', style: TextStyle(color: BoostDriveTheme.primaryColor)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).grandTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: BoostDriveTheme.textDim),
                  SizedBox(height: 16),
                  Text('Your cart is empty', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 18)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Dismissible(
                  key: ValueKey(item.product.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(cartProvider.notifier).removeItem(item.product.id);
                  },
                  child: Card(
                    color: BoostDriveTheme.surfaceDark,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Thumbnail
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[800],
                              image: item.product.imageUrls.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(item.product.imageUrls.first), fit: BoxFit.cover)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('N\$ ${item.product.price.toStringAsFixed(2)}', style: const TextStyle(color: BoostDriveTheme.primaryColor)),
                                if (item.product.category == 'rental') ...[
                                  Text(
                                    '${item.rentalStartDate?.toString().split(" ")[0]} - ${item.rentalEndDate?.toString().split(" ")[0]}',
                                    style: const TextStyle(fontSize: 10, color: BoostDriveTheme.textDim),
                                  ),
                                ] else ...[
                                  Text('Qty: ${item.quantity}', style: const TextStyle(fontSize: 12, color: BoostDriveTheme.textDim)),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            'N\$ ${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: BoostDriveTheme.surfaceDark,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 18, color: BoostDriveTheme.textDim)),
                  Text(
                    'N\$ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cartItems.isEmpty || _isLoading ? null : _handleCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoostDriveTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
