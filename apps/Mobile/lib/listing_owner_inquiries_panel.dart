import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

import 'messages_page.dart';

String _formatInquiryTimeAgo(dynamic timestamp) {
  if (timestamp == null) return '';
  final DateTime? date = timestamp is String ? DateTime.tryParse(timestamp) : timestamp as DateTime?;
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.day}/${date.month}/${date.year}';
}

String _inquiryInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}

class ListingOwnerInquiriesPanel extends ConsumerWidget {
  final Product product;

  const ListingOwnerInquiriesPanel({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF162128) : Colors.white;
    final titleColor = isDark ? const Color(0xFFD8E4EE) : const Color(0xFF1A1C1C);
    final bodyColor = isDark ? const Color(0xFFE3BFB2) : const Color(0xFF5A4138);
    final mutedColor = isDark ? const Color(0xFFAA8A7E) : const Color(0xFF8F7066);
    final borderColor = isDark ? const Color(0xFF5A4138) : const Color(0xFFE3BFB2);
    final sectionBg = isDark ? const Color(0xFF121D24) : const Color(0xFFF3F3F3);

    final user = ref.watch(currentUserProvider);
    if (user == null || product.sellerId != user.id) {
      return const SizedBox.shrink();
    }

    final inquiriesAsync = ref.watch(
      listingInquiriesProvider(
        ListingInquiriesRequest(productId: product.id, sellerId: user.id),
      ),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.35)),
      ),
      child: inquiriesAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leads & Inquiries', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: titleColor)),
            const SizedBox(height: 16),
            Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor, strokeWidth: 2)),
          ],
        ),
        error: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leads & Inquiries', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: titleColor)),
            const SizedBox(height: 8),
            Text('Could not load inquiries.', style: TextStyle(color: bodyColor)),
          ],
        ),
        data: (inquiries) {
          if (inquiries.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Leads & Inquiries', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: titleColor)),
                const SizedBox(height: 8),
                Text(
                  'No buyer messages yet. Inquiries will appear here.',
                  style: GoogleFonts.montserrat(fontSize: 13, color: bodyColor, height: 1.4),
                ),
              ],
            );
          }

          final preview = inquiries.take(3).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Leads & Inquiries', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: titleColor)),
              const SizedBox(height: 12),
              ...preview.map(
                (conv) => _InquiryRow(
                  conversation: conv,
                  titleColor: titleColor,
                  bodyColor: bodyColor,
                  mutedColor: mutedColor,
                  sectionBg: sectionBg,
                ),
              ),
              if (inquiries.length > preview.length)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MessagesPage()),
                    );
                  },
                  child: Text(
                    'View All Inquiries (${inquiries.length})',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFFB59A) : const Color(0xFFA43700),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InquiryRow extends ConsumerWidget {
  final Map<String, dynamic> conversation;
  final Color titleColor;
  final Color bodyColor;
  final Color mutedColor;
  final Color sectionBg;

  const _InquiryRow({
    required this.conversation,
    required this.titleColor,
    required this.bodyColor,
    required this.mutedColor,
    required this.sectionBg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = conversation['id']?.toString() ?? '';
    final buyerId = conversation['buyer_id']?.toString() ?? '';
    final preview = conversation['last_message']?.toString() ?? 'No messages yet';
    final activityAt = conversation['activity_at'] ?? conversation['last_message_at'] ?? conversation['created_at'];

    Widget row(String name, String? avatarUrl) {
      return InkWell(
        onTap: conversationId.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessagesPage(initialConversationId: conversationId),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: sectionBg,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(_inquiryInitials(name), style: TextStyle(fontWeight: FontWeight.w700, color: titleColor))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: titleColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(preview, style: GoogleFonts.montserrat(fontSize: 13, color: bodyColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(_formatInquiryTimeAgo(activityAt), style: GoogleFonts.montserrat(fontSize: 11, color: mutedColor)),
            ],
          ),
        ),
      );
    }

    if (buyerId.isEmpty) return row('Buyer', null);

    return ref.watch(userProfileProvider(buyerId)).when(
          data: (profile) => row(
            profile?.displayName ?? 'Buyer',
            profile != null && profile.profileImg.isNotEmpty ? profile.profileImg : null,
          ),
          loading: () => row('Loading...', null),
          error: (_, __) => row('Buyer', null),
        );
  }
}
