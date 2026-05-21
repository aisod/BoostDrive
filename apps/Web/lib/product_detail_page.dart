import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boost_drive_web/public_page_frame.dart';
import 'package:boost_drive_web/public_page_widgets.dart';
import 'package:boost_drive_web/listing_detail_widgets.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:boost_drive_web/messages_page.dart';

import 'edit_listing_page.dart';
import 'listing_owner_inquiries_panel.dart';

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
    final palette = ListingDetailPalette.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Listing', style: TextStyle(color: palette.titleColor, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete this listing?',
          style: TextStyle(color: palette.bodyColor),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: palette.mutedColor))),
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
          Navigator.pop(context, true);
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
      _hasChanges = true;
    } else if (result == true && mounted) {
      _hasChanges = true;
    }
  }

  String _guestActiveRoute() {
    switch (_currentProduct.category) {
      case 'part':
        return '/buy-parts';
      case 'rental':
        return '/rent-a-car';
      default:
        return '/marketplace';
    }
  }

  String _priceLabel() {
    final amount = 'N\$ ${_currentProduct.price.toStringAsFixed(2)}';
    if (_currentProduct.category == 'rental') return '$amount / day';
    return amount;
  }

  String _statusLabel() {
    return _currentProduct.status.toUpperCase();
  }

  Widget _buildBackLink(ListingDetailPalette palette) {
    return TextButton.icon(
      onPressed: () => Navigator.pop(context, _hasChanges),
      icon: Icon(Icons.arrow_back, color: palette.primaryText, size: 20),
      label: Text(
        listingBackLabel(_currentProduct.category),
        style: GoogleFonts.montserrat(
          color: palette.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildBuyerSidebar(ListingDetailPalette palette, bool isGuest) {
    final sellerId = _currentProduct.sellerId;
    final profileAsync = sellerId != null ? ref.watch(userProfileProvider(sellerId)) : null;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderColor.withValues(alpha: 0.2)),
        boxShadow: palette.ambientHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ListingDetailBadge(label: _currentProduct.condition.toUpperCase()),
              if (_currentProduct.isFeatured)
                ListingDetailBadge(
                  label: 'New Arrival',
                  backgroundColor: palette.primary.withValues(alpha: 0.12),
                  textColor: palette.primaryText,
                ),
              if (_currentProduct.fitment != null && _currentProduct.category != 'rental')
                ListingDetailBadge(
                  label: 'Verified Fitment',
                  backgroundColor: palette.secondaryFixed.withValues(alpha: 0.35),
                  textColor: palette.titleColor,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentProduct.title,
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: palette.titleColor,
              height: 1.15,
              letterSpacing: -0.02,
            ),
          ),
          if (_currentProduct.subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _currentProduct.subtitle,
              style: GoogleFonts.montserrat(fontSize: 15, color: palette.bodyColor, height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            _priceLabel(),
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: palette.primaryText,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: palette.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentProduct.location,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.bodyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_existingConversationId != null) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagesPage(initialConversationId: _existingConversationId),
                    ),
                  );
                },
                icon: const Icon(Icons.forum_outlined),
                label: const Text('View Conversation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.primaryText,
                  side: BorderSide(color: palette.primary, width: 2),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _handleAction(context, ref),
              icon: Icon(
                _currentProduct.category == 'rental' ? Icons.calendar_month_outlined : Icons.mail_outline,
              ),
              label: Text(
                _currentProduct.category == 'rental'
                    ? 'Rent Now'
                    : (_existingConversationId != null ? 'Message Seller Again' : 'Message Seller'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          if (isGuest) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Sign in required to contact seller',
                style: GoogleFonts.montserrat(fontSize: 12, color: palette.mutedColor),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Divider(color: palette.borderColor.withValues(alpha: 0.35)),
          const SizedBox(height: 20),
          Text(
            'SELLER INFORMATION',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.mutedColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          profileAsync == null
              ? _sellerPlaceholder(palette)
              : profileAsync.when(
                  data: (profile) => _sellerRow(palette, profile?.displayName ?? 'BoostDrive Seller'),
                  loading: () => _sellerPlaceholder(palette),
                  error: (_, __) => _sellerPlaceholder(palette),
                ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.sectionBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.borderColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user, color: palette.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buying Safety',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: palette.titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Always meet in a public place. Do not send money via wire transfer before seeing the vehicle or part.',
                        style: GoogleFonts.montserrat(fontSize: 13, height: 1.45, color: palette.bodyColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellerPlaceholder(ListingDetailPalette palette) {
    return _sellerRow(palette, 'BoostDrive Seller');
  }

  Widget _sellerRow(ListingDetailPalette palette, String name) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: palette.navBarTint.withValues(alpha: 0.35),
          child: Icon(Icons.storefront_outlined, color: palette.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15, color: palette.titleColor),
              ),
              Text(
                'Verified on BoostDrive',
                style: GoogleFonts.montserrat(fontSize: 12, color: palette.mutedColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerSidebar(ListingDetailPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOwnerPanel(palette),
        const SizedBox(height: 16),
        ListingOwnerInquiriesPanel(product: _currentProduct),
      ],
    );
  }

  Widget _buildOwnerPanel(ListingDetailPalette palette) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderColor.withValues(alpha: 0.35)),
        boxShadow: palette.ambientLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ListingDetailBadge(
                label: _statusLabel(),
                backgroundColor: palette.secondaryFixed.withValues(alpha: 0.4),
                textColor: palette.titleColor,
              ),
              if (_currentProduct.createdAt != null)
                Text(
                  'Posted ${_formatPosted(_currentProduct.createdAt!)}',
                  style: GoogleFonts.montserrat(fontSize: 12, color: palette.mutedColor),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentProduct.title,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: palette.titleColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _priceLabel(),
            style: GoogleFonts.montserrat(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: palette.primaryText,
            ),
          ),
          const SizedBox(height: 24),
          _ownerSpecGrid(palette),
          if (_currentProduct.description.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              "Owner's Description",
              style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w600, color: palette.titleColor),
            ),
            const SizedBox(height: 12),
            Text(
              _currentProduct.description,
              style: GoogleFonts.montserrat(fontSize: 15, height: 1.6, color: palette.bodyColor),
            ),
          ],
          const SizedBox(height: 28),
          Divider(color: palette.borderColor.withValues(alpha: 0.35)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Listing'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.primaryText,
                    side: BorderSide(color: palette.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _handleDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.errorContainer,
                    foregroundColor: palette.onErrorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ownerSpecGrid(ListingDetailPalette palette) {
    final specs = <(String, String)>[
      ('Condition', _currentProduct.condition.toUpperCase()),
      ('Location', _currentProduct.location),
      ('Category', _currentProduct.category.toUpperCase()),
      ('Views', '${_currentProduct.clickCount ?? 0}'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: specs
          .map(
            (s) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.sectionBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.$1, style: GoogleFonts.montserrat(fontSize: 12, color: palette.mutedColor)),
                  Text(
                    s.$2,
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: palette.titleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatPosted(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return 'recently';
  }

  Widget _buildMainColumn(ListingDetailPalette palette, {required bool isOwner}) {
    final specCards = listingSpecCardsForProduct(_currentProduct);
    final descriptionTitle = switch (_currentProduct.category) {
      'rental' => 'Description',
      'part' => 'Product Description',
      _ => 'Vehicle Description',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListingImageGallery(
          imageUrls: _currentProduct.imageUrls,
          height: isOwner ? 380 : 400,
          showThumbnails: true,
        ),
        if (isOwner) ...[
          const SizedBox(height: 20),
          ListingOwnerAnalyticsBar(product: _currentProduct),
        ],
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 700 ? 3 : 1;
            if (cols == 1) {
              return Column(
                children: [
                  for (final card in specCards) ...[card, const SizedBox(height: 12)],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < specCards.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < specCards.length - 1 ? 16 : 0),
                      child: specCards[i],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        ListingDescriptionPanel(
          title: descriptionTitle,
          body: _currentProduct.description.isNotEmpty
              ? _currentProduct.description
              : _currentProduct.subtitle,
        ),
        if (_currentProduct.fitment != null) ...[
          const SizedBox(height: 32),
          ListingFitmentGrid(fitment: _currentProduct.fitment!, product: _currentProduct),
        ],
        if (_currentProduct.category == 'rental') ...[
          const SizedBox(height: 32),
          ListingSectionTitle(title: 'Premium Features'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _RentalFeatureChip(icon: Icons.ac_unit, title: 'Climate Control', body: 'Dual-zone comfort for every passenger.'),
              _RentalFeatureChip(icon: Icons.gps_fixed, title: 'GPS Navigation', body: 'Built-in guidance for Namibian roads.'),
              _RentalFeatureChip(icon: Icons.security, title: 'Safety Pack', body: 'Advanced driver assistance and airbags.'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPageContent({
    required bool isGuest,
    required bool isOwner,
  }) {
    final palette = ListingDetailPalette.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 1000;

    return ColoredBox(
      color: palette.pageBackground,
      child: PublicPageContainer(
        maxWidth: 1440,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackLink(palette),
              const SizedBox(height: 20),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isOwner ? 7 : 8,
                      child: _buildMainColumn(palette, isOwner: isOwner),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: isOwner ? 5 : 4,
                      child: isOwner
                          ? _buildOwnerSidebar(palette)
                          : _buildBuyerSidebar(palette, isGuest),
                    ),
                  ],
                )
              else ...[
                _buildMainColumn(palette, isOwner: isOwner),
                const SizedBox(height: 24),
                isOwner ? _buildOwnerSidebar(palette) : _buildBuyerSidebar(palette, isGuest),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user;
    final isOwner = _currentProduct.sellerId == user?.id;
    final isGuest = user == null;

    return PublicPageFrame(
      activeRoute: _guestActiveRoute(),
      child: _buildPageContent(isGuest: isGuest, isOwner: isOwner),
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
    if (_currentProduct.category == 'rental') {
      _handleRental(context, ref, user);
    } else {
      _handleMessaging(context, ref, user);
    }
  }

  void _handleMessaging(BuildContext context, WidgetRef ref, User user) async {
    final messageService = ref.read(messageServiceProvider);
    final TextEditingController messageController = TextEditingController(
      text: 'Hi, I\'m interested in this ${_currentProduct.title}. Is it still available?',
    );
    final palette = ListingDetailPalette.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Message Seller', style: TextStyle(color: palette.titleColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start a conversation with the seller to discuss details and arrangement.',
              style: TextStyle(color: palette.bodyColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              style: TextStyle(color: palette.titleColor),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                filled: true,
                fillColor: palette.sectionBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: palette.mutedColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
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
        builder: (context) => Center(child: CircularProgressIndicator(color: palette.primary)),
      );

      try {
        if (_currentProduct.sellerId == null || _currentProduct.sellerId!.isEmpty) {
          throw Exception('This product has no seller ID assigned in the database. Please update the listing.');
        }

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
          Navigator.pop(context);
        }

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: palette.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.send_rounded, color: Colors.green, size: 80),
                  const SizedBox(height: 24),
                  Text(
                    'Message Sent!',
                    style: TextStyle(color: palette.titleColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your message has been delivered. You can continue the chat in your Messages hub.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.bodyColor),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessagesPage(initialConversationId: conversationId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
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
                        foregroundColor: palette.titleColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: palette.borderColor),
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
        if (context.mounted) Navigator.pop(context);
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
    final palette = ListingDetailPalette.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Confirm Rental', style: TextStyle(color: palette.titleColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve booked this vehicle for rent. Do you want to proceed with ${_currentProduct.title}?',
              style: TextStyle(color: palette.bodyColor),
            ),
            const SizedBox(height: 12),
            Text(
              'NOTE: This sends your rental request for manual confirmation.',
              style: TextStyle(color: palette.primaryText, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.sectionBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Price:', style: TextStyle(color: palette.bodyColor)),
                  Text(
                    _priceLabel(),
                    style: TextStyle(color: palette.primaryText, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: palette.mutedColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Rental Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator(color: palette.primary)),
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

        if (context.mounted) Navigator.pop(context);

        if (success != null && context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: palette.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                  const SizedBox(height: 24),
                  Text(
                    'Booking Pending!',
                    style: TextStyle(color: palette.titleColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your rental request was sent. The provider will contact you to finalize arrangements manually.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.bodyColor),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
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
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _RentalFeatureChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _RentalFeatureChip({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ListingDetailPalette.of(context);
    return SizedBox(
      width: 280,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.sectionBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.borderColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: palette.primary, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: palette.titleColor),
            ),
            const SizedBox(height: 8),
            Text(body, style: GoogleFonts.montserrat(fontSize: 14, height: 1.45, color: palette.bodyColor)),
          ],
        ),
      ),
    );
  }
}
