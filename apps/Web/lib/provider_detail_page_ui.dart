import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

/// Stitch light-mode UI for the provider profile detail screen (Find a Provider → View Profile).
class ProviderDetailLightUi {
  ProviderDetailLightUi._();

  static const Color pageBackground = Color(0xFFF5F7F8);
  static const Color cardBackground = Colors.white;
  static const Color titleColor = Color(0xFF1D2939);
  static const Color bodyColor = Color(0xFF667085);
  static const Color mutedColor = Color(0xFF98A2B3);
  static const Color borderColor = Color(0xFFE4E7EC);
  static const Color avatarBackground = Color(0xFF09151B);

  static const double cardRadius = 16;
  static const double maxContentWidth = 900;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static TextStyle get sectionTitleStyle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: titleColor,
        letterSpacing: -0.3,
      );

  static TextStyle get bodyStyle => GoogleFonts.inter(
        fontSize: 15,
        height: 1.6,
        color: bodyColor,
      );

  static Widget sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: borderColor),
        boxShadow: cardShadow,
      ),
      child: child,
    );
  }

  static Widget sectionHeader({
    required String title,
    IconData? icon,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: BoostDriveTheme.primaryColor, size: 22),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(title, style: sectionTitleStyle)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: mutedColor, height: 1.4)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  static Widget heroCard({
    required String displayName,
    required String initials,
    required String roleLabel,
    required bool isVerified,
  }) {
    return sectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: avatarBackground,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                color: BoostDriveTheme.primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: BoostDriveTheme.primaryColor, size: 22),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    roleLabel,
                    style: GoogleFonts.inter(
                      color: BoostDriveTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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

  static Widget specializationChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: BoostDriveTheme.primaryColor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: BoostDriveTheme.primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Widget trustMetric({
    required IconData icon,
    required String label,
    required String value,
    bool highlightValue = false,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: BoostDriveTheme.primaryColor),
          ),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: highlightValue ? BoostDriveTheme.primaryColor : titleColor,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget businessDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, color: mutedColor, fontWeight: FontWeight.w500),
            ),
          ),
          SelectableText(
            value,
            style: GoogleFonts.inter(fontSize: 14, color: titleColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  static Widget floatingActionBar({
    required bool showCallNow,
    required bool showMessage,
    required bool isStartingConversation,
    required VoidCallback? onCallNow,
    required VoidCallback? onSendMessage,
    required VoidCallback onRequestQuote,
  }) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      color: cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackVertical = constraints.maxWidth < 560;
            final children = <Widget>[
              if (showCallNow)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: onCallNow,
                      icon: const Icon(Icons.phone, size: 20),
                      label: const Text('Call Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: BoostDriveTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              if (showCallNow && showMessage) const SizedBox(width: 10),
              if (showMessage)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: isStartingConversation ? null : onSendMessage,
                      icon: isStartingConversation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text('Send Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BoostDriveTheme.primaryColor,
                        side: const BorderSide(color: BoostDriveTheme.primaryColor, width: 1.5),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              if (showMessage || showCallNow) const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onRequestQuote,
                    icon: const Icon(Icons.request_quote_outlined, size: 20),
                    label: const Text('Request Quote'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BoostDriveTheme.primaryColor,
                      side: const BorderSide(color: BoostDriveTheme.primaryColor, width: 1.5),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ];

            if (stackVertical) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showCallNow) ...[
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onCallNow,
                        icon: const Icon(Icons.phone, size: 20),
                        label: const Text('Call Now'),
                        style: FilledButton.styleFrom(
                          backgroundColor: BoostDriveTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (showMessage) ...[
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isStartingConversation ? null : onSendMessage,
                        icon: isStartingConversation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chat_bubble_outline, size: 20),
                        label: const Text('Send Message'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BoostDriveTheme.primaryColor,
                          side: const BorderSide(color: BoostDriveTheme.primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRequestQuote,
                      icon: const Icon(Icons.request_quote_outlined, size: 20),
                      label: const Text('Request Quote'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BoostDriveTheme.primaryColor,
                        side: const BorderSide(color: BoostDriveTheme.primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(children: children);
          },
        ),
      ),
    );
  }

  static Widget gallerySection({
    required List<String> galleryUrls,
    required void Function(String url) onImageTap,
    required Widget actionBar,
  }) {
    final urls = galleryUrls
        .where((u) => u.isNotEmpty && u.contains('/provider-galleries/'))
        .take(10)
        .toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    return sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionHeader(
            title: 'Gallery (${urls.length}/10 photos)',
            subtitle: 'Workshop, tow truck, or completed repairs.',
            icon: Icons.collections_outlined,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  final url = urls[index];
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onImageTap(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            image: DecorationImage(
                              image: NetworkImage(url),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 28),
          actionBar,
        ],
      ),
    );
  }
}

/// Full light-mode provider detail body (UI only — callbacks preserve existing behavior).
class ProviderDetailLightView extends StatelessWidget {
  final UserProfile profile;
  final String roleLabel;
  final bool isVerified;
  final List<String> businessNumbers;
  final bool hasBusinessContact;
  final bool hasPersonalContact;
  final bool isStartingConversation;
  final VoidCallback? onCallNow;
  final VoidCallback? onSendMessage;
  final VoidCallback onRequestQuote;
  final void Function(String url) onGalleryImageTap;
  final void Function(String number)? onBusinessNumberTap;

  const ProviderDetailLightView({
    super.key,
    required this.profile,
    required this.roleLabel,
    required this.isVerified,
    required this.businessNumbers,
    required this.hasBusinessContact,
    required this.hasPersonalContact,
    required this.isStartingConversation,
    required this.onCallNow,
    required this.onSendMessage,
    required this.onRequestQuote,
    required this.onGalleryImageTap,
    this.onBusinessNumberTap,
  });

  bool get _hasSpecializations =>
      profile.brandExpertise.isNotEmpty ||
      profile.serviceTags.isNotEmpty ||
      (profile.role.toLowerCase().contains('towing') && profile.towingCapabilities.isNotEmpty);

  bool get _hasGallery =>
      profile.galleryUrls.any((u) => u.isNotEmpty && u.contains('/provider-galleries/'));

  @override
  Widget build(BuildContext context) {
    final bio = (profile.businessBio ?? '').trim();
    final actionBar = ProviderDetailLightUi.floatingActionBar(
      showCallNow: hasBusinessContact,
      showMessage: true,
      isStartingConversation: isStartingConversation,
      onCallNow: onCallNow,
      onSendMessage: onSendMessage,
      onRequestQuote: onRequestQuote,
    );

    return ColoredBox(
      color: ProviderDetailLightUi.pageBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ProviderDetailLightUi.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProviderDetailLightUi.heroCard(
                  displayName: profile.displayName,
                  initials: getInitials(profile.displayName),
                  roleLabel: roleLabel,
                  isVerified: isVerified,
                ),
                const SizedBox(height: 16),
                ProviderDetailLightUi.sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProviderDetailLightUi.sectionHeader(
                        title: 'About',
                        icon: Icons.info_outline,
                      ),
                      Text(
                        bio.isNotEmpty
                            ? bio
                            : 'No bio added yet. This provider is part of the BoostDrive verified network.',
                        style: ProviderDetailLightUi.bodyStyle,
                      ),
                    ],
                  ),
                ),
                if (_hasGallery) ...[
                  const SizedBox(height: 16),
                  ProviderDetailLightUi.gallerySection(
                    galleryUrls: profile.galleryUrls,
                    onImageTap: onGalleryImageTap,
                    actionBar: actionBar,
                  ),
                ],
                if (!_hasGallery) ...[
                  const SizedBox(height: 16),
                  ProviderDetailLightUi.sectionCard(child: actionBar),
                ],
                if (_hasSpecializations) ...[
                  const SizedBox(height: 16),
                  ProviderDetailLightUi.sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProviderDetailLightUi.sectionHeader(
                          title: 'Service Specializations',
                          subtitle: 'Used for search filters and matching.',
                          icon: Icons.build_circle_outlined,
                        ),
                        if (profile.brandExpertise.isNotEmpty) ...[
                          Text(
                            'Brand expertise',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: ProviderDetailLightUi.mutedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: profile.brandExpertise
                                .map((k) => ProviderDetailLightUi.specializationChip(
                                      UserProfile.getSpecializationLabel(k),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (profile.serviceTags.isNotEmpty) ...[
                          Text(
                            'Service tags',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: ProviderDetailLightUi.mutedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: profile.serviceTags
                                .map((k) => ProviderDetailLightUi.specializationChip(
                                      UserProfile.getSpecializationLabel(k),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (profile.role.toLowerCase().contains('towing') &&
                            profile.towingCapabilities.isNotEmpty) ...[
                          Text(
                            'Towing capabilities',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: ProviderDetailLightUi.mutedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: profile.towingCapabilities
                                .map((k) => ProviderDetailLightUi.specializationChip(
                                      UserProfile.getSpecializationLabel(k),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ProviderDetailLightUi.sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProviderDetailLightUi.sectionHeader(
                        title: 'Trust & Experience',
                        subtitle: 'Business bio and portfolio build customer trust.',
                        icon: Icons.verified_user_outlined,
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (profile.yearsInOperation != null)
                            ProviderDetailLightUi.trustMetric(
                              icon: Icons.history,
                              label: 'Experience',
                              value: '${profile.yearsInOperation} Years',
                            ),
                          if (profile.teamSize != null)
                            ProviderDetailLightUi.trustMetric(
                              icon: Icons.groups_outlined,
                              label: 'Team size',
                              value: '${profile.teamSize} People',
                            ),
                          if (profile.standardLaborRate != null)
                            ProviderDetailLightUi.trustMetric(
                              icon: Icons.payments_outlined,
                              label: 'Labor Rate',
                              value: 'N\$${profile.standardLaborRate}/hr',
                            ),
                          ProviderDetailLightUi.trustMetric(
                            icon: Icons.verified_user_outlined,
                            label: 'Verification',
                            value: isVerified ? 'Approved' : 'Pending',
                            highlightValue: isVerified,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if ((profile.registrationNumber ?? '').isNotEmpty ||
                    (profile.taxVatNumber ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ProviderDetailLightUi.sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProviderDetailLightUi.sectionHeader(
                          title: 'Business details',
                          icon: Icons.business_outlined,
                        ),
                        if (profile.registrationNumber != null &&
                            profile.registrationNumber!.isNotEmpty)
                          ProviderDetailLightUi.businessDetailRow(
                            label: 'Registration Number',
                            value: profile.registrationNumber!,
                          ),
                        if (profile.taxVatNumber != null && profile.taxVatNumber!.isNotEmpty)
                          ProviderDetailLightUi.businessDetailRow(
                            label: 'Tax / VAT Number',
                            value: profile.taxVatNumber!,
                          ),
                      ],
                    ),
                  ),
                ],
                if (profile.serviceAreaDescription.isNotEmpty || profile.workingHours.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ProviderDetailLightUi.sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProviderDetailLightUi.sectionHeader(
                          title: 'Location & hours',
                          icon: Icons.location_on_outlined,
                        ),
                        if (profile.serviceAreaDescription.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.near_me, size: 20, color: ProviderDetailLightUi.mutedColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    profile.serviceAreaDescription,
                                    style: ProviderDetailLightUi.bodyStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (profile.workingHours.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.schedule, size: 20, color: ProviderDetailLightUi.mutedColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  profile.workingHours,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF12B76A),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
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
                if (hasBusinessContact) ...[
                  const SizedBox(height: 16),
                  ProviderDetailLightUi.sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProviderDetailLightUi.sectionHeader(
                          title: 'Contact Information',
                          icon: Icons.contact_phone_outlined,
                        ),
                        ...businessNumbers.map(
                          (number) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: onBusinessNumberTap != null ? () => onBusinessNumberTap!(number) : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.business_outlined,
                                    color: BoostDriveTheme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SelectableText(
                                      'Business: $number',
                                      style: GoogleFonts.inter(
                                        color: BoostDriveTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        decoration: TextDecoration.underline,
                                        decorationColor: BoostDriveTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }
}
