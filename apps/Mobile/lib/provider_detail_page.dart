import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

import 'messages_page.dart';
import 'mobile_app_bar_actions.dart';
import 'phone_launch_util.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full provider profile — parity with web Find a Provider → provider detail.
class ProviderDetailPage extends ConsumerStatefulWidget {
  const ProviderDetailPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends ConsumerState<ProviderDetailPage> {
  bool _isStartingConversation = false;

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

  Future<void> _launchTel(String phone) => PhoneLaunchUtil.launchDialer(context, phone);

  Future<void> _openWebsite(String url) async {
    var u = url.trim();
    if (u.isEmpty) return;
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'https://$u';
    final uri = Uri.tryParse(u);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Iterable<String> get _galleryUrls => widget.profile.galleryUrls
      .where((u) => u.isNotEmpty && u.contains('/provider-galleries/'))
      .take(10);

  String? get _heroImageUrl {
    for (final url in _galleryUrls) {
      return url;
    }
    final img = widget.profile.profileImg.trim();
    return img.isNotEmpty ? img : null;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final palette = DashboardPalette.of(context);
    final roleLabel = _roleDisplayName(profile.role);
    final isVerified = profile.verificationStatus.toLowerCase() == 'approved';
    final tradingName = (profile.tradingName ?? '').trim();
    final displayNameTrimmed = profile.displayName.trim();
    final businessBioText = (profile.businessBio ?? '').trim();
    final regNumber = (profile.registrationNumber ?? '').trim();
    final vatNumber = (profile.taxVatNumber ?? '').trim();
    final workshopAddr = (profile.workshopAddress ?? '').trim();
    final website = (profile.websiteUrl ?? '').trim();

    final businessContactString = (profile.businessContactNumber ?? '').trim();
    final businessNumbers = businessContactString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final personalContactNumber = profile.phoneNumber.trim();
    final hasBusinessContact = businessNumbers.isNotEmpty;
    final hasPersonalContact = personalContactNumber.isNotEmpty;
    final primaryContactNumber =
        hasBusinessContact ? businessNumbers.first : personalContactNumber;

    final locationLine = workshopAddr.isNotEmpty
        ? workshopAddr
        : profile.serviceAreaDescription;

    final specLabels = {
      ...profile.serviceTags.map(UserProfile.getSpecializationLabel),
      ...profile.brandExpertise.map(UserProfile.getSpecializationLabel),
      if (profile.role.toLowerCase().contains('towing'))
        ...profile.towingCapabilities.map(UserProfile.getSpecializationLabel),
    }.take(8).toList();

    final aboutStats = <({String label, String value})>[
      if (profile.yearsInOperation != null)
        (label: 'Experience', value: '${profile.yearsInOperation} years'),
      if (profile.teamSize != null)
        (label: 'Team size', value: '${profile.teamSize} people'),
      if (profile.standardLaborRate != null)
        (label: 'Labor rate', value: 'N\$${profile.standardLaborRate}/hr'),
    ];

    return PremiumPageLayout(
      showBackground: false,
      appBar: ProviderDirectoryUi.detailAppBar(
        context: context,
        palette: palette,
        trailing: mobileAppBarActions(),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          ProviderDirectoryUi.marginMobile,
          8,
          ProviderDirectoryUi.marginMobile,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProviderDirectoryUi.detailHero(
              palette: palette,
              imageUrl: _heroImageUrl,
              isVerified: isVerified,
            ),
            const SizedBox(height: 20),
            ProviderDirectoryUi.detailTitleBlock(
              palette: palette,
              displayName: profile.displayName,
              tradingName: tradingName.isNotEmpty && tradingName != displayNameTrimmed
                  ? tradingName
                  : null,
              roleLabel: roleLabel,
              locationLine: locationLine,
              isVerified: isVerified,
            ),
            if (specLabels.isNotEmpty) ...[
              const SizedBox(height: 14),
              ProviderDirectoryUi.specChipRow(palette: palette, labels: specLabels),
            ],
            const SizedBox(height: 20),
            if (primaryContactNumber.isNotEmpty)
              ProviderDirectoryUi.primaryCallButton(
                palette: palette,
                onPressed: () => _launchTel(primaryContactNumber),
              ),
            const SizedBox(height: 12),
            ProviderDirectoryUi.secondaryActionRow(
              palette: palette,
              leftLabel: 'Request quote',
              leftIcon: Icons.request_quote_outlined,
              onLeft: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request quote — coming soon')),
                );
              },
              rightLabel: 'Message',
              rightIcon: Icons.chat_bubble_outline,
              rightLoading: _isStartingConversation,
              onRight: _isStartingConversation ? null : _startConversation,
            ),
            const SizedBox(height: 24),
            ProviderDirectoryUi.sectionCard(
              palette: palette,
              title: 'About the Specialist',
              icon: Icons.person_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProviderDirectoryUi.bodyText(
                    palette,
                    businessBioText.isNotEmpty
                        ? businessBioText
                        : 'No bio added yet. This provider is part of the BoostDrive verified network.',
                  ),
                  if (aboutStats.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ProviderDirectoryUi.aboutStatsRow(palette: palette, stats: aboutStats),
                  ],
                ],
              ),
            ),
            if (_galleryUrls.isNotEmpty) ...[
              const SizedBox(height: 24),
              ProviderDirectoryUi.sectionCard(
                palette: palette,
                title: 'Gallery',
                subtitle: 'Workshop, fleet, or completed work.',
                icon: Icons.collections_outlined,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: _galleryUrls.length,
                  itemBuilder: (context, index) {
                    final url = _galleryUrls.elementAt(index);
                    return ProviderDirectoryUi.galleryThumbnail(
                      palette: palette,
                      imageUrl: url,
                      onTap: () => _showGalleryDialog(url),
                    );
                  },
                ),
              ),
            ],
            if (profile.brandExpertise.isNotEmpty ||
                profile.serviceTags.isNotEmpty ||
                (profile.role.toLowerCase().contains('towing') &&
                    profile.towingCapabilities.isNotEmpty)) ...[
              const SizedBox(height: 24),
              ProviderDirectoryUi.sectionCard(
                palette: palette,
                title: 'Service specializations',
                subtitle: 'How this provider can help.',
                icon: Icons.build_circle_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.brandExpertise.isNotEmpty) ...[
                      ProviderDirectoryUi.subsectionLabel(palette, 'Brand expertise'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: profile.brandExpertise
                            .map((k) => ProviderDirectoryUi.specChip(
                                  palette: palette,
                                  label: UserProfile.getSpecializationLabel(k),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (profile.serviceTags.isNotEmpty) ...[
                      ProviderDirectoryUi.subsectionLabel(palette, 'Service tags'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: profile.serviceTags
                            .map((k) => ProviderDirectoryUi.specChip(
                                  palette: palette,
                                  label: UserProfile.getSpecializationLabel(k),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (profile.role.toLowerCase().contains('towing') &&
                        profile.towingCapabilities.isNotEmpty) ...[
                      ProviderDirectoryUi.subsectionLabel(palette, 'Towing capabilities'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: profile.towingCapabilities
                            .map((k) => ProviderDirectoryUi.specChip(
                                  palette: palette,
                                  label: UserProfile.getSpecializationLabel(k),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ProviderDirectoryUi.sectionCard(
              palette: palette,
              title: 'Trust & experience',
              icon: Icons.verified_user_outlined,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (profile.yearsInOperation != null)
                    ProviderDirectoryUi.trustTile(
                      palette: palette,
                      icon: Icons.history,
                      label: 'Experience',
                      value: '${profile.yearsInOperation} years',
                    ),
                  if (profile.teamSize != null)
                    ProviderDirectoryUi.trustTile(
                      palette: palette,
                      icon: Icons.groups_outlined,
                      label: 'Team size',
                      value: '${profile.teamSize} people',
                    ),
                  if (profile.standardLaborRate != null)
                    ProviderDirectoryUi.trustTile(
                      palette: palette,
                      icon: Icons.payments_outlined,
                      label: 'Labor rate',
                      value: 'N\$${profile.standardLaborRate}/hr',
                    ),
                  ProviderDirectoryUi.trustTile(
                    palette: palette,
                    icon: Icons.verified_user_outlined,
                    label: 'Verification',
                    value: isVerified ? 'Approved' : 'Pending',
                  ),
                ],
              ),
            ),
            if (regNumber.isNotEmpty || vatNumber.isNotEmpty) ...[
              const SizedBox(height: 24),
              ProviderDirectoryUi.sectionCard(
                palette: palette,
                title: 'Business details',
                icon: Icons.business_outlined,
                child: Column(
                  children: [
                    if (regNumber.isNotEmpty)
                      ProviderDirectoryUi.businessDetailRow(
                        palette: palette,
                        label: 'Registration',
                        value: regNumber,
                      ),
                    if (vatNumber.isNotEmpty)
                      ProviderDirectoryUi.businessDetailRow(
                        palette: palette,
                        label: 'Tax / VAT',
                        value: vatNumber,
                      ),
                  ],
                ),
              ),
            ],
            if (profile.serviceAreaDescription.isNotEmpty ||
                profile.workingHours.isNotEmpty ||
                workshopAddr.isNotEmpty) ...[
              const SizedBox(height: 24),
              ProviderDirectoryUi.sectionCard(
                palette: palette,
                title: 'Location & hours',
                icon: Icons.location_on_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (workshopAddr.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.home_work_outlined, size: 20, color: palette.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(child: ProviderDirectoryUi.bodyText(palette, workshopAddr)),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (profile.serviceAreaDescription.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.near_me, size: 20, color: palette.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ProviderDirectoryUi.bodyText(palette, profile.serviceAreaDescription),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (profile.workingHours.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.schedule, size: 20, color: palette.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              profile.workingHours,
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: palette.primaryContainer,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            if (workshopAddr.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Workshop Location',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.title,
                ),
              ),
              const SizedBox(height: 12),
              ProviderDirectoryUi.workshopMapPlaceholder(
                palette: palette,
                address: workshopAddr,
              ),
            ],
            if (website.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _openWebsite(website),
                icon: Icon(Icons.language, color: palette.primaryContainer),
                label: Text(
                  website.length > 40 ? '${website.substring(0, 40)}…' : website,
                  style: GoogleFonts.manrope(
                    color: palette.primaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (hasBusinessContact || hasPersonalContact) ...[
              const SizedBox(height: 24),
              ProviderDirectoryUi.sectionCard(
                palette: palette,
                title: 'Contact',
                icon: Icons.contact_phone_outlined,
                child: Column(
                  children: [
                    if (hasBusinessContact)
                      ...businessNumbers.map(
                        (n) => ProviderDirectoryUi.contactListTile(
                          palette: palette,
                          icon: Icons.business_outlined,
                          title: 'Business',
                          subtitle: n,
                          onTap: () => _launchTel(n),
                        ),
                      ),
                    if (hasPersonalContact)
                      ProviderDirectoryUi.contactListTile(
                        palette: palette,
                        icon: Icons.person_outline,
                        title: hasBusinessContact ? 'Personal' : 'Phone',
                        subtitle: personalContactNumber,
                        onTap: () => _launchTel(personalContactNumber),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startConversation() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to send a message.')),
        );
      }
      return;
    }
    setState(() => _isStartingConversation = true);
    try {
      final convId = await ref.read(messageServiceProvider).getOrCreateDirectConversation(
            userId: user.id,
            providerId: widget.profile.uid,
          );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MessagesPage(initialConversationId: convId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start chat: $e')),
      );
    } finally {
      if (mounted) setState(() => _isStartingConversation = false);
    }
  }

  void _showGalleryDialog(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                width: double.infinity,
                loadingBuilder: (ctx, child, progress) {
                  if (progress != null) {
                    return const Center(
                      child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor),
                    );
                  }
                  return child;
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
