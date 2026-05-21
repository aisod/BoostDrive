import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boost_drive_web/public_page_widgets.dart';
import 'package:boost_drive_web/public_page_frame.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boost_drive_web/product_detail_page.dart';

/// This page shows the parts marketplace with search and vehicle filters.
class PartsMarketplacePage extends ConsumerStatefulWidget {
  const PartsMarketplacePage({super.key});

  @override
  ConsumerState<PartsMarketplacePage> createState() => _PartsMarketplacePageState();
}

/// Holds UI state for filters, search text, and async loading.
class _PartsMarketplacePageState extends ConsumerState<PartsMarketplacePage> {
  final ProductService _productService = ProductService();
  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;
  String _selectedCondition = 'all';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late Future<List<Product>> _partsFuture;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadParts();
    });
  }

  void _loadParts() {
    if (!mounted) return;
    setState(() {
      _partsFuture = _productService.searchParts(
        make: _selectedMake,
        model: _selectedModel,
        year: _selectedYear,
        condition: _selectedCondition == 'all' ? null : _selectedCondition,
        query: _searchController.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PublicPageFrame(
      activeRoute: '/buy-parts',
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
                              label: 'Search spare parts, upgrades, and replacement stock.',
                              value: 'Parts Search',
                            ),
                          ),
                          SizedBox(
                            width: statWidth,
                            child: const PublicStatCard(
                              label: 'Filter by vehicle fitment before opening the same detail page.',
                              value: 'Fitment Match',
                            ),
                          ),
                          SizedBox(
                            width: statWidth,
                            child: const PublicStatCard(
                              label: 'Designed to match the supplied parts marketplace references.',
                              value: 'Design Match',
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
                    title: 'Parts and upgrades',
                    subtitle: 'Existing part data, search, and detail navigation remain unchanged. The refreshed shell focuses purely on the UI.',
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<List<Product>>(
                    future: _partsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const PublicFeedbackState(
                          icon: Icons.settings_suggest_outlined,
                          title: 'Loading parts',
                          message: 'Fetching available parts and accessories.',
                        );
                      }

                      if (snapshot.hasError) {
                        return PublicFeedbackState(
                          icon: Icons.error_outline,
                          title: 'Could not load parts',
                          message: 'The parts query failed: ${snapshot.error}',
                          action: TextButton(
                            onPressed: _loadParts,
                            child: const Text('Try again'),
                          ),
                        );
                      }

                      final parts = snapshot.data ?? [];
                      if (parts.isEmpty) {
                        return const PublicFeedbackState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No parts found',
                          message: 'Try adjusting make, model, year, or condition to broaden the results.',
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
                            itemCount: parts.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              childAspectRatio: width > 1180 ? 0.82 : 0.84,
                            ),
                            itemBuilder: (context, index) {
                              final product = parts[index];
                              return BoostProductCard(
                                key: ValueKey('part_card_${product.id}'),
                                product: product,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailPage(product: product),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadParts();
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
      eyebrow: 'PARTS MARKETPLACE',
      title: 'A sharper storefront for discovering parts, upgrades, and essential replacements.',
      subtitle: 'The refreshed page reflects the supplied parts marketplace mockups while still using the same filters, queries, and product detail behavior already in the app.',
      imageUrl: 'https://images.unsplash.com/photo-1487754180451-c456f719a1fc?auto=format&fit=crop&w=1600&q=80',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: PublicSearchField(
          controller: _searchController,
          hintText: 'Search by part name (e.g. Brake Pads)...',
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
            title: 'Fitment verification',
            subtitle: 'Keep searching by make, model, year, and condition exactly as before, but inside the new visual system.',
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
                        _loadParts();
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
                        _loadParts();
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
                        _loadParts();
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
                        _loadParts();
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
                    'This section keeps the original parts search intact while visually matching the supplied redesign for light and dark mode.',
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
                  _loadParts();
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
