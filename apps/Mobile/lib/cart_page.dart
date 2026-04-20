// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'messages_page.dart';

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

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Checkout Options',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Choose how you want to continue:',
          style: TextStyle(color: BoostDriveTheme.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'message_seller'),
            child: const Text('Message Seller Directly'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'online_coming_soon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BoostDriveTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Online Payments (Coming Soon)'),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'online_coming_soon') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Online payments are coming soon. Please message the seller directly for now.'),
        ),
      );
      return;
    }
    if (action == 'message_seller') {
      await _messageSellerDirectly(user, cartItems);
    }
  }

  Future<void> _messageSellerDirectly(User user, List<CartItem> cartItems) async {
    final bySeller = <String, List<CartItem>>{};
    for (final item in cartItems) {
      final sellerId = item.product.sellerId?.trim() ?? '';
      if (sellerId.isEmpty || sellerId == user.id) continue;
      bySeller.putIfAbsent(sellerId, () => <CartItem>[]).add(item);
    }

    if (bySeller.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No seller found for these cart items.')),
      );
      return;
    }

    String? selectedSellerId;
    if (bySeller.length == 1) {
      selectedSellerId = bySeller.keys.first;
    } else {
      selectedSellerId = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: BoostDriveTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Select Seller',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: bySeller.entries.map((entry) {
                final sellerId = entry.key;
                final items = entry.value;
                final title = items.first.product.title;
                return ListTile(
                  title: Text(title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${items.length} item(s)',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () => Navigator.pop(ctx, sellerId),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );
    }

    if (!mounted || selectedSellerId == null) return;
    final sellerItems = bySeller[selectedSellerId]!;
    setState(() => _isLoading = true);
    try {
      final seed = sellerItems.first;
      final conversationId = await ref.read(messageServiceProvider).getOrCreateConversation(
            productId: seed.product.id,
            buyerId: user.id,
            seller_id: selectedSellerId,
          );

      final summary = sellerItems
          .map((e) => '${e.product.title} (x${e.quantity})')
          .join(', ');
      await ref.read(messageServiceProvider).sendMessage(
            conversationId: conversationId,
            senderId: user.id,
            content: 'Hi, I want to checkout these item(s): $summary',
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MessagesPage(initialConversationId: conversationId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open seller chat: $e'), backgroundColor: Colors.red),
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
