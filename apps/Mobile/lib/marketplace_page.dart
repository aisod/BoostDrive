import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'product_detail_page.dart';
import 'add_listing_page.dart';
import 'cart_page.dart';

class MarketplacePage extends ConsumerStatefulWidget {
  final String? initialCategory;
  const MarketplacePage({super.key, this.initialCategory});

  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
  }
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(featuredProductsProvider);
    final user = ref.watch(authStateProvider).value?.session?.user;

    // Redirect to Role Selection if logged in but no roles set
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('BoostDrive Shop'),
        leading: user != null ? ref.watch(userProfileProvider(user.id)).whenData((profile) => profile != null ? Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              profile.isSeller ? 'S' : 'B',
              style: TextStyle(
                color: profile.isSeller ? BoostDriveTheme.primaryColor : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ) : const SizedBox()).value : const SizedBox(),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
               Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const CartPage())
              );
            },
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
          // Refresh provider after adding listing
          final _ = ref.refresh(featuredProductsProvider);
        },
        backgroundColor: BoostDriveTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Sell Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == 'all',
                  onTap: () => setState(() => _selectedCategory = 'all'),
                ),
                _CategoryChip(
                  label: 'Cars',
                  isSelected: _selectedCategory == 'car',
                  onTap: () => setState(() => _selectedCategory = 'car'),
                ),
                _CategoryChip(
                  label: 'Parts',
                  isSelected: _selectedCategory == 'part',
                  onTap: () => setState(() => _selectedCategory = 'part'),
                ),
                _CategoryChip(
                  label: 'Rentals',
                  isSelected: _selectedCategory == 'rental',
                  onTap: () => setState(() => _selectedCategory = 'rental'),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Featured Items',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Product Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filteredProducts = _selectedCategory == 'all'
                    ? products
                    : products.where((p) => p.category == _selectedCategory).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('No items found in this category'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Bottom padding for FAB
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70, // Taller cards
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return BoostProductCard(
                      product: filteredProducts[index],
                      onTap: () async {
                        final result = await Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => ProductDetailPage(product: filteredProducts[index]))
                        );
                        if (result == true) {
                          final _ = ref.refresh(featuredProductsProvider);
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: BoostDriveTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? BoostDriveTheme.primaryColor : BoostDriveTheme.textDim,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: BoostDriveTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? BoostDriveTheme.primaryColor : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
