import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boost_drive_web/listing_detail_widgets.dart';
import 'package:boost_drive_web/messages_page.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';

String formatInquiryTimeAgo(dynamic timestamp) {
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

String inquiryInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}

/// Owner-side leads and inquiries for a single listing (real message threads).
class ListingOwnerInquiriesPanel extends ConsumerWidget {
  final Product product;

  const ListingOwnerInquiriesPanel({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ListingDetailPalette.of(context);
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderColor.withValues(alpha: 0.35)),
        boxShadow: palette.ambientLow,
      ),
      child: inquiriesAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leads & Inquiries',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.titleColor,
              ),
            ),
            const SizedBox(height: 20),
            Center(child: CircularProgressIndicator(color: palette.primary, strokeWidth: 2)),
          ],
        ),
        error: (e, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leads & Inquiries',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.titleColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load inquiries.',
              style: GoogleFonts.montserrat(fontSize: 13, color: palette.bodyColor),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(
                listingInquiriesProvider(
                  ListingInquiriesRequest(productId: product.id, sellerId: user.id),
                ),
              ),
              child: Text('Retry', style: TextStyle(color: palette.primaryText)),
            ),
          ],
        ),
        data: (inquiries) {
          if (inquiries.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leads & Inquiries',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No buyer messages yet. Inquiries from interested buyers will appear here.',
                  style: GoogleFonts.montserrat(fontSize: 13, height: 1.45, color: palette.bodyColor),
                ),
              ],
            );
          }

          final preview = inquiries.take(3).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leads & Inquiries',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.titleColor,
                ),
              ),
              const SizedBox(height: 16),
              ...preview.map(
                (conv) => _InquiryRow(
                  conversation: conv,
                  palette: palette,
                ),
              ),
              if (inquiries.length > preview.length) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MessagesPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: palette.primaryText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'View All Inquiries (${inquiries.length})',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InquiryRow extends ConsumerWidget {
  final Map<String, dynamic> conversation;
  final ListingDetailPalette palette;

  const _InquiryRow({
    required this.conversation,
    required this.palette,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = conversation['id']?.toString() ?? '';
    final buyerId = conversation['buyer_id']?.toString() ?? '';
    final previewText = conversation['last_message']?.toString() ?? 'No messages yet';
    final activityAt = conversation['activity_at'] ?? conversation['last_message_at'] ?? conversation['created_at'];

    if (buyerId.isEmpty) {
      return _rowContent(context, 'Buyer', previewText, activityAt, conversationId, null);
    }

    return ref.watch(userProfileProvider(buyerId)).when(
          data: (profile) => _rowContent(
            context,
            profile?.displayName ?? 'Buyer',
            previewText,
            activityAt,
            conversationId,
            profile != null && profile.profileImg.isNotEmpty ? profile.profileImg : null,
          ),
          loading: () => _rowContent(context, 'Loading...', previewText, activityAt, conversationId, null),
          error: (_, __) => _rowContent(context, 'Buyer', previewText, activityAt, conversationId, null),
        );
  }

  Widget _rowContent(
    BuildContext context,
    String name,
    String preview,
    dynamic activityAt,
    String conversationId,
    String? avatarUrl,
  ) {
    final initials = inquiryInitials(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: palette.sectionBackground.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: palette.secondaryFixed.withValues(alpha: 0.45),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          initials,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: palette.titleColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: palette.titleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: palette.bodyColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatInquiryTimeAgo(activityAt),
                  style: GoogleFonts.montserrat(fontSize: 12, color: palette.mutedColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
