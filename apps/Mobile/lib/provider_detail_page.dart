import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

import 'messages_page.dart';

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

  Future<void> _launchTel(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
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
    final primaryContactNumber = hasBusinessContact ? businessNumbers.first : personalContactNumber;

    return PremiumPageLayout(
      showBackground: true,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          profile.displayName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                  child: Text(
                    getInitials(profile.displayName),
                    style: const TextStyle(
                      color: BoostDriveTheme.primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (tradingName.isNotEmpty && tradingName != displayNameTrimmed) ...[
                        const SizedBox(height: 4),
                        Text(
                          tradingName,
                          style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              roleLabel,
                              style: const TextStyle(
                                color: BoostDriveTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.verified, color: BoostDriveTheme.primaryColor, size: 22),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionTitle(title: 'About', icon: Icons.info_outline),
            Text(
              businessBioText.isNotEmpty
                  ? businessBioText
                  : 'No bio added yet. This provider is part of the BoostDrive verified network.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), height: 1.55, fontSize: 15),
            ),
            if (_galleryUrls.isNotEmpty) ...[
              const SizedBox(height: 28),
              _SectionTitle(
                title: 'Gallery',
                subtitle: 'Workshop, fleet, or completed work.',
                icon: Icons.collections_outlined,
              ),
              GridView.builder(
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
                  return GestureDetector(
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
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x22FF6600)),
                        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ],
            if (profile.brandExpertise.isNotEmpty ||
                profile.serviceTags.isNotEmpty ||
                (profile.role.toLowerCase().contains('towing') && profile.towingCapabilities.isNotEmpty)) ...[
              const SizedBox(height: 28),
              _SectionTitle(
                title: 'Service specializations',
                subtitle: 'How this provider can help.',
                icon: Icons.build_circle_outlined,
              ),
              if (profile.brandExpertise.isNotEmpty) ...[
                Text('Brand expertise', style: TextStyle(fontSize: 13, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: profile.brandExpertise
                      .map((k) => _SpecChip(label: UserProfile.getSpecializationLabel(k)))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],
              if (profile.serviceTags.isNotEmpty) ...[
                Text('Service tags', style: TextStyle(fontSize: 13, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: profile.serviceTags
                      .map((k) => _SpecChip(label: UserProfile.getSpecializationLabel(k)))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],
              if (profile.role.toLowerCase().contains('towing') && profile.towingCapabilities.isNotEmpty) ...[
                Text('Towing capabilities', style: TextStyle(fontSize: 13, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: profile.towingCapabilities
                      .map((k) => _SpecChip(label: UserProfile.getSpecializationLabel(k)))
                      .toList(),
                ),
              ],
            ],
            const SizedBox(height: 28),
            _SectionTitle(title: 'Trust & experience', icon: Icons.verified_user_outlined),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (profile.yearsInOperation != null)
                  _TrustItem(icon: Icons.history, label: 'Experience', value: '${profile.yearsInOperation} years'),
                if (profile.teamSize != null)
                  _TrustItem(icon: Icons.groups_outlined, label: 'Team size', value: '${profile.teamSize} people'),
                if (profile.standardLaborRate != null)
                  _TrustItem(
                    icon: Icons.payments_outlined,
                    label: 'Labor rate',
                    value: 'N\$${profile.standardLaborRate}/hr',
                  ),
                _TrustItem(
                  icon: Icons.verified_user_outlined,
                  label: 'Verification',
                  value: isVerified ? 'Approved' : 'Pending',
                ),
              ],
            ),
            if (regNumber.isNotEmpty || vatNumber.isNotEmpty) ...[
              const SizedBox(height: 28),
              _SectionTitle(title: 'Business details', icon: Icons.business_outlined),
              if (regNumber.isNotEmpty) _BusinessRow(label: 'Registration', value: regNumber),
              if (vatNumber.isNotEmpty) _BusinessRow(label: 'Tax / VAT', value: vatNumber),
            ],
            if (profile.serviceAreaDescription.isNotEmpty ||
                profile.workingHours.isNotEmpty ||
                workshopAddr.isNotEmpty) ...[
              const SizedBox(height: 28),
              _SectionTitle(title: 'Location & hours', icon: Icons.location_on_outlined),
              if (workshopAddr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.home_work_outlined, size: 20, color: BoostDriveTheme.textDim),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          workshopAddr,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), height: 1.5, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              if (profile.serviceAreaDescription.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.near_me, size: 20, color: BoostDriveTheme.textDim),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profile.serviceAreaDescription,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), height: 1.5, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              if (profile.workingHours.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule, size: 20, color: BoostDriveTheme.textDim),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        profile.workingHours,
                        style: TextStyle(
                          color: Colors.green.shade400,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
            if (website.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _openWebsite(website),
                icon: const Icon(Icons.language, color: BoostDriveTheme.primaryColor),
                label: Text(
                  website.length > 40 ? '${website.substring(0, 40)}…' : website,
                  style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            if (hasBusinessContact || hasPersonalContact) ...[
              const SizedBox(height: 28),
              _SectionTitle(title: 'Contact', icon: Icons.contact_phone_outlined),
              if (hasBusinessContact)
                ...businessNumbers.map(
                  (n) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.business_outlined, color: BoostDriveTheme.primaryColor),
                    title: Text('Business', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
                    subtitle: Text(n, style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600)),
                    onTap: () => _launchTel(n),
                  ),
                ),
              if (hasPersonalContact)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline, color: BoostDriveTheme.primaryColor),
                  title: Text(hasBusinessContact ? 'Personal' : 'Phone', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
                  subtitle: Text(
                    personalContactNumber,
                    style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => _launchTel(personalContactNumber),
                ),
            ],
            const SizedBox(height: 28),
            if (primaryContactNumber.isNotEmpty)
              FilledButton.icon(
                onPressed: () => _launchTel(primaryContactNumber),
                style: FilledButton.styleFrom(
                  backgroundColor: BoostDriveTheme.primaryColor,
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.phone),
                label: const Text('Call now'),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isStartingConversation
                  ? null
                  : () async {
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
                              providerId: profile.uid,
                            );
                        if (!context.mounted) return;
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => MessagesPage(initialConversationId: convId),
                          ),
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not start chat: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isStartingConversation = false);
                      }
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: BoostDriveTheme.primaryColor,
                side: const BorderSide(color: BoostDriveTheme.primaryColor),
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _isStartingConversation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: BoostDriveTheme.primaryColor),
                    )
                  : const Icon(Icons.chat_bubble_outline),
              label: Text(_isStartingConversation ? 'Opening…' : 'Send message'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request quote — coming soon')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: BoostDriveTheme.primaryColor,
                side: const BorderSide(color: BoostDriveTheme.primaryColor),
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Request quote'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: BoostDriveTheme.primaryColor, size: 22),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12)),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: BoostDriveTheme.primaryColor, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FF6600)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: BoostDriveTheme.primaryColor),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 11, color: BoostDriveTheme.textDim, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _BusinessRow extends StatelessWidget {
  const _BusinessRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: TextStyle(fontSize: 14, color: BoostDriveTheme.textDim)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
