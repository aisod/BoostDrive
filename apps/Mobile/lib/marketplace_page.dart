import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'product_detail_page.dart';
import 'add_listing_page.dart';
import 'cart_page.dart';

/// Marketplace home for browsing listings and creating new sell listings.
class MarketplacePage extends ConsumerStatefulWidget {
  final String? initialCategory;
  const MarketplacePage({super.key, this.initialCategory});

  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

/// State for selected category, search query, and listing filters.
class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  late String _selectedCategory;
  String _searchQuery = '';

  bool _matchesSearch(Product p) {
    if (_searchQuery.trim().isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return p.title.toLowerCase().contains(q) ||
        p.subtitle.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q) ||
        p.location.toLowerCase().contains(q);
  }

  void _openSearch() {
    MarketplaceUi.showSearchListingsSheet(
      context: context,
      initialQuery: _searchQuery,
      onApply: (query) => setState(() => _searchQuery = query),
      onClear: () => setState(() => _searchQuery = ''),
    );
  }

  bool _matchesSelectedCategory(String category) {
    if (_selectedCategory == 'all') return true;
    final c = category.trim().toLowerCase();
    if (_selectedCategory == 'car') return c == 'car' || c == 'cars' || c == 'vehicle' || c == 'vehicles';
    if (_selectedCategory == 'part') return c == 'part' || c == 'parts';
    if (_selectedCategory == 'rental') return c == 'rental' || c == 'rentals';
    return c == _selectedCategory;
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(marketplaceProductsProvider);
    final user = ref.watch(authStateProvider).value?.session?.user;
    final cartCount = ref.watch(cartProvider).length;

    if (user != null) {
      final profileAsync = ref.watch(userProfileProvider(user.id));
      profileAsync.whenData((profile) {
        if (profile != null && !profile.isBuyer && !profile.isSeller) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
            );
          });
        }
      });
    }

    final palette = DashboardPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: MarketplaceUi.shopAppBar(
        context: context,
        palette: palette,
        onSearch: _openSearch,
        cartItemCount: cartCount,
        onCart: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CartPage()),
          );
        },
      ),
      floatingActionButton: MarketplaceUi.sellFab(
        palette: palette,
        onPressed: () async {
          final user = ref.read(currentUserProvider);
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please log in to sell items.')),
            );
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddListingPage()),
          );
          final _ = ref.refresh(marketplaceProductsProvider);
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: MarketplaceUi.marginMobile,
              vertical: 12,
            ),
            child: Row(
              children: [
                MarketplaceUi.categoryPill(
                  palette: palette,
                  label: 'All',
                  selected: _selectedCategory == 'all',
                  onTap: () => setState(() => _selectedCategory = 'all'),
                ),
                MarketplaceUi.categoryPill(
                  palette: palette,
                  label: 'Cars',
                  selected: _selectedCategory == 'car',
                  onTap: () => setState(() => _selectedCategory = 'car'),
                ),
                MarketplaceUi.categoryPill(
                  palette: palette,
                  label: 'Parts',
                  selected: _selectedCategory == 'part',
                  onTap: () => setState(() => _selectedCategory = 'part'),
                ),
                MarketplaceUi.categoryPill(
                  palette: palette,
                  label: 'Rentals',
                  selected: _selectedCategory == 'rental',
                  onTap: () => setState(() => _selectedCategory = 'rental'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MarketplaceUi.marginMobile,
              8,
              MarketplaceUi.marginMobile,
              16,
            ),
            child: MarketplaceUi.sectionHeader(palette, onFiltersTap: _openSearch),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filteredProducts = products
                    .where((p) => _matchesSelectedCategory(p.category) && _matchesSearch(p))
                    .toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Text(
                      'No items found in this category',
                      style: TextStyle(color: palette.muted),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.52,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return BoostProductCard(
                      compact: true,
                      product: filteredProducts[index],
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(product: filteredProducts[index]),
                          ),
                        );
                        if (result == true) {
                          final _ = ref.refresh(marketplaceProductsProvider);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
