import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boost_drive_web/public_page_widgets.dart';
import 'package:boost_drive_web/public_top_nav_bar.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boost_drive_web/product_detail_page.dart';

class AllListingsPage extends ConsumerStatefulWidget {
  const AllListingsPage({super.key});

  @override
  ConsumerState<AllListingsPage> createState() => _AllListingsPageState();
}

class _AllListingsPageState extends ConsumerState<AllListingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

  void _showLoginDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PremiumPageLayout(
      scaffoldKey: _scaffoldKey,
      appBar: BoostDrivePublicTopNavBar(
        activeRoute: '/marketplace',
        onAuthTap: _showLoginDrawer,
      ),
      endDrawer: Drawer(
        width: isMobile ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.width * 0.46,
        backgroundColor: Colors.white,
        child: BoostLoginPage(
          onLoginSuccess: () => _scaffoldKey.currentState?.closeEndDrawer(),
          onClose: () => _scaffoldKey.currentState?.closeEndDrawer(),
        ),
      ),
      footer: const AppFooter(),
      child: ColoredBox(
        color: palette.pageBackground,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, isMobile ? 20 : 28, 20, 72),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final statWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 3;
                      return Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          SizedBox(
                            width: statWidth,
                            child: const PublicStatCard(
                              label: 'Browse all vehicle, parts, and rental inventory in one place.',
                              value: 'All-in-One',
                            ),
                          ),
                          SizedBox(
                            width: statWidth,
                            child: const PublicStatCard(
                              label: 'Search by make, model, year, category, and condition.',
                              value: 'Smart Filters',
                            ),
                          ),
                          SizedBox(
                            width: statWidth,
                            child: const PublicStatCard(
                              label: 'Use one shared marketplace layout across light and dark mode.',
                              value: 'Unified UI',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildFilterBar(),
                  const SizedBox(height: 28),
                  const PublicSectionHeading(
                    title: 'Fresh listings across BoostDrive',
                    subtitle: 'Everything below still uses the existing marketplace data and detail pages. This redesign only changes presentation.',
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<List<Product>>(
                    future: _listingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const PublicFeedbackState(
                          icon: Icons.autorenew,
                          title: 'Loading marketplace',
                          message: 'Fetching the latest listings from BoostDrive.',
                        );
                      }

                      if (snapshot.hasError) {
                        return PublicFeedbackState(
                          icon: Icons.error_outline,
                          title: 'Could not load listings',
                          message: 'The marketplace request failed: ${snapshot.error}',
                          action: TextButton(
                            onPressed: _loadListings,
                            child: const Text('Try again'),
                          ),
                        );
                      }

                      final listings = snapshot.data ?? [];
                      if (listings.isEmpty) {
                        return const PublicFeedbackState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No listings found',
                          message: 'Try widening your search or clearing a few filters to see more results.',
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          int crossAxisCount = 1;
                          if (width > 1180) {
                            crossAxisCount = 3;
                          } else if (width > 760) {
                            crossAxisCount = 2;
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: listings.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              childAspectRatio: width > 1180 ? 0.82 : 0.84,
                            ),
                            itemBuilder: (context, index) {
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
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return PublicHeroBanner(
      eyebrow: 'OUR COMPLETE MARKETPLACE',
      title: 'Everything automotive in one beautifully redesigned marketplace.',
      subtitle: 'Search cars, spare parts, and rental offers from one polished storefront while keeping the existing BoostDrive search and product detail flow intact.',
      imageUrl: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=1600&q=80',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: PublicSearchField(
          controller: _searchController,
          hintText: 'Search the entire marketplace...',
          filledLight: true,
          onChanged: (_) => _onSearchChanged(),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final palette = PublicPagePalette.of(context);

    return PublicPageSection(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: PublicSectionHeading(
                  title: 'Refine your search',
                  subtitle: 'Use category and fitment filters to narrow results without changing the underlying marketplace logic.',
                ),
              ),
              if (!isMobile)
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
                  icon: const Icon(Icons.filter_alt_off, color: BoostDriveTheme.primaryColor),
                  label: const Text('Clear filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: BoostDriveTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCategoryChip('All', null),
              _buildCategoryChip('Vehicles', 'car'),
              _buildCategoryChip('Parts', 'part'),
              _buildCategoryChip('Rentals', 'rental'),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
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
                icon: const Icon(Icons.filter_alt_off, color: BoostDriveTheme.primaryColor),
                label: const Text('Clear filters'),
                style: TextButton.styleFrom(foregroundColor: BoostDriveTheme.primaryColor),
              ),
            ),
          ],
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width > 1180 ? 5 : (width > 720 ? 2 : 1);
              final itemWidth = columns == 1 ? width : (width - (24 * (columns - 1))) / columns;

              return Wrap(
                spacing: 24,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: PublicDropdownField(
                      label: 'Category',
                      value: _selectedCategory,
                      hintText: 'All categories',
                      options: const ['car', 'part', 'rental'],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                        _loadListings();
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: PublicDropdownField(
                      label: 'Make',
                      value: _selectedMake,
                      hintText: 'All makes',
                      options: const ['Toyota', 'Volkswagen', 'Ford', 'Nissan'],
                      onChanged: (value) {
                        setState(() => _selectedMake = value);
                        _loadListings();
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: PublicDropdownField(
                      label: 'Model',
                      value: _selectedModel,
                      hintText: 'All models',
                      options: const ['Hilux', 'Golf', 'Ranger', 'Navara'],
                      onChanged: (value) {
                        setState(() => _selectedModel = value);
                        _loadListings();
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: PublicDropdownField(
                      label: 'Year',
                      value: _selectedYear?.toString(),
                      hintText: 'All years',
                      options: const ['2024', '2023', '2022', '2021', '2020'],
                      onChanged: (value) {
                        setState(() => _selectedYear = value != null ? int.parse(value) : null);
                        _loadListings();
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: PublicDropdownField(
                      label: 'Condition',
                      value: _selectedCondition,
                      hintText: 'All conditions',
                      options: const ['all', 'new', 'used', 'salvage'],
                      onChanged: (value) {
                        setState(() => _selectedCondition = value ?? 'all');
                        _loadListings();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.fieldBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: BoostDriveTheme.primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The new layout mirrors the supplied design while still driving the existing backend search and filters.',
                    style: TextStyle(
                      color: palette.bodyColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final palette = PublicPagePalette.of(context);
    final isSelected = _selectedCategory == value || (_selectedCategory == null && value == null);
    return InkWell(
      onTap: () {
        setState(() => _selectedCategory = value);
        _loadListings();
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? BoostDriveTheme.primaryColor
              : palette.fieldBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? BoostDriveTheme.primaryColor : palette.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : palette.titleColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
