import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boost_drive_web/public_page_widgets.dart';
import 'package:boost_drive_web/public_page_frame.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boost_drive_web/product_detail_page.dart';

class RentalMarketplacePage extends ConsumerStatefulWidget {
  const RentalMarketplacePage({super.key});

  @override
  ConsumerState<RentalMarketplacePage> createState() => _RentalMarketplacePageState();
}

class _RentalMarketplacePageState extends ConsumerState<RentalMarketplacePage> {
  final TextEditingController _searchController = TextEditingController();

  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;
  String _selectedCondition = 'all';
  Timer? _searchDebounce;
  
  late Future<List<Product>> _rentalsFuture;

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<List<Product>> _getRentalData([String? query]) {
    return ref.read(productServiceProvider).searchProducts(
      category: 'rental',
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
      _loadRentals();
    });
  }

  void _loadRentals() {
    if (!mounted) return;
    setState(() {
      _rentalsFuture = _getRentalData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PublicPageFrame(
      activeRoute: '/rent-a-car',
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
                              label: 'Explore self-drive and daily-use rental inventory.',
                              value: 'Daily Rentals',
                            ),
                          ),
                          SizedBox(
                            width: statWidth,
                            child: const PublicStatCard(
                              label: 'Search by make, model, year, and condition.',
                              value: 'Quick Booking View',
                            ),
                          ),
                          SizedBox(
                            width: statWidth,
                            child: const PublicStatCard(
                              label: 'Matches the provided premium rental mockups in both themes.',
                              value: 'Premium Look',
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
                    title: 'Rental inventory',
                    subtitle: 'The cards below still open the same rental detail pages and backend data. Only the presentation has been redesigned.',
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<List<Product>>(
                    future: _rentalsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const PublicFeedbackState(
                          icon: Icons.directions_car_filled_outlined,
                          title: 'Loading rentals',
                          message: 'Pulling the latest rental vehicles from BoostDrive.',
                        );
                      }

                      if (snapshot.hasError) {
                        return PublicFeedbackState(
                          icon: Icons.error_outline,
                          title: 'Could not load rentals',
                          message: 'The rental query failed: ${snapshot.error}',
                          action: TextButton(
                            onPressed: _loadRentals,
                            child: const Text('Try again'),
                          ),
                        );
                      }

                      final rentals = snapshot.data ?? [];
                      if (rentals.isEmpty) {
                        return const PublicFeedbackState(
                          icon: Icons.no_transfer,
                          title: 'No rental vehicles available',
                          message: 'Try broadening your filters to see more rental options.',
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
                            itemCount: rentals.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              childAspectRatio: width > 1180 ? 0.82 : 0.84,
                            ),
                            itemBuilder: (context, index) {
                              final product = rentals[index];
                              return BoostProductCard(
                                key: ValueKey('rental_card_${product.id}'),
                                product: product,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailPage(product: product),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadRentals();
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
      eyebrow: 'RENTAL MARKETPLACE',
      title: 'Find polished rental offers with a cleaner booking-first storefront.',
      subtitle: 'The rental page now mirrors the supplied premium layouts while still querying the same rental listings and opening the same detail flow.',
      imageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1600&q=80',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: PublicSearchField(
          controller: _searchController,
          hintText: 'Search by vehicle name (e.g. Toyota Hilux)...',
          filledLight: true,
          onChanged: (_) => _onSearchChanged(),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final palette = PublicPagePalette.of(context);

    return PublicPageSection(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PublicSectionHeading(
            title: 'Vehicle selection and filters',
            subtitle: 'Filter rental inventory by vehicle fitment data while keeping the exact same backend rental search in place.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width > 1180 ? 4 : (width > 720 ? 2 : 1);
              final itemWidth = columns == 1 ? width : (width - (24 * (columns - 1))) / columns;

              return Wrap(
                spacing: 24,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: PublicDropdownField(
                      label: 'Make',
                      value: _selectedMake,
                      hintText: 'All makes',
                      options: const ['Toyota', 'Volkswagen', 'Ford', 'Nissan'],
                      onChanged: (value) {
                        setState(() => _selectedMake = value);
                        _loadRentals();
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
                        _loadRentals();
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
                        _loadRentals();
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
                        _loadRentals();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: palette.fieldBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Need a reset? Clear the fitment fields and search term to reveal the full rental inventory again.',
                    style: TextStyle(
                      color: palette.bodyColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedMake = null;
                    _selectedModel = null;
                    _selectedYear = null;
                    _selectedCondition = 'all';
                    _searchController.clear();
                  });
                  _loadRentals();
                },
                icon: const Icon(Icons.filter_alt_off, color: BoostDriveTheme.primaryColor),
                label: const Text('Clear filters'),
                style: TextButton.styleFrom(foregroundColor: BoostDriveTheme.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
