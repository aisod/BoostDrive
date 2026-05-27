// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:google_fonts/google_fonts.dart';
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

    final action = await ShopCommerceUi.showCheckoutOptionsDialog(context);

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
      selectedSellerId = await ShopCommerceUi.showSelectSellerDialog(
        context,
        sellers: bySeller.entries
            .map(
              (e) => (
                sellerId: e.key,
                title: e.value.first.product.title,
                itemCount: e.value.length,
              ),
            )
            .toList(),
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
    final palette = DashboardPalette.of(context);
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).grandTotal;
    final customerId = ref.watch(currentUserProvider)?.id;
    final pushesAsync = customerId == null ? null : ref.watch(_pendingCartPushesFamily(customerId));

    return Scaffold(
      backgroundColor: palette.background,
      appBar: ShopCommerceUi.glassAppBar(
        context: context,
        palette: palette,
        title: 'My Cart',
        onColoredHeader: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ShopCommerceUi.marginMobile,
          8,
          ShopCommerceUi.marginMobile,
          120,
        ),
        children: [
          if (pushesAsync != null)
            pushesAsync.when(
              data: (pushes) {
                if (pushes.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShopCommerceUi.cartSectionHeading(
                      palette,
                      'Parts recommended by your provider',
                    ),
                    ...pushes.map((push) => _buildPushCard(palette, push)),
                    const SizedBox(height: 20),
                  ],
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: palette.primaryContainer,
                  backgroundColor: palette.surfaceContainer,
                ),
              ),
              error: (e, _) => Text(
                'Could not load provider recommendations: $e',
                style: TextStyle(color: palette.error),
              ),
            ),
          if (cartItems.isEmpty)
            ShopCommerceUi.cartEmptyState(palette)
          else ...[
            ShopCommerceUi.cartSectionHeading(
              palette,
              'Items in cart (${cartItems.length})',
            ),
            ...cartItems.map((item) {
              final isRental = item.product.category == 'rental';
              final meta = isRental
                  ? '${item.rentalStartDate?.toString().split(' ')[0] ?? ''} - ${item.rentalEndDate?.toString().split(' ')[0] ?? ''}'
                  : 'Qty: ${item.quantity}';
              return Dismissible(
                key: ValueKey(item.product.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: palette.error,
                    borderRadius: BorderRadius.circular(ShopCommerceUi.radiusCard),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref.read(cartProvider.notifier).removeItem(item.product.id);
                },
                child: ShopCommerceUi.cartLineItem(
                  palette: palette,
                  title: item.product.title,
                  subtitle: item.product.subtitle.isNotEmpty
                      ? item.product.subtitle
                      : item.product.location,
                  unitPriceLabel: 'N\$ ${item.product.price.toStringAsFixed(2)}',
                  lineTotalLabel: 'N\$ ${item.totalPrice.toStringAsFixed(2)}',
                  metaLabel: meta,
                  isRental: isRental,
                  imageUrl: item.product.imageUrls.isNotEmpty ? item.product.imageUrls.first : null,
                  onRemove: () {
                    ref.read(cartProvider.notifier).removeItem(item.product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item removed from cart')),
                    );
                  },
                ),
              );
            }),
          ],
        ],
      ),
      bottomNavigationBar: ShopCommerceUi.cartFooter(
        palette: palette,
        totalLabel: 'N\$ ${total.toStringAsFixed(2)}',
        checkoutEnabled: cartItems.isNotEmpty,
        loading: _isLoading,
        onCheckout: _handleCheckout,
      ),
    );
  }

  Widget _buildPushCard(DashboardPalette palette, Map<String, dynamic> push) {
    final pushId = push['id']?.toString() ?? '';
    final vehicle = push['vehicle_label']?.toString() ?? 'Vehicle';
    final notes = push['notes']?.toString() ?? '';
    final isProcessing = _processingPushIds.contains(pushId);
    final itemsAsync = ref.watch(_pushItemsFamily(pushId));

    final summaryLine = itemsAsync.when(
      data: (rows) {
        final rowTotal = rows.fold<double>(
          0,
          (sum, r) => sum + ((r['quantity'] as num?)?.toDouble() ?? 0) * ((r['unit_price'] as num?)?.toDouble() ?? 0),
        );
        return Text(
          '${rows.length} part(s) • N\$${rowTotal.toStringAsFixed(2)}',
          style: GoogleFonts.manrope(fontSize: 13, color: palette.secondary),
        );
      },
      loading: () => Text('Loading parts...', style: TextStyle(color: palette.muted, fontSize: 12)),
      error: (e, _) => Text('$e', style: TextStyle(color: palette.error, fontSize: 12)),
    );

    return ShopCommerceUi.providerRecommendationCard(
      palette: palette,
      vehicleLabel: vehicle,
      notes: notes,
      summaryLine: summaryLine,
      isProcessing: isProcessing,
      onViewDetails: () => _viewPushDetails(pushId),
      onDismiss: () => _rejectPush(pushId),
      onAddToCart: () => _acceptPush(pushId),
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
    final palette = DashboardPalette.of(context);
    final svc = ref.read(jobCardServiceProvider);
    final items = await svc.listCartPushItems(pushId);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ShopCommerceUi.radiusCard)),
        title: Text(
          'Recommended Parts',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: palette.title),
        ),
        content: SizedBox(
          width: 360,
          child: items.isEmpty
              ? Text('No parts found for this recommendation.', style: TextStyle(color: palette.muted))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: palette.outlineVariant.withValues(alpha: 0.15),
                  ),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final qty = (it['quantity'] as num?)?.toInt() ?? 1;
                    final unit = (it['unit_price'] as num?)?.toDouble() ?? 0;
                    final lineTotal = qty * unit;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(it['part_name']?.toString() ?? '', style: TextStyle(color: palette.title)),
                      subtitle: Text(
                        'Qty $qty × N\$${unit.toStringAsFixed(2)}',
                        style: TextStyle(color: palette.muted, fontSize: 12),
                      ),
                      trailing: Text(
                        'N\$${lineTotal.toStringAsFixed(2)}',
                        style: TextStyle(color: palette.title, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CLOSE', style: TextStyle(color: palette.primaryContainer)),
          ),
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
