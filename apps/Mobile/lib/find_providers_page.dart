import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';

import 'phone_launch_util.dart';
import 'provider_detail_page.dart';

/// Mobile: Find a Provider — Mechanics, Towing, Parts Suppliers, Rental Agencies.
class FindProvidersPage extends ConsumerStatefulWidget {
  const FindProvidersPage({super.key});

  @override
  ConsumerState<FindProvidersPage> createState() => _FindProvidersPageState();
}

class _FindProvidersPageState extends ConsumerState<FindProvidersPage> {
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

  @override
  Widget build(BuildContext context) {
    final serviceType = _getServiceTypeForProvider();
    final providersAsync = ref.watch(verifiedProvidersProvider(serviceType));
    final palette = DashboardPalette.of(context);

    return PremiumPageLayout(
      showBackground: false,
      appBar: ProviderDirectoryUi.listAppBar(context: context, title: 'FIND A PROVIDER'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ProviderDirectoryUi.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            ProviderDirectoryUi.searchField(
              palette: palette,
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
            ),
            const SizedBox(height: 16),
            ProviderDirectoryUi.filterChipRow(
              children: [
                ProviderDirectoryUi.filterChip(
                  palette: palette,
                  label: 'All',
                  selected: _serviceFilter == 'all',
                  onTap: () => setState(() => _serviceFilter = 'all'),
                ),
                ProviderDirectoryUi.filterChip(
                  palette: palette,
                  label: 'Mechanic',
                  selected: _serviceFilter == 'mechanic',
                  onTap: () => setState(() => _serviceFilter = 'mechanic'),
                ),
                ProviderDirectoryUi.filterChip(
                  palette: palette,
                  label: 'Towing',
                  selected: _serviceFilter == 'towing',
                  onTap: () => setState(() => _serviceFilter = 'towing'),
                ),
                ProviderDirectoryUi.filterChip(
                  palette: palette,
                  label: 'Parts',
                  selected: _serviceFilter == 'parts',
                  onTap: () => setState(() => _serviceFilter = 'parts'),
                ),
                ProviderDirectoryUi.filterChip(
                  palette: palette,
                  label: 'Rental',
                  selected: _serviceFilter == 'rental',
                  onTap: () => setState(() => _serviceFilter = 'rental'),
                ),
              ],
            ),
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
                  return ProviderDirectoryUi.emptyState(palette);
                }
                return _buildProviderList(palette, list);
              },
              loading: () => ProviderDirectoryUi.loadingIndicator(palette),
              error: (_, _) => ProviderDirectoryUi.errorState(
                palette: palette,
                onRetry: () => ref.invalidate(verifiedProvidersProvider(serviceType)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderList(DashboardPalette palette, List<UserProfile> list) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        final roleLabel = _roleDisplayName(p.role);
        final isVerified = p.verificationStatus.toLowerCase() == 'approved';
        final businessContactString = (p.businessContactNumber ?? '').trim();
        final businessNumbers = businessContactString
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final primaryContactNumber = businessNumbers.isNotEmpty
            ? businessNumbers.first
            : p.phoneNumber.trim();

        final brandLabels = p.brandExpertise
            .map(UserProfile.getSpecializationLabel)
            .toList();

        final bio = (p.businessBio ?? '').trim();
        final isTowing = p.role.toLowerCase().contains('towing');
        final quoteSnippet = isTowing && bio.isNotEmpty
            ? (bio.length > 120 ? '${bio.substring(0, 120)}…' : bio)
            : null;

        final profileImg = p.profileImg.trim();
        final imageUrl = profileImg.isNotEmpty ? profileImg : null;

        return ProviderDirectoryUi.providerCard(
          palette: palette,
          displayName: p.displayName.isNotEmpty ? p.displayName : 'Provider',
          roleLabel: roleLabel,
          serviceArea: p.serviceAreaDescription,
          workingHours: p.workingHours,
          isVerified: isVerified,
          initials: getInitials(p.displayName),
          profileImageUrl: imageUrl,
          brandLabels: brandLabels,
          quoteSnippet: quoteSnippet,
          onOpenDetail: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ProviderDetailPage(profile: p),
              ),
            );
          },
          onCall: primaryContactNumber.isNotEmpty
              ? () => PhoneLaunchUtil.launchDialer(context, primaryContactNumber)
              : null,
        );
      },
    );
  }
}
