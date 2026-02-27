import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'product_detail_page.dart';

class AllListingsPage extends ConsumerStatefulWidget {
  const AllListingsPage({super.key});

  @override
  ConsumerState<AllListingsPage> createState() => _AllListingsPageState();
}

class _AllListingsPageState extends ConsumerState<AllListingsPage> {
  final TextEditingController _searchController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;
  String _selectedCondition = 'all';
  Timer? _searchDebounce;
  
  late Future<List<Product>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<List<Product>> _getListingsData([String? query]) {
    return ref.read(productServiceProvider).searchProducts(
      category: _selectedCategory,
      query: query ?? _searchController.text,
      make: _selectedMake,
      model: _selectedModel,
      year: _selectedYear,
      condition: _selectedCondition == 'all' ? null : _selectedCondition,
    );
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadListings();
    });
  }

  void _loadListings() {
    if (!mounted) return;
    setState(() {
      _listingsFuture = _getListingsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'Our Complete Marketplace',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacementNamed('/');
          }
        },
      ),
      footer: const AppFooter(),
      headerSlivers: [
        SliverToBoxAdapter(child: _buildHero()),
        SliverToBoxAdapter(child: _buildFilterBar()),
      ],
      slivers: [
        FutureBuilder<List<Product>>(
          future: _listingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SliverToBoxAdapter(
                child: Container(
                  height: 300,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: BoostDriveTheme.primaryColor),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Container(
                  height: 300,
                  alignment: Alignment.center,
                  child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                ),
              );
            }
            
            final listings = snapshot.data ?? [];
            
            if (listings.isEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  height: 300,
                  alignment: Alignment.center,
                  child: const Text('No listings found.', style: TextStyle(color: BoostDriveTheme.textDim)),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisExtent: 450,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = listings[index];
                    return BoostProductCard(
                      key: ValueKey('all_listing_card_${product.id}'),
                      product: product,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(product: product),
                          ),
                        );
                        if (result == true) {
                          _loadListings();
                        }
                      },
                    );
                  },
                  childCount: listings.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 60),
      decoration: const BoxDecoration(
        color: BoostDriveTheme.surfaceDark,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          const Text(
            'Explore Everything',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48, 
              fontWeight: FontWeight.w900, 
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cars, parts, and rentals—all in one place. Discover the best of BoostDrive.',
            textAlign: TextAlign.center,
            style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 18),
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _onSearchChanged(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search the entire marketplace...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: BoostDriveTheme.primaryColor),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: BoostDriveTheme.primaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: BoostDriveTheme.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Product Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedMake = null;
                    _selectedModel = null;
                    _selectedYear = null;
                    _selectedCondition = 'all';
                    _searchController.clear();
                  });
                  _loadListings();
                },
                icon: const Icon(Icons.filter_list_off, size: 20, color: BoostDriveTheme.primaryColor),
                label: const Text('Clear Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.white.withOpacity(0.05),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final double parentWidth = constraints.maxWidth;
              final double screenWidth = MediaQuery.of(context).size.width;
              final double maxWidth = (parentWidth.isFinite && parentWidth > 0) ? parentWidth : screenWidth - 48;
              
              return Wrap(
                spacing: 16,
                runSpacing: 24,
                children: [
                  _buildFilterItem('Category', ['car', 'part', 'rental'], _selectedCategory, (v) {
                    setState(() => _selectedCategory = v);
                    _loadListings();
                  }, maxWidth),
                  _buildFilterItem('Make', ['Toyota', 'Volkswagen', 'Ford', 'Nissan'], _selectedMake, (v) {
                    setState(() => _selectedMake = v);
                    _loadListings();
                  }, maxWidth),
                  _buildFilterItem('Model', ['Hilux', 'Golf', 'Ranger', 'Navara'], _selectedModel, (v) {
                    setState(() => _selectedModel = v);
                    _loadListings();
                  }, maxWidth),
                  _buildFilterItem('Year', ['2024', '2023', '2022', '2021', '2020'], _selectedYear?.toString(), (v) {
                    setState(() => _selectedYear = v != null ? int.parse(v) : null);
                    _loadListings();
                  }, maxWidth),
                  _buildFilterItem('Condition', ['all', 'new', 'used', 'salvage'], _selectedCondition, (v) {
                    setState(() => _selectedCondition = v ?? 'all');
                    _loadListings();
                  }, maxWidth),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(String label, List<String> items, String? value, ValueChanged<String?> onChanged, double maxWidth) {
    final double divisor = maxWidth > 1000 ? 5 : (maxWidth > 700 ? 3 : (maxWidth > 500 ? 2 : 1));
    final double itemWidth = (maxWidth - (16 * (divisor - 1))) / divisor;
    
    return SizedBox(
      width: itemWidth.clamp(140.0, 600.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: BoostDriveTheme.backgroundDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: BoostDriveTheme.surfaceDark,
                icon: const Icon(Icons.keyboard_arrow_down, color: BoostDriveTheme.textDim),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                hint: Text('All $label', style: const TextStyle(color: Colors.white24, fontSize: 13)),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
