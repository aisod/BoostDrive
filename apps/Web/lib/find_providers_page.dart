import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'messages_page.dart';

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
  final TextEditingController _locationController = TextEditingController(text: 'Windhoek');
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'closest'; // 'closest' | 'rated' | 'experienced'
  bool _isMapView = false;

  @override
  void dispose() {
    _locationController.dispose();
    _searchController.dispose();
    super.dispose();
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
    final serviceType = _getServiceTypeForProvider();
    final providersAsync = ref.watch(verifiedProvidersProvider(serviceType));

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
                  _buildProviderContent(providersAsync, serviceType),
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
                onChanged: (_) => setState(() {}),
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
                onChanged: (_) => setState(() {}),
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
          onTap: () => setState(() => _sortBy = 'closest'),
        ),
        _QuickLinkChip(
          icon: Icons.star_outline,
          label: 'Highly Rated',
          onTap: () => setState(() => _sortBy = 'rated'),
        ),
        _QuickLinkChip(
          icon: Icons.schedule,
          label: 'Available Now',
          onTap: () => setState(() {}),
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
            GestureDetector(
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
        if (list.isEmpty) {
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

  const _QuickLinkChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: BoostDriveTheme.primaryColor),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
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
    return GestureDetector(
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
    return GestureDetector(
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
    return GestureDetector(
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
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onTap;

  const _ProviderCard({required this.profile, this.onTap});

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roleDisplayName(profile.role);
    final isVerified = profile.verificationStatus.toLowerCase() == 'approved';

    return GestureDetector(
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
                  (profile.fullName.isNotEmpty ? profile.fullName[0] : '?').toUpperCase(),
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
                            profile.fullName.isNotEmpty ? profile.fullName : 'Provider',
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
                              (profile.serviceAreaDescription).isNotEmpty ? profile.serviceAreaDescription : '— km away',
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
                          ],
                        ),
                        Text(
                          (profile.workingHours).isNotEmpty ? profile.workingHours : 'Open Now',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade400, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                    if (profile.phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _launchTel(context, profile.phoneNumber),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: BoostDriveTheme.primaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SelectableText(
                                profile.phoneNumber,
                                style: TextStyle(fontSize: 13, color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (profile.phoneNumber.isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _launchTel(context, profile.phoneNumber),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.phone_outlined, color: BoostDriveTheme.primaryColor, size: 24),
                  ),
                ), // GestureDetector
            ],
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

  /// On web, shows a dialog with the number and Copy so the tab doesn't navigate to a blank tel: page.
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
class _ProviderDetailPage extends ConsumerWidget {
  final UserProfile profile;

  const _ProviderDetailPage({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleLabel = _ProviderCard._roleDisplayName(profile.role);
    final isVerified = profile.verificationStatus.toLowerCase() == 'approved';

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.backgroundDark,
        title: Text(profile.fullName.isNotEmpty ? profile.fullName : 'Provider'),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                      child: Text(
                        (profile.fullName.isNotEmpty ? profile.fullName[0] : '?').toUpperCase(),
                        style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName.isNotEmpty ? profile.fullName : 'Provider',
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
                _SectionTitle(title: 'About'),
                Text(
                  'No bio added yet. This provider is part of the BoostDrive verified network.',
                  style: TextStyle(color: BoostDriveTheme.textDim, height: 1.5),
                ),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Gallery'),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text('Photos of workshop or fleet', style: TextStyle(color: BoostDriveTheme.textDim))),
                ),
                const SizedBox(height: 24),
                if (profile.serviceAreaDescription.isNotEmpty || profile.workingHours.isNotEmpty) ...[
                  _SectionTitle(title: 'Location & hours'),
                  if (profile.serviceAreaDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.near_me, size: 18, color: BoostDriveTheme.textDim),
                          const SizedBox(width: 8),
                          Expanded(child: Text(profile.serviceAreaDescription, style: TextStyle(color: BoostDriveTheme.textDim, height: 1.5))),
                        ],
                      ),
                    ),
                  if (profile.workingHours.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.schedule, size: 18, color: BoostDriveTheme.textDim),
                        const SizedBox(width: 8),
                        Expanded(child: Text(profile.workingHours, style: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.w600, height: 1.5))),
                      ],
                    ),
                  const SizedBox(height: 24),
                ],
                _SectionTitle(title: 'Services & pricing'),
                Text('Standard services and starting prices — coming soon.', style: TextStyle(color: BoostDriveTheme.textDim)),
                if (profile.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'Contact'),
                  GestureDetector(
                    onTap: () => _ProviderCard._launchTel(context, profile.phoneNumber),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.phone_outlined, color: BoostDriveTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            profile.phoneNumber,
                            style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 16, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (profile.phoneNumber.isNotEmpty)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _ProviderCard._launchTel(context, profile.phoneNumber),
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
                    if (profile.phoneNumber.isNotEmpty) const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesPage()));
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
                              Icon(Icons.chat_bubble_outline, color: BoostDriveTheme.primaryColor, size: 20),
                              SizedBox(width: 8),
                              Text('Send Message', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}
