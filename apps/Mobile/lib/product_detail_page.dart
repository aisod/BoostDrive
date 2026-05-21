// ignore_for_file: use_build_context_synchronously
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
import 'listing_owner_inquiries_panel.dart';

/// Product details page for buyers and sellers.
class ProductDetailPage extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

/// State for current listing data, edit/delete actions, and cart flow.
class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  late Product _currentProduct;
  bool _hasChanges = false;
  bool _hasTrackedClick = false;
  late final PageController _imagePageController;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _imagePageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackListingClick());
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  List<String> get _imageUrls => _currentProduct.imageUrls.where((u) => u.trim().isNotEmpty).toList();

  Color _pageBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF09151B) : const Color(0xFFF9F9F9);

  Color _cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF162128) : Colors.white;

  Color _titleColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFD8E4EE) : const Color(0xFF1A1C1C);

  Color _bodyColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE3BFB2) : const Color(0xFF5A4138);

  Color _primaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFFB59A) : const Color(0xFFA43700);

  Future<void> _trackListingClick() async {
    // Only track one click per page open.
    if (_hasTrackedClick) return;
    _hasTrackedClick = true;

    // Do not count seller viewing their own listing.
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

  void _handleDelete() async {
    // Confirm destructive action before deleting listing.
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
    // Open edit page and update local product if changed.
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

  String _priceLabel() {
    final amount = 'N\$ ${_currentProduct.price.toStringAsFixed(2)}';
    if (_currentProduct.category == 'rental') return '$amount / day';
    return amount;
  }

  Widget _mobileSpecCard(BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bodyColor(context).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: BoostDriveTheme.primaryColor),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: _bodyColor(context))),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _titleColor(context)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user;
    final isOwner = _currentProduct.sellerId == user?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _pageBg(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
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
              height: 380,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_imageUrls.isEmpty)
                    ColoredBox(
                      color: isDark ? const Color(0xFF202B33) : const Color(0xFFE8E8E8),
                      child: Icon(Icons.image_not_supported_outlined, size: 64, color: _bodyColor(context)),
                    )
                  else
                    PageView.builder(
                      controller: _imagePageController,
                      onPageChanged: (i) => setState(() => _imageIndex = i),
                      itemCount: _imageUrls.length,
                      itemBuilder: (_, i) => Image.network(
                        _imageUrls[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: isDark ? const Color(0xFF202B33) : const Color(0xFFE8E8E8),
                          child: Icon(Icons.broken_image_outlined, size: 64, color: _bodyColor(context)),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _pageBg(context),
                            _pageBg(context).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_imageUrls.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _imageUrls.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _imageIndex ? 10 : 8,
                            height: i == _imageIndex ? 10 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: i == _imageIndex ? 1 : 0.45),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardBg(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentProduct.category == 'rental' ? 'RENTAL' : _currentProduct.category.toUpperCase(),
                        style: TextStyle(
                          color: _primaryText(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentProduct.title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: _titleColor(context),
                        ),
                      ),
                      if (_currentProduct.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_currentProduct.subtitle, style: TextStyle(color: _bodyColor(context), fontSize: 14)),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        _priceLabel(),
                        style: TextStyle(
                          color: _primaryText(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_imageUrls.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageUrls.length > 4 ? 4 : _imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final isLastOverlay = i == 3 && _imageUrls.length > 4;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _imageIndex = i);
                          _imagePageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        },
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _imageIndex == i ? BoostDriveTheme.primaryColor : _bodyColor(context).withValues(alpha: 0.25),
                                width: _imageIndex == i ? 2 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(_imageUrls[i], fit: BoxFit.cover),
                                if (isLastOverlay)
                                  Container(
                                    color: Colors.black54,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '+${_imageUrls.length - 3}',
                                      style: TextStyle(color: _primaryText(context), fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOwner) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF121D24) : const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, color: _primaryText(context)),
                          const SizedBox(width: 12),
                          Text(
                            'Clicks: ${_currentProduct.clickCount ?? 0} • Saved: ${_currentProduct.saveCount ?? 0}',
                            style: TextStyle(color: _titleColor(context), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    ListingOwnerInquiriesPanel(product: _currentProduct),
                  ],
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _mobileSpecCard(context, Icons.fact_check_outlined, 'Condition', _currentProduct.condition.toUpperCase()),
                      _mobileSpecCard(context, Icons.location_on_outlined, 'Location', _currentProduct.location),
                      if (_currentProduct.fitment != null)
                        _mobileSpecCard(
                          context,
                          Icons.directions_car_outlined,
                          'Fitment',
                          '${_currentProduct.fitment!['make']} ${_currentProduct.fitment!['model']}',
                        ),
                    ],
                  ),
                  if (_currentProduct.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Description',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _primaryText(context)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _cardBg(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _bodyColor(context).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _currentProduct.description,
                        style: TextStyle(fontSize: 15, height: 1.55, color: _bodyColor(context)),
                      ),
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
          color: _cardBg(context),
          border: Border(top: BorderSide(color: _bodyColor(context).withValues(alpha: 0.15))),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
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
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
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
                      color: Colors.white.withValues(alpha: 0.05),
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
    // Opens buyer-seller chat for this listing.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Please log in to message the seller')));
      return;
    }

    if (_currentProduct.sellerId == user.id) {
      messenger.showSnackBar(const SnackBar(content: Text('You cannot message yourself')));
      return;
    }

    try {
      final messageService = ref.read(messageServiceProvider);
      final conversationId = await messageService.getOrCreateConversation(
        productId: _currentProduct.id,
        buyerId: user.id,
        seller_id: _currentProduct.sellerId!,
      );

      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ChatPage(
            conversationId: conversationId,
            productTitle: _currentProduct.title,
            buyerId: user.id,
            sellerId: _currentProduct.sellerId!,
          ),
        ),
      );
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref) async {
    // Entry point for buyer action button (book/add-to-cart).
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to continue.')),
      );
      return;
    }
    _handleManualAction(context, ref, user);
  }

  void _handleManualAction(BuildContext context, WidgetRef ref, User user) async {
    // Rental items ask for booking date range before adding to cart.
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
      // Standard product asks for quantity before adding to cart.
      final qty = await _promptQuantity(context);
      if (qty == null) return;
      ref.read(cartProvider.notifier).addItem(_currentProduct, quantity: qty);
      _showAddedSnackBar(context, quantity: qty);
    }
  }

  Future<int?> _promptQuantity(BuildContext context) async {
    // Dialog to validate and return quantity for cart add.
    final controller = TextEditingController(text: '1');
    String? errorText;
    final value = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: BoostDriveTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Select Quantity',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter quantity',
              hintStyle: const TextStyle(color: Colors.white54),
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed < 1) {
                  setStateDialog(() => errorText = 'Enter a valid quantity (1+)');
                  return;
                }
                if (parsed > 999) {
                  setStateDialog(() => errorText = 'Quantity is too high');
                  return;
                }
                Navigator.pop(context, parsed);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BoostDriveTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
    return value;
  }

  void _showAddedSnackBar(BuildContext context, {int quantity = 1}) {
    // Shows success snackbar and quick link to cart page.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(quantity > 1 ? '$quantity items added to cart' : 'Added to Cart'),
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
