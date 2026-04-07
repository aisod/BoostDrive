import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:boost_drive_web/messages_page.dart';
import 'package:boost_drive_web/provider_hub_page.dart';

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

    return PremiumPageLayout(
      title: 'Find a Provider',
      child: RepaintBoundary(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  _buildQuickLinks(),
                  const SizedBox(height: 24),
                  _buildCategoryFilters(),
                  const SizedBox(height: 16),
                  _buildSortAndViewToggle(),
                  const SizedBox(height: 24),
                  _buildProviderContent(sortedProvidersAsync, serviceType),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Back',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Find a Provider',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Book a service, compare mechanics, or find towing. Not in an emergency? Browse verified providers below.',
          style: TextStyle(fontSize: 14, color: BoostDriveTheme.textDim, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Windhoek, Walvis Bay',
                  filled: true,
                  fillColor: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: BoostDriveTheme.primaryColor, size: 20),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => _debounceUpdateSearch(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'e.g. Brake Pad Replacement, Flatbed Towing',
                  filled: true,
                  fillColor: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.search, color: BoostDriveTheme.primaryColor, size: 20),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => _debounceUpdateSearch(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickLinks() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _QuickLinkChip(
          icon: Icons.near_me,
          label: 'Nearby Me',
          isSelected: _sortBy == 'closest',
          onTap: () => setState(() => _sortBy = 'closest'),
        ),
        _QuickLinkChip(
          icon: Icons.star_outline,
          label: 'Highly Rated',
          isSelected: _sortBy == 'rated',
          onTap: () => setState(() => _sortBy = 'rated'),
        ),
        _QuickLinkChip(
          icon: Icons.schedule,
          label: 'Available Now',
          isSelected: _availableFilter,
          onTap: () => setState(() => _availableFilter = !_availableFilter),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: TextStyle(fontSize: 12, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _FilterChip(label: 'All', isSelected: _serviceFilter == 'all', onTap: () => setState(() => _serviceFilter = 'all')),
            _FilterChip(label: 'Mechanics', isSelected: _serviceFilter == 'mechanic', onTap: () => setState(() => _serviceFilter = 'mechanic')),
            _FilterChip(label: 'Towing', isSelected: _serviceFilter == 'towing', onTap: () => setState(() => _serviceFilter = 'towing')),
            _FilterChip(label: 'Service Stations', isSelected: _serviceFilter == 'service_station', onTap: () => setState(() => _serviceFilter = 'service_station')),
            _FilterChip(label: 'Parts', isSelected: _serviceFilter == 'parts', onTap: () => setState(() => _serviceFilter = 'parts')),
            _FilterChip(label: 'Rental', isSelected: _serviceFilter == 'rental', onTap: () => setState(() => _serviceFilter = 'rental')),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BoostDriveTheme.primaryColor),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 18, color: BoostDriveTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Filter', style: TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortAndViewToggle() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Sort by', style: TextStyle(fontSize: 12, color: BoostDriveTheme.textDim)),
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
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: BoostDriveTheme.primaryColor),
              const SizedBox(height: 16),
              Text('Loading providers…', style: TextStyle(color: BoostDriveTheme.textDim)),
            ],
          ),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Could not load providers. Try again.', style: TextStyle(color: BoostDriveTheme.textDim)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(verifiedProvidersProvider(serviceType)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: BoostDriveTheme.primaryColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Map view coming soon', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Pins for each provider with Navigate', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isTowing = _serviceFilter == 'towing';
    final message = isTowing
        ? 'No towing services found in this area yet. Try expanding your search radius or select "All" to see other providers.'
        : 'No providers match this filter yet. Try "All" or a different category, or check back as we onboard more providers.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 64, color: BoostDriveTheme.textDim.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            isTowing ? 'No towing services here' : 'No providers found',
            style: TextStyle(fontSize: 18, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: BoostDriveTheme.textDim),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderList(List<UserProfile> list) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ProviderCard(
            profile: p,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _ProviderDetailPage(profile: p),
              ),
            ),
          ),
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

  const _QuickLinkChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
              ? BoostDriveTheme.primaryColor.withValues(alpha: 0.4) 
              : BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                ? BoostDriveTheme.primaryColor 
                : BoostDriveTheme.primaryColor.withValues(alpha: 0.4),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isSelected ? Colors.white : BoostDriveTheme.primaryColor
              ),
              const SizedBox(width: 6),
              Text(
                label, 
                style: TextStyle(
                  color: Colors.white, 
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? BoostDriveTheme.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? BoostDriveTheme.primaryColor : Colors.white24,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : BoostDriveTheme.textDim,
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? BoostDriveTheme.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? BoostDriveTheme.primaryColor : Colors.white24,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : BoostDriveTheme.textDim,
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
    return Container(
      decoration: BoxDecoration(
        color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? BoostDriveTheme.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? BoostDriveTheme.primaryColor : BoostDriveTheme.textDim),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : BoostDriveTheme.textDim,
                ),
              ),
            ],
          ),
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
    final businessContactNumber = (profile.businessContactNumber ?? '').trim();
    final personalContactNumber = (profile.phoneNumber ?? '').trim();
    final hasBusinessContact = businessContactNumber.isNotEmpty;
    final hasPersonalContact = personalContactNumber.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                child: Text(
                  getInitials(profile.displayName),
                  style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.verified, color: BoostDriveTheme.primaryColor, size: 20),
                        ] else ...[
                          const SizedBox(width: 8),
                          Icon(Icons.schedule, size: 18, color: BoostDriveTheme.textDim),
                        ],
                        if (hasPromo) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'PROMO',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            roleLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: BoostDriveTheme.primaryColor),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me, size: 14, color: BoostDriveTheme.textDim),
                            const SizedBox(width: 4),
                            Text(
                              (profile.serviceAreaDescription ?? '').isNotEmpty ? (profile.serviceAreaDescription ?? '') : '— km away',
                              style: TextStyle(fontSize: 12, color: BoostDriveTheme.textDim),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                            const SizedBox(width: 2),
                            Text('— ★', style: TextStyle(fontSize: 12, color: BoostDriveTheme.textDim)),
                            if (profile.yearsInOperation != null) ...[
                              const SizedBox(width: 6),
                              Text('•', style: TextStyle(color: Colors.white24, fontSize: 12)),
                              const SizedBox(width: 6),
                              Text('${profile.yearsInOperation} Yrs Exp', style: TextStyle(fontSize: 12, color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                        Text(
                          (profile.workingHours ?? '').isNotEmpty ? (profile.workingHours ?? '') : 'Open Now',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade400, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                    if ((profile.brandExpertise ?? []).isNotEmpty || (profile.serviceTags ?? []).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...profile.brandExpertise.take(2).map((key) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _SmallSpecializationChip(label: UserProfile.getSpecializationLabel(key)),
                            )),
                            ...profile.serviceTags.take(1).map((key) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _SmallSpecializationChip(label: UserProfile.getSpecializationLabel(key)),
                            )),
                            if (profile.brandExpertise.length + profile.serviceTags.length > 3)
                              Text(
                                '+${profile.brandExpertise.length + profile.serviceTags.length - 3} more',
                                style: TextStyle(fontSize: 11, color: BoostDriveTheme.textDim, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (hasBusinessContact || hasPersonalContact) ...[
                      const SizedBox(height: 8),
                      if (hasBusinessContact)
                        GestureDetector(
                          onTap: () => _launchTel(context, businessContactNumber),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.business_outlined, size: 14, color: BoostDriveTheme.primaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: SelectableText(
                                  'Business: $businessContactNumber',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: BoostDriveTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasBusinessContact && hasPersonalContact) const SizedBox(height: 4),
                      if (hasPersonalContact)
                        GestureDetector(
                          onTap: () => _launchTel(context, personalContactNumber),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.phone_android_outlined, size: 14, color: BoostDriveTheme.primaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: SelectableText(
                                  'Personal: $personalContactNumber',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: BoostDriveTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (hasBusinessContact || hasPersonalContact)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showContactNumbersDialog(
                    context,
                    businessNumber: hasBusinessContact ? businessContactNumber : null,
                    personalNumber: hasPersonalContact ? personalContactNumber : null,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.phone_outlined, color: BoostDriveTheme.primaryColor, size: 24),
                  ),
                ), // GestureDetector
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
    String? businessNumber,
    String? personalNumber,
  }) async {
    if (!kIsWeb || !context.mounted) return;

    final business = (businessNumber ?? '').trim();
    final personal = (personalNumber ?? '').trim();
    final hasBusiness = business.isNotEmpty;
    final hasPersonal = personal.isNotEmpty;
    if (!hasBusiness && !hasPersonal) return;

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
                _contactNumberRow(
                  context: ctx,
                  label: 'Business',
                  value: business,
                ),
              if (hasBusiness && hasPersonal) const SizedBox(height: 10),
              if (hasPersonal)
                _contactNumberRow(
                  context: ctx,
                  label: 'Personal',
                  value: personal,
                ),
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
                  color: Colors.grey.shade600,
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final roleLabel = _ProviderCard._roleDisplayName(profile.role ?? 'mechanic');
    final isVerified = (profile.verificationStatus ?? '').toLowerCase() == 'approved';
    final businessContactNumber = (profile.businessContactNumber ?? '').trim();
    final personalContactNumber = (profile.phoneNumber ?? '').trim();
    final hasBusinessContact = businessContactNumber.isNotEmpty;
    final hasPersonalContact = personalContactNumber.isNotEmpty;
    final primaryContactNumber = hasBusinessContact ? businessContactNumber : personalContactNumber;

    return PremiumPageLayout(
      title: profile.displayName,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                      child: Text(
                        getInitials(profile.displayName),
                        style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(roleLabel, style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600)),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.verified, color: BoostDriveTheme.primaryColor, size: 20),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _SectionTitle(
                  title: 'About',
                  icon: Icons.info_outline,
                ),
                Text(
                  (profile.businessBio ?? '').isNotEmpty ? profile.businessBio! : 'No bio added yet. This provider is part of the BoostDrive verified network.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), height: 1.6, fontSize: 15),
                ),
                if (profile.galleryUrls.any((url) => url.isNotEmpty && url.contains('/provider-galleries/'))) ...[
                  const SizedBox(height: 32),
                  _SectionTitle(
                    title: 'Gallery (${profile.galleryUrls.where((u) => u.isNotEmpty && u.contains('/provider-galleries/')).take(10).length}/10 photos)',
                    subtitle: 'Workshop, tow truck, or completed repairs.',
                    icon: Icons.collections_outlined,
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: profile.galleryUrls.where((u) => u.isNotEmpty && u.contains('/provider-galleries/')).take(10).length,
                    itemBuilder: (context, index) {
                      final url = profile.galleryUrls.where((u) => u.isNotEmpty && u.contains('/provider-galleries/')).take(10).elementAt(index);
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
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
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () => Navigator.pop(ctx),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            child: const Icon(Icons.close, color: Colors.white, size: 22),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                              image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 32),
                if ((profile.brandExpertise ?? []).isNotEmpty || (profile.serviceTags ?? []).isNotEmpty || ((profile.role ?? '').toLowerCase().contains('towing') && (profile.towingCapabilities ?? []).isNotEmpty)) ...[
                  _SectionTitle(
                    title: 'Service Specializations',
                    subtitle: 'Used for search filters and matching.',
                    icon: Icons.build_circle_outlined,
                  ),
                  if (profile.brandExpertise.isNotEmpty) ...[
                    Text('Brand expertise', style: TextStyle(fontSize: 13, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: profile.brandExpertise.map((key) => _SpecializationChip(label: UserProfile.getSpecializationLabel(key))).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (profile.serviceTags.isNotEmpty) ...[
                    Text('Service tags', style: TextStyle(fontSize: 13, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: profile.serviceTags.map((key) => _SpecializationChip(label: UserProfile.getSpecializationLabel(key))).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (profile.role.toLowerCase().contains('towing') && profile.towingCapabilities.isNotEmpty) ...[
                    Text('Towing capabilities', style: TextStyle(fontSize: 13, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: profile.towingCapabilities.map((key) => _SpecializationChip(label: UserProfile.getSpecializationLabel(key))).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
                _SectionTitle(
                  title: 'Trust & Experience',
                  subtitle: 'Business bio and portfolio build customer trust.',
                  icon: Icons.verified_user_outlined,
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    if (profile.yearsInOperation != null)
                      _TrustItem(icon: Icons.history, label: 'Experience', value: '${profile.yearsInOperation} Years'),
                    if (profile.teamSize != null)
                      _TrustItem(icon: Icons.groups_outlined, label: 'Team size', value: '${profile.teamSize} People'),
                    if (profile.standardLaborRate != null)
                      _TrustItem(icon: Icons.payments_outlined, label: 'Labor Rate', value: 'N\$${profile.standardLaborRate}/hr'),
                    _TrustItem(icon: Icons.verified_user_outlined, label: 'Verification', value: isVerified ? 'Approved' : 'Pending'),
                  ],
                ),
                const SizedBox(height: 32),
                if (profile.registrationNumber != null || profile.taxVatNumber != null) ...[
                  _SectionTitle(
                    title: 'Business details',
                    icon: Icons.business_outlined,
                  ),
                  if (profile.registrationNumber != null && profile.registrationNumber!.isNotEmpty)
                    _BusinessDetailRow(label: 'Registration Number', value: profile.registrationNumber!),
                  if (profile.taxVatNumber != null && profile.taxVatNumber!.isNotEmpty)
                    _BusinessDetailRow(label: 'Tax / VAT Number', value: profile.taxVatNumber!),
                  const SizedBox(height: 24),
                ],
                if ((profile.serviceAreaDescription ?? '').isNotEmpty || (profile.workingHours ?? '').isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Location & hours',
                    icon: Icons.location_on_outlined,
                  ),
                  if (profile.serviceAreaDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.near_me, size: 20, color: BoostDriveTheme.textDim),
                          const SizedBox(width: 12),
                          Expanded(child: Text(profile.serviceAreaDescription, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), height: 1.5, fontSize: 15))),
                        ],
                      ),
                    ),
                  if (profile.workingHours.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.schedule, size: 20, color: BoostDriveTheme.textDim),
                        const SizedBox(width: 12),
                        Expanded(child: Text(profile.workingHours, style: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.w700, height: 1.5, fontSize: 15))),
                      ],
                    ),
                  const SizedBox(height: 32),
                ],
                if (hasBusinessContact || hasPersonalContact) ...[
                  _SectionTitle(
                    title: 'Contact Information',
                    icon: Icons.contact_phone_outlined,
                  ),
                  if (hasBusinessContact)
                    GestureDetector(
                      onTap: () => _ProviderCard._launchTel(context, businessContactNumber),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.business_outlined, color: BoostDriveTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              'Business: $businessContactNumber',
                              style: const TextStyle(
                                color: BoostDriveTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasBusinessContact && hasPersonalContact) const SizedBox(height: 8),
                  if (hasPersonalContact)
                    GestureDetector(
                      onTap: () => _ProviderCard._launchTel(context, personalContactNumber),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.phone_android_outlined, color: BoostDriveTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              'Personal: $personalContactNumber',
                              style: const TextStyle(
                                color: BoostDriveTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (hasBusinessContact || hasPersonalContact)
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _ProviderCard._showContactNumbersDialog(
                              context,
                              businessNumber: hasBusinessContact ? businessContactNumber : null,
                              personalNumber: hasPersonalContact ? personalContactNumber : null,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: BoostDriveTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.phone, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Call Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (primaryContactNumber.isNotEmpty) const SizedBox(width: 12),
                    Expanded(
                      child: MouseRegion(
                        cursor: _isStartingConversation ? SystemMouseCursors.basic : SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isStartingConversation ? null : () async {
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
                                  SnackBar(content: Text('Could not start conversation: $e')));
                                setState(() => _isStartingConversation = false);
                              }
                              return;
                            }
                            
                            if (!mounted) return;
                            
                            // Navigate to message page
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => MessagesPage(initialConversationId: conversationId),
                            ));
                            
                            // Reset loading state after a delay or when we might return
                            if (mounted) {
                              setState(() => _isStartingConversation = false);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: BoostDriveTheme.primaryColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isStartingConversation)
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(BoostDriveTheme.primaryColor),
                                    ),
                                  )
                                else ...[
                                  const Icon(Icons.chat_bubble_outline, color: BoostDriveTheme.primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Send Message', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request quote — coming soon')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: BoostDriveTheme.primaryColor),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.request_quote_outlined, color: BoostDriveTheme.primaryColor, size: 20),
                                SizedBox(width: 8),
                                Text('Request Quote', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const _SectionTitle({required this.title, this.subtitle, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: BoostDriveTheme.primaryColor, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SpecializationChip extends StatelessWidget {
  final String label;

  const _SpecializationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.8), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: BoostDriveTheme.primaryColor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TrustItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BoostDriveTheme.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: BoostDriveTheme.primaryColor),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 12, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _BusinessDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _BusinessDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('$label:', style: TextStyle(fontSize: 14, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          SelectableText(value, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SmallSpecializationChip extends StatelessWidget {
  final String label;

  const _SmallSpecializationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
