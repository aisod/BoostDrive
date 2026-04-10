import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mobile: Find a Provider — Mechanics, Towing, Parts Suppliers, Rental Agencies.
/// Same filters and data as Web; uses verifiedProvidersProvider with fallback so list is never blank.
class FindProvidersPage extends ConsumerStatefulWidget {
  const FindProvidersPage({super.key});

  @override
  ConsumerState<FindProvidersPage> createState() => _FindProvidersPageState();
}

class _FindProvidersPageState extends ConsumerState<FindProvidersPage> {
  /// 'all' | 'mechanic' | 'towing' | 'parts' | 'rental'
  String _serviceFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
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
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceType = _getServiceTypeForProvider();
    final providersAsync = ref.watch(verifiedProvidersProvider(serviceType));

    return PremiumPageLayout(
      showBackground: true,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Find a Provider',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Verified service providers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Browse mechanics and towing providers verified by BoostDrive. Use filters to find the right help.',
              style: TextStyle(fontSize: 13, color: Colors.white, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name, role, or service area...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: BoostDriveTheme.surfaceDark.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterChips(),
            const SizedBox(height: 20),
            providersAsync.when(
              data: (allData) {
                final list = allData.where((p) {
                  if (_searchQuery.isEmpty) return true;
                  final matchName = p.fullName.toLowerCase().contains(_searchQuery);
                  final matchRole = p.role.toLowerCase().contains(_searchQuery);
                  final matchArea = p.serviceAreaDescription.toLowerCase().contains(_searchQuery);
                  return matchName || matchRole || matchArea;
                }).toList();
                
                if (list.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildProviderList(list);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor)),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load providers. Try again.',
                        style: TextStyle(color: BoostDriveTheme.textDim),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(verifiedProvidersProvider(serviceType)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _FilterChip(label: 'All', isSelected: _serviceFilter == 'all', onTap: () => setState(() => _serviceFilter = 'all')),
        _FilterChip(label: 'Mechanic', isSelected: _serviceFilter == 'mechanic', onTap: () => setState(() => _serviceFilter = 'mechanic')),
        _FilterChip(label: 'Towing', isSelected: _serviceFilter == 'towing', onTap: () => setState(() => _serviceFilter = 'towing')),
        _FilterChip(label: 'Parts', isSelected: _serviceFilter == 'parts', onTap: () => setState(() => _serviceFilter = 'parts')),
        _FilterChip(label: 'Rental', isSelected: _serviceFilter == 'rental', onTap: () => setState(() => _serviceFilter = 'rental')),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.white.withOpacity(0.8)),
            const SizedBox(height: 16),
            const Text(
              'No providers match this filter yet.',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try "All", adjust your search, or check back as we onboard more providers.',
              style: TextStyle(fontSize: 14, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        return _ProviderCard(profile: p);
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: BoostDriveTheme.primaryColor.withOpacity(0.3),
      checkmarkColor: BoostDriveTheme.primaryColor,
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final UserProfile profile;

  const _ProviderCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roleDisplayName(profile.role);
    final isVerified = profile.verificationStatus.toLowerCase() == 'approved';
    final businessContactString = (profile.businessContactNumber ?? '').trim();
    final List<String> businessNumbers = businessContactString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final hasBusinessContact = businessNumbers.isNotEmpty;
    final primaryContactNumber = hasBusinessContact ? businessNumbers.first : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
              child: Text(
                (profile.fullName.isNotEmpty ? profile.fullName[0] : '?').toUpperCase(),
                style: const TextStyle(
                  color: BoostDriveTheme.primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BoostDriveTheme.primaryColor,
                          ),
                        ),
                      ),
                      if (profile.serviceAreaDescription.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            profile.serviceAreaDescription,
                            style: TextStyle(fontSize: 12, color: BoostDriveTheme.textDim),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (profile.workingHours.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            profile.workingHours,
                            style: TextStyle(fontSize: 11, color: Colors.green.shade400, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasBusinessContact) ...[
                    const SizedBox(height: 8),
                    if (hasBusinessContact)
                      ...businessNumbers.map((number) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: GestureDetector(
                          onTap: () => _launchTel(number),
                          child: Row(
                            children: [
                              const Icon(Icons.business_outlined, size: 14, color: BoostDriveTheme.primaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Business: $number',
                                  style: const TextStyle(fontSize: 13, color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  ],
                ],
              ),
            ),
            if (primaryContactNumber.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.phone_outlined, color: BoostDriveTheme.primaryColor),
                onPressed: () => _launchTel(primaryContactNumber),
                tooltip: 'Call $primaryContactNumber',
              ),
          ],
        ),
      ),
    );
  }

  String _roleDisplayName(String role) {
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

  Future<void> _launchTel(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
    }
  }
}
