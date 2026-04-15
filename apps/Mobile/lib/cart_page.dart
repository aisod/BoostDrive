// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
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
  final Set<String> _processingPushIds = <String>{};

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

    final String? paymentChoice = await showDialog<String>(
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
            onPressed: () => Navigator.pop(context, 'manual'),
            child: const Text('Manual / Cash', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'pay2day'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.08)),
            child: const Text('Pay2Day'),
          ),
        ],
      ),
    );

    if (paymentChoice == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (paymentChoice == 'pay2day') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pay2Day integration is coming soon! For now, please proceed with cash or manual bank transfer.',
            ),
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    if (paymentChoice == 'manual') {
      _finishManualCheckout(context, ref, user, total, cartItems);
      return;
    }
    setState(() => _isLoading = false);
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
    final customerId = ref.watch(currentUserProvider)?.id;
    final pushesAsync = customerId == null ? null : ref.watch(_pendingCartPushesFamily(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pushesAsync != null)
            pushesAsync.when(
              data: (pushes) {
                if (pushes.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PARTS RECOMMENDED BY YOUR PROVIDER',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 10),
                    ...pushes.map((push) => _buildPushCard(push)),
                    const SizedBox(height: 20),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (e, _) => Text('Could not load provider recommendations: $e', style: const TextStyle(color: Colors.redAccent)),
            ),
          if (cartItems.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 64, color: BoostDriveTheme.textDim),
                    SizedBox(height: 16),
                    Text('Your cart is empty', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 18)),
                  ],
                ),
              ),
            )
          else
            ...cartItems.map((item) {
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'Remove item',
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).removeItem(item.product.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Item removed from cart')),
                                  );
                                },
                              ),
                              Text(
                                'N\$ ${item.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
        ],
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

  Widget _buildPushCard(Map<String, dynamic> push) {
    final pushId = push['id']?.toString() ?? '';
    final vehicle = push['vehicle_label']?.toString() ?? 'Vehicle';
    final notes = push['notes']?.toString() ?? '';
    final isProcessing = _processingPushIds.contains(pushId);
    final itemsAsync = ref.watch(_pushItemsFamily(pushId));
    return Card(
      color: BoostDriveTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(notes, style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            itemsAsync.when(
              data: (rows) {
                final total = rows.fold<double>(
                  0,
                  (sum, r) => sum + ((r['quantity'] as num?)?.toDouble() ?? 0) * ((r['unit_price'] as num?)?.toDouble() ?? 0),
                );
                return Text(
                  '${rows.length} part(s) • N\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                );
              },
              loading: () => const Text('Loading parts...', style: TextStyle(color: Colors.white54, fontSize: 12)),
              error: (e, _) => Text('$e', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: isProcessing ? null : () => _viewPushDetails(pushId),
                    child: const Text('VIEW DETAILS'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing ? null : () => _rejectPush(pushId),
                    child: const Text('DISMISS'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () => _acceptPush(pushId),
                    style: ElevatedButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
                    child: Text(isProcessing ? 'ADDING...' : 'ADD TO CART'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptPush(String pushId) async {
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;
    setState(() => _processingPushIds.add(pushId));
    try {
      final svc = ref.read(jobCardServiceProvider);
      final items = await svc.listCartPushItems(pushId);
      for (final it in items) {
        final product = Product(
          id: (it['product_id']?.toString().trim().isNotEmpty ?? false)
              ? it['product_id'].toString()
              : 'push_${it['id']}',
          title: it['part_name']?.toString() ?? 'Required part',
          subtitle: 'Recommended by your provider',
          price: (it['unit_price'] as num?)?.toDouble() ?? 0,
          imageUrls: const <String>[],
          location: 'Provider recommendation',
          category: 'part',
          condition: 'new',
          status: 'active',
          description: 'Part added from provider job card',
        );
        ref.read(cartProvider.notifier).addItem(
              product,
              quantity: (it['quantity'] as num?)?.toInt() ?? 1,
            );
      }
      await svc.setCartPushStatus(pushId: pushId, status: 'accepted');
      ref.invalidate(_pendingCartPushesFamily(uid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recommended parts added to cart.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add parts: $e')));
      }
    } finally {
      if (mounted) setState(() => _processingPushIds.remove(pushId));
    }
  }

  Future<void> _rejectPush(String pushId) async {
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;
    try {
      await ref.read(jobCardServiceProvider).setCartPushStatus(pushId: pushId, status: 'rejected');
      ref.invalidate(_pendingCartPushesFamily(uid));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not dismiss recommendation: $e')));
      }
    }
  }

  Future<void> _viewPushDetails(String pushId) async {
    final svc = ref.read(jobCardServiceProvider);
    final items = await svc.listCartPushItems(pushId);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Recommended Parts', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 360,
          child: items.isEmpty
              ? Text('No parts found for this recommendation.', style: TextStyle(color: BoostDriveTheme.textDim))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final qty = (it['quantity'] as num?)?.toInt() ?? 1;
                    final unit = (it['unit_price'] as num?)?.toDouble() ?? 0;
                    final total = qty * unit;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(it['part_name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                      subtitle: Text('Qty $qty × N\$${unit.toStringAsFixed(2)}',
                          style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
                      trailing: Text('N\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
        ],
      ),
    );
  }
}

final _pendingCartPushesFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async {
  return ref.read(jobCardServiceProvider).listPendingCartPushesForCustomer(customerId);
});

final _pushItemsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, pushId) async {
  return ref.read(jobCardServiceProvider).listCartPushItems(pushId);
});
