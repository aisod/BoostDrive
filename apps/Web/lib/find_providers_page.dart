import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boost_drive_web/public_page_frame.dart';
import 'package:boost_drive_web/public_page_widgets.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:boost_drive_web/messages_page.dart';
import 'package:boost_drive_web/provider_hub_page.dart';
import 'package:boost_drive_web/provider_detail_page_ui.dart';

/// Find a Provider — "Digital Yellow Pages" for booking service, comparing mechanics, or finding towing.
/// Header with search, category filters, provider list (verified badge, role, distance, rating, hours), list/map toggle.
class FindProvidersPage extends ConsumerStatefulWidget {
  const FindProvidersPage({super.key});

  @override
  ConsumerState<FindProvidersPage> createState() => _FindProvidersPageState();
}

class _FindProvidersPageState extends ConsumerState<FindProvidersPage> {
  /// 'all' | 'mechanic' | 'towing' | 'parts' | 'rental' | 'service_station'
  String _serviceFilter = 'all';
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'closest'; // 'closest' | 'rated' | 'experienced'
  bool _isMapView = false;
  bool _availableFilter = false;
  Timer? _debounceTimer;

  bool _isProviderRole(String role) {
    final cleaned = role.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');
    if (cleaned.isEmpty) return false;

    // Your DB sometimes stores provider accounts as plain "provider".
    if (cleaned == 'service_provider') return true;

    return cleaned.contains('service provider') ||
        cleaned.contains('service pro') ||
        cleaned.contains('mechanic') ||
        cleaned.contains('towing') ||
        cleaned.contains('logistics') ||
        cleaned.contains('rental');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _locationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _debounceUpdateSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String? _getServiceTypeForProvider() {
    switch (_serviceFilter) {
      case 'mechanic':
        return 'mechanic';
      case 'towing':
        return 'towing';
      case 'parts':
        return 'parts';
      case 'rental':
        return 'rental';
      case 'service_station':
        return 'mechanic'; // map to mechanic for now
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      final profileAsync = ref.watch(userProfileProvider(user.id));
      return profileAsync.when(
        data: (profile) {
          if (profile != null && _isProviderRole(profile.role)) {
            // Provider should not be on this page, redirect to provider hub.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProviderHubPage()),
              );
            });
            return const Scaffold(body: Center(child: Text('Redirecting to Provider Hub...')));
          }
          return _buildCustomerView();
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Error loading profile: $e'))),
      );
    }
    // Not logged in, show customer view
    return _buildCustomerView();
  }

  Widget _buildCustomerView() {
    final serviceType = _getServiceTypeForProvider();
    final providersAsync = ref.watch(verifiedProvidersProvider(serviceType));
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    // Client-side search and location filtering
    final filteredProvidersAsync = providersAsync.whenData((list) {
      if (list == null) return <UserProfile>[];
      if (kDebugMode) print('DEBUG: FindProvidersPage got ${list.length} providers from backend.');
      final query = _searchController.text.toLowerCase().trim();
      final locationQuery = _locationController.text.toLowerCase().trim();

      return list.where((p) {
        final name = (p.displayName ?? '').toLowerCase();
        final bio = (p.businessBio ?? '').toLowerCase();
        final brands = p.brandExpertise.map((k) => UserProfile.getSpecializationLabel(k ?? '').toLowerCase()).join(' ');
        final tags = p.serviceTags.map((k) => UserProfile.getSpecializationLabel(k ?? '').toLowerCase()).join(' ');
        final category = UserProfile.getSpecializationLabel(p.primaryServiceCategory ?? 'mechanic').toLowerCase();

        final matchesQuery = query.isEmpty ||
            name.contains(query) ||
            bio.contains(query) ||
            brands.contains(query) ||
            tags.contains(query) ||
            category.contains(query);

        final address = (p.workshopAddress ?? '').toLowerCase();
        final area = (p.serviceAreaDescription ?? '').toLowerCase();

        final matchesLocation = locationQuery.isEmpty ||
            address.contains(locationQuery) ||
            area.contains(locationQuery);

        final matchesAvailable = !(_availableFilter == true) || (p.isOnline == true);

        return (matchesQuery == true) && (matchesLocation == true) && (matchesAvailable == true);
      }).toList();
    });

    // Client-side sorting
    final sortedProvidersAsync = filteredProvidersAsync.whenData((list) {
      if (list == null) return <UserProfile>[];
      final sorted = List<UserProfile>.from(list);
      switch (_sortBy) {
        case 'rated':
          sorted.sort((a, b) {
            final aApproved = (a.verificationStatus ?? '').toLowerCase() == 'approved';
            final bApproved = (b.verificationStatus ?? '').toLowerCase() == 'approved';
            final aScore = (aApproved ? 2 : 0) + (a.isOnline == true ? 1 : 0);
            final bScore = (bApproved ? 2 : 0) + (b.isOnline == true ? 1 : 0);
            return bScore.compareTo(aScore);
          });
          break;
        case 'experienced':
          sorted.sort((a, b) => (b.yearsInOperation ?? 0).compareTo(a.yearsInOperation ?? 0));
          break;
        case 'closest':
          sorted.sort((a, b) => (b.isOnline == true ? 1 : 0).compareTo(a.isOnline == true ? 1 : 0));
          break;
      }
      return sorted;
    });

    return PublicPageFrame(
      activeRoute: '/find-provider',
      child: RepaintBoundary(
        child: ColoredBox(
          color: palette.pageBackground,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, isMobile ? 20 : 28, 20, 72),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
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
                                label: 'Search verified mechanics, towing, rental, and parts providers.',
                                value: 'Verified Network',
                              ),
                            ),
                            SizedBox(
                              width: statWidth,
                              child: const PublicStatCard(
                                label: 'Sort by availability, experience, and provider type.',
                                value: 'Smart Discovery',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    PublicPageSection(
                      elevated: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PublicSectionHeading(
                            title: 'Search and compare providers',
                            subtitle: 'Filter providers without touching the existing verification, sorting, or messaging behavior already built into BoostDrive.',
                          ),
                          const SizedBox(height: 18),
                          _buildSearchBar(),
                          const SizedBox(height: 18),
                          _buildQuickLinks(),
                          const SizedBox(height: 20),
                          _buildCategoryFilters(),
                          const SizedBox(height: 18),
                          _buildSortAndViewToggle(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const PublicSectionHeading(
                      title: 'Providers ready to help',
                      subtitle: 'Browse verified service businesses, compare specialties, and open the same provider detail flow as before.',
                    ),
                    const SizedBox(height: 18),
                    _buildProviderContent(sortedProvidersAsync, serviceType),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return PublicHeroBanner(
      eyebrow: 'FIND A PROVIDER',
      title: 'Discover trusted automotive services through a more polished provider hub.',
      subtitle: 'Search mechanics, towing, rentals, and parts businesses with the same live provider data and customer actions already connected in BoostDrive.',
      imageUrl: 'https://images.unsplash.com/photo-1486006920555-c77dcf18193c?auto=format&fit=crop&w=1600&q=80',
    );
  }

  Widget _buildSearchBar({bool heroMode = false}) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final fields = [
      Expanded(
        flex: 2,
        child: PublicSearchField(
          controller: _locationController,
          hintText: 'Location, town, or region',
          icon: Icons.location_on_outlined,
          filledLight: heroMode,
          onChanged: (_) => _debounceUpdateSearch(),
        ),
      ),
      SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 12 : 0),
      Expanded(
        flex: 3,
        child: PublicSearchField(
          controller: _searchController,
          hintText: 'Search mechanics, towing, parts, rentals...',
          filledLight: heroMode,
          onChanged: (_) => _debounceUpdateSearch(),
        ),
      ),
    ];

    return isMobile
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: fields)
        : Row(children: fields);
  }

  Widget _buildQuickLinks({bool heroMode = false}) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        _QuickLinkChip(
          icon: Icons.near_me,
          label: 'Nearby Me',
          heroMode: heroMode,
          isSelected: _sortBy == 'closest',
          onTap: () => setState(() => _sortBy = 'closest'),
        ),
        _QuickLinkChip(
          icon: Icons.star_outline,
          label: 'Highly Rated',
          heroMode: heroMode,
          isSelected: _sortBy == 'rated',
          onTap: () => setState(() => _sortBy = 'rated'),
        ),
        _QuickLinkChip(
          icon: Icons.schedule,
          label: 'Available Now',
          heroMode: heroMode,
          isSelected: _availableFilter,
          onTap: () => setState(() => _availableFilter = !_availableFilter),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    final palette = PublicPagePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider Category',
          style: TextStyle(fontSize: 12, color: palette.mutedColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _FilterChip(label: 'All', isSelected: _serviceFilter == 'all', onTap: () => setState(() => _serviceFilter = 'all')),
            _FilterChip(label: 'Mechanics', isSelected: _serviceFilter == 'mechanic', onTap: () => setState(() => _serviceFilter = 'mechanic')),
            _FilterChip(label: 'Towing', isSelected: _serviceFilter == 'towing', onTap: () => setState(() => _serviceFilter = 'towing')),
            _FilterChip(label: 'Service Stations', isSelected: _serviceFilter == 'service_station', onTap: () => setState(() => _serviceFilter = 'service_station')),
            _FilterChip(label: 'Parts', isSelected: _serviceFilter == 'parts', onTap: () => setState(() => _serviceFilter = 'parts')),
            _FilterChip(label: 'Rental', isSelected: _serviceFilter == 'rental', onTap: () => setState(() => _serviceFilter = 'rental')),
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Advanced filters'),
                    content: const Text('Distance, specialization, and rating filters coming soon.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Advanced filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: BoostDriveTheme.primaryColor,
                side: BorderSide(color: palette.borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortAndViewToggle() {
    final palette = PublicPagePalette.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Sort by', style: TextStyle(fontSize: 12, color: palette.mutedColor, fontWeight: FontWeight.w700)),
        _SortChip(label: 'Closest', value: 'closest', selected: _sortBy == 'closest', onTap: () => setState(() => _sortBy = 'closest')),
        _SortChip(label: 'Highest Rated', value: 'rated', selected: _sortBy == 'rated', onTap: () => setState(() => _sortBy = 'rated')),
        _SortChip(label: 'Most Experienced', value: 'experienced', selected: _sortBy == 'experienced', onTap: () => setState(() => _sortBy = 'experienced')),
        _ListMapToggle(
          isMapView: _isMapView,
          onChanged: (v) => setState(() => _isMapView = v),
        ),
      ],
    );
  }

  Widget _buildProviderContent(AsyncValue<List<UserProfile>> providersAsync, String? serviceType) {
    if (_isMapView) {
      return _buildMapPlaceholder();
    }
    return providersAsync.when(
      data: (list) {
        if (list == null || list.isEmpty) {
          return _buildEmptyState();
        }
        return _buildProviderList(list);
      },
      loading: () => Center(
        child: const PublicFeedbackState(
          icon: Icons.autorenew,
          title: 'Loading providers',
          message: 'Fetching verified providers from BoostDrive.',
        ),
      ),
      error: (err, _) => Center(
        child: PublicFeedbackState(
          icon: Icons.error_outline,
          title: 'Could not load providers',
          message: 'The provider query failed. Try refreshing this list.',
          action: TextButton(
            onPressed: () => ref.invalidate(verifiedProvidersProvider(serviceType)),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return const PublicFeedbackState(
      icon: Icons.map_outlined,
      title: 'Map view coming soon',
      message: 'The list and filters are live today. Map pins and navigation overlays can be layered into this redesigned shell next.',
    );
  }

  Widget _buildEmptyState() {
    final isTowing = _serviceFilter == 'towing';
    final message = isTowing
        ? 'No towing services found in this area yet. Try expanding your search radius or select "All" to see other providers.'
        : 'No providers match this filter yet. Try "All" or a different category, or check back as we onboard more providers.';
    return PublicFeedbackState(
      icon: Icons.person_search,
      title: isTowing ? 'No towing services here' : 'No providers found',
      message: message,
    );
  }

  Widget _buildProviderList(List<UserProfile> list) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1140 ? 3 : (width > 760 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: width > 1140 ? 0.98 : 1.02,
          ),
          itemBuilder: (context, index) {
            final p = list[index];
            return _ProviderCard(
              profile: p,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _ProviderDetailPage(profile: p),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickLinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final bool heroMode;

  const _QuickLinkChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.heroMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final backgroundColor = heroMode
        ? (isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.16))
        : (isSelected
            ? BoostDriveTheme.primaryColor
            : palette.fieldBackground);
    final foregroundColor = heroMode
        ? (isSelected ? const Color(0xFF221C20) : Colors.white)
        : (isSelected ? Colors.white : palette.titleColor);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: heroMode
                  ? Colors.white.withValues(alpha: isSelected ? 0 : 0.22)
                  : (isSelected ? BoostDriveTheme.primaryColor : palette.borderColor),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 18, 
                color: foregroundColor,
              ),
              const SizedBox(width: 6),
              Text(
                label, 
                style: TextStyle(
                  color: foregroundColor, 
                  fontSize: 13, 
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category filter as GestureDetector (avoids FilterChip/Material mouse_tracker issues on web).
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? BoostDriveTheme.primaryColor : palette.fieldBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? BoostDriveTheme.primaryColor : palette.borderColor,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : palette.titleColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sort option as a simple tap target (no dropdown overlay) to reduce web mouse_tracker issues.
class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? BoostDriveTheme.primaryColor : palette.fieldBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? BoostDriveTheme.primaryColor : palette.borderColor,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : palette.titleColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple list/map toggle to avoid SegmentedButton mouse_tracker issues on web.
class _ListMapToggle extends StatelessWidget {
  final bool isMapView;
  final ValueChanged<bool> onChanged;

  const _ListMapToggle({required this.isMapView, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.fieldBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSegment(
            label: 'List View',
            icon: Icons.list,
            selected: !isMapView,
            onTap: () => onChanged(false),
          ),
          _ToggleSegment(
            label: 'Map View',
            icon: Icons.map,
            selected: isMapView,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? BoostDriveTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : palette.bodyColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : palette.titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? foregroundColor;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final color = foregroundColor ?? palette.bodyColor;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: palette.fieldBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  final UserProfile profile;
  final VoidCallback? onTap;

  const _ProviderCard({required this.profile, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePromos = ref.watch(activePromotionsProvider(profile.primaryServiceCategory)).value ?? [];
    final hasPromo = activePromos.isNotEmpty;
    final roleLabel = _roleDisplayName(profile.role ?? 'mechanic');
    final isVerified = (profile.verificationStatus ?? '').toLowerCase() == 'approved';
    final businessContactString = (profile.businessContactNumber ?? '').trim();
    final List<String> businessNumbers = businessContactString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final personalContactNumber = (profile.phoneNumber ?? '').trim();
    final hasBusinessContact = businessNumbers.isNotEmpty;
    final hasPersonalContact = personalContactNumber.isNotEmpty;
    final palette = PublicPagePalette.of(context);
    final tags = [
      ...profile.brandExpertise.take(2).map((key) => UserProfile.getSpecializationLabel(key)),
      ...profile.serviceTags.take(2).map((key) => UserProfile.getSpecializationLabel(key)),
    ].toSet().toList();
    final locationText = (profile.serviceAreaDescription ?? '').isNotEmpty
        ? profile.serviceAreaDescription!
        : ((profile.workshopAddress ?? '').isNotEmpty ? profile.workshopAddress! : 'Service area on request');
    final hoursText = (profile.workingHours ?? '').isNotEmpty ? profile.workingHours! : 'Availability on request';
    final bio = (profile.businessBio ?? '').trim();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.borderColor),
            boxShadow: [
              BoxShadow(
                color: palette.isDark
                    ? Colors.black.withValues(alpha: 0.16)
                    : const Color(0xFFD7C8BF).withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.14),
                    child: Text(
                      getInitials(profile.displayName),
                      style: const TextStyle(
                        color: BoostDriveTheme.primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              profile.displayName,
                              style: TextStyle(
                                color: palette.titleColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: BoostDriveTheme.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, size: 14, color: BoostDriveTheme.primaryColor),
                                    SizedBox(width: 5),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: BoostDriveTheme.primaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (hasPromo)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Promo',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          roleLabel,
                          style: TextStyle(
                            color: palette.bodyColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                bio.isNotEmpty
                    ? bio
                    : 'Verified provider profile on BoostDrive. View this profile to see services, experience, and contact information.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.bodyColor,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(icon: Icons.near_me, label: locationText),
                  _InfoPill(
                    icon: Icons.schedule,
                    label: hoursText,
                    foregroundColor: Colors.green.shade700,
                  ),
                  if (profile.yearsInOperation != null)
                    _InfoPill(
                      icon: Icons.history,
                      label: '${profile.yearsInOperation} years experience',
                    ),
                  if (hasPersonalContact || hasBusinessContact)
                    _InfoPill(
                      icon: Icons.phone_outlined,
                      label: hasBusinessContact ? businessNumbers.first : personalContactNumber,
                    ),
                ],
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map((tag) => _SmallSpecializationChip(label: tag))
                      .toList(),
                ),
              ],
              const Spacer(),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasBusinessContact || hasPersonalContact)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (hasBusinessContact) {
                              _showContactNumbersDialog(context, businessNumbers: businessNumbers);
                            } else {
                              _launchTel(context, personalContactNumber);
                            }
                          },
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: const Text('Contact'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BoostDriveTheme.primaryColor,
                            side: BorderSide(color: palette.borderColor),
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.standard,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  if (hasBusinessContact || hasPersonalContact) const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: BoostDriveTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.standard,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('View Profile'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _roleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'mechanic':
        return 'Mechanic';
      case 'towing':
        return 'Towing';
      case 'service_provider':
        return 'Service Provider';
      case 'seller':
        return 'Parts Supplier';
      case 'rental':
        return 'Rental Agency';
      default:
        return role.isNotEmpty ? '${role[0].toUpperCase()}${role.substring(1)}' : role;
    }
  }

  /// On web, show both business and personal contact numbers in one dialog.
  static Future<void> _showContactNumbersDialog(
    BuildContext context, {
    List<String> businessNumbers = const [],
  }) async {
    if (!kIsWeb || !context.mounted) return;

    final hasBusiness = businessNumbers.isNotEmpty;
    if (!hasBusiness) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Provider contact numbers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasBusiness)
                ...businessNumbers.map((number) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _contactNumberRow(
                    context: ctx,
                    label: 'Business',
                    value: number,
                  ),
                )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Widget _contactNumberRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.phone_outlined, size: 18, color: BoostDriveTheme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.4),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy $label number',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label number copied to clipboard')),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
        ),
      ],
    );
  }

  static Future<void> _launchTel(BuildContext context, String phone) async {
    if (kIsWeb) {
      if (!context.mounted) return;
      final trimmed = phone.trim();
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Provider phone number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(
                trimmed,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              if (trimmed.length < 10) ...[
                const SizedBox(height: 12),
                Text(
                  'This number may be incomplete. The provider can update it in Profile Settings.',
                  style: TextStyle(fontSize: 12, color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1), fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: trimmed));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Phone number copied to clipboard')),
                  );
                  Navigator.pop(ctx);
                }
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
          ],
        ),
      );
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }
}

/// Detail page for a single provider: About, Gallery placeholder, Services & Pricing, Call / Message / Request Quote.
class _ProviderDetailPage extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _ProviderDetailPage({required this.profile});

  @override
  ConsumerState<_ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends ConsumerState<_ProviderDetailPage> {
  bool _isStartingConversation = false;

  void _openGalleryImage(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                width: double.infinity,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor)),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final profile = widget.profile;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to send a message.'),
            backgroundColor: BoostDriveTheme.primaryColor,
          ),
        );
      }
      return;
    }

    setState(() => _isStartingConversation = true);

    String? conversationId;
    try {
      conversationId = await ref.read(messageServiceProvider).getOrCreateDirectConversation(
            userId: user.id,
            providerId: profile.uid,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start conversation: $e')),
        );
        setState(() => _isStartingConversation = false);
      }
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesPage(initialConversationId: conversationId),
      ),
    );

    if (mounted) {
      setState(() => _isStartingConversation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final currentUser = ref.watch(currentUserProvider);
    final roleLabel = _ProviderCard._roleDisplayName(profile.role ?? 'mechanic');
    final isVerified = (profile.verificationStatus ?? '').toLowerCase() == 'approved';
    final businessContactString = (profile.businessContactNumber ?? '').trim();
    final businessNumbers = businessContactString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final hasBusinessContact = businessNumbers.isNotEmpty;

    final pageBody = ProviderDetailLightView(
      profile: profile,
      roleLabel: roleLabel,
      isVerified: isVerified,
      businessNumbers: businessNumbers,
      hasBusinessContact: hasBusinessContact,
      hasPersonalContact: (profile.phoneNumber ?? '').trim().isNotEmpty,
      isStartingConversation: _isStartingConversation,
      onCallNow: hasBusinessContact
          ? () => _ProviderCard._showContactNumbersDialog(
                context,
                businessNumbers: businessNumbers,
              )
          : null,
      onSendMessage: _handleSendMessage,
      onRequestQuote: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request quote — coming soon')),
        );
      },
      onGalleryImageTap: _openGalleryImage,
      onBusinessNumberTap: (number) => _ProviderCard._launchTel(context, number),
    );

    if (currentUser == null) {
      return PublicPageFrame(
        activeRoute: '/find-provider',
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: ProviderDetailLightUi.titleColor),
                  label: Text(
                    'Back',
                    style: TextStyle(
                      color: ProviderDetailLightUi.titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              pageBody,
            ],
          ),
        ),
      );
    }

    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: ProviderDetailLightUi.pageBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: ProviderDetailLightUi.titleColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: PremiumPageLayout(
        title: profile.displayName,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: ProviderDetailLightUi.titleColor),
        ),
        child: pageBody,
      ),
    );
  }
}

class _SmallSpecializationChip extends StatelessWidget {
  final String label;

  const _SmallSpecializationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.fieldBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.titleColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
