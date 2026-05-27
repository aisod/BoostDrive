import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_palette.dart';
import 'mobile_customer_ui.dart';

/// Kinetic Precision UI for mobile Messages list + active chat (Stitch exports).
class MessagesUi {
  MessagesUi._();

  static const double marginMobile = MobileCustomerUi.marginMobile;
  static const double radiusCard = MobileCustomerUi.radiusCard;
  static const double radiusControl = MobileCustomerUi.radiusControl;
  static const double radiusBubble = 16;

  static Color primaryButtonFg(DashboardPalette palette) =>
      palette.isDark ? const Color(0xFF1A1A1A) : Colors.white;

  static Color _primaryButtonFg(DashboardPalette palette) => primaryButtonFg(palette);

  static Color scaffoldBackground(DashboardPalette palette) => palette.background;

  static Color threadBackground(DashboardPalette palette) =>
      palette.isDark ? const Color(0xFF0A1218) : Colors.white;

  static Color composerBackground(DashboardPalette palette) =>
      palette.isDark ? const Color(0xFF000000) : Colors.white;

  static PreferredSizeWidget listAppBar({
    required BuildContext context,
    required DashboardPalette palette,
  }) =>
      MobileCustomerUi.topAppBar(context: context, title: 'MESSAGES');

  /// Chat mode: orange bar with back only (participant info is in [chatParticipantHeader]).
  static PreferredSizeWidget chatAppBar({
    required BuildContext context,
    required DashboardPalette palette,
    required VoidCallback onBack,
    List<Widget>? trailing,
  }) {
    return AppBar(
      backgroundColor: palette.primaryContainer,
      elevation: palette.isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _primaryButtonFg(palette)),
        onPressed: onBack,
      ),
      title: const SizedBox.shrink(),
      actions: trailing,
    );
  }

  static Widget chatParticipantHeader({
    required DashboardPalette palette,
    required Widget avatar,
    required String displayName,
    required String contextLine,
    required String listingTypeLabel,
    required bool isDirectMessage,
    String? roleLabel,
  }) {
    final headerBg = palette.primaryContainer;
    final fg = _primaryButtonFg(palette);
    final subFg = fg.withValues(alpha: 0.85);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 14),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(
          bottom: BorderSide(color: fg.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  contextLine,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: subFg,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (roleLabel != null && roleLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    roleLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.03,
                      color: subFg.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (palette.isDark) ...[
            if (roleLabel != null && roleLabel.isNotEmpty)
              _headerBadge(
                label: roleLabel.toUpperCase(),
                bg: fg.withValues(alpha: 0.15),
                fg: fg,
              ),
            const SizedBox(width: 6),
          ],
          _headerBadge(
            label: listingTypeLabel.toUpperCase(),
            bg: isDirectMessage ? fg.withValues(alpha: 0.2) : Colors.white,
            fg: isDirectMessage ? fg : const Color(0xFF1A1A1A),
          ),
        ],
      ),
    );
  }

  static Widget _headerBadge({
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.04,
          color: fg,
        ),
      ),
    );
  }

  static Widget otherUserAvatar({
    required DashboardPalette palette,
    required String initial,
    required String? imageUrl,
    bool isSupport = false,
    double radius = 22,
    bool showOnlineDot = false,
  }) {
    final bg = isSupport
        ? palette.primaryContainer
        : (palette.isDark ? palette.surfaceContainerHigh : palette.surfaceContainer);

    Widget avatar;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor: bg,
            child: Text(initial, style: _avatarText(palette, radius, isOnOrange: false)),
          ),
        ),
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Text(initial, style: _avatarText(palette, radius, isOnOrange: false)),
      );
    }

    if (!showOnlineDot) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: palette.success,
              shape: BoxShape.circle,
              border: Border.all(color: palette.primaryContainer, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  static TextStyle _avatarText(DashboardPalette palette, double radius, {required bool isOnOrange}) {
    return GoogleFonts.manrope(
      fontSize: radius * 0.55,
      fontWeight: FontWeight.w800,
      color: isOnOrange ? _primaryButtonFg(palette) : palette.primaryContainer,
    );
  }

  static Widget conversationTile({
    required DashboardPalette palette,
    required bool isSelected,
    required bool isUnread,
    required Widget avatar,
    required String displayName,
    required String listingTypeLabel,
    required bool isDirectMessage,
    required String roleLabel,
    required String productTitle,
    required String previewText,
    required String? dateLabel,
    required int unreadCount,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final cardBg = palette.surfaceContainerLowest;
    final borderColor = palette.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : palette.outlineVariant.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: marginMobile, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusCard),
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected ? palette.primaryContainer.withValues(alpha: 0.12) : cardBg,
              borderRadius: BorderRadius.circular(radiusCard),
              border: Border.all(
                color: isSelected ? palette.primaryContainer.withValues(alpha: 0.45) : borderColor,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: palette.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      avatar,
                      if (isUnread)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: palette.primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                                  color: palette.title,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (dateLabel != null)
                              Text(
                                dateLabel,
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                  color: isUnread ? palette.primaryContainer : palette.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          productTitle,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.primaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _listingChip(palette, listingTypeLabel, isDirectMessage),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                previewText,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                                  color: palette.body,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (roleLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            roleLabel,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: palette.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    children: [
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: palette.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _primaryButtonFg(palette),
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: palette.error.withValues(alpha: 0.7),
                        ),
                        tooltip: 'Delete conversation',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: palette.onSurfaceVariant.withValues(alpha: 0.5),
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _listingChip(DashboardPalette palette, String label, bool isDirect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDirect
            ? palette.primaryContainer.withValues(alpha: 0.12)
            : palette.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.04,
          color: palette.primaryContainer,
        ),
      ),
    );
  }

  static Widget dateSeparator(DashboardPalette palette, String label) {
    final bg = palette.isDark
        ? palette.surfaceContainerHigh
        : palette.surfaceContainer;
    final fg = palette.isDark ? palette.onSurfaceVariant : palette.body;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.06,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  static BoxDecoration messageBubbleDecoration({
    required DashboardPalette palette,
    required bool isMe,
  }) {
    if (isMe) {
      return BoxDecoration(
        color: palette.primaryContainer,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(radiusBubble),
          topRight: const Radius.circular(radiusBubble),
          bottomLeft: const Radius.circular(radiusBubble),
          bottomRight: const Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primaryContainer.withValues(alpha: palette.isDark ? 0.25 : 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: palette.isDark ? Colors.white : palette.surfaceContainerLowest,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(radiusBubble),
        topRight: const Radius.circular(radiusBubble),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(radiusBubble),
      ),
      border: Border.all(
        color: palette.isDark
            ? Colors.transparent
            : palette.outlineVariant.withValues(alpha: 0.35),
      ),
      boxShadow: palette.isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  static TextStyle messageTextStyle(DashboardPalette palette, {required bool isMe}) {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 1.45,
      color: isMe ? _primaryButtonFg(palette) : (palette.isDark ? Colors.black87 : palette.title),
    );
  }

  static TextStyle senderLabelStyle(DashboardPalette palette, {required bool isAdmin}) {
    return GoogleFonts.montserrat(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      color: isAdmin ? palette.primaryContainer : palette.onSurfaceVariant,
    );
  }

  static Widget messageMetaRow({
    required DashboardPalette palette,
    required bool isMe,
    required String timeLabel,
    required bool isRead,
    required bool isDelivered,
    bool belowBubble = true,
  }) {
    final timeColor = palette.isDark
        ? (isMe ? Colors.white.withValues(alpha: 0.65) : Colors.black54)
        : palette.onSurfaceVariant;

    final ticks = isMe ? readReceiptTicks(palette: palette, isRead: isRead, isDelivered: isDelivered) : null;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeLabel,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: timeColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (ticks != null) ...[const SizedBox(width: 4), ticks],
      ],
    );

    if (!belowBubble) return row;

    return Padding(
      padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 4, right: isMe ? 4 : 0),
      child: row,
    );
  }

  static Widget readReceiptTicks({
    required DashboardPalette palette,
    required bool isRead,
    required bool isDelivered,
  }) {
    const tickSize = 14.0;
    final readColor = palette.isDark ? Colors.white : palette.primaryContainer;
    final unreadColor = readColor.withValues(alpha: palette.isDark ? 0.55 : 0.35);

    if (isRead) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all_rounded, size: tickSize, color: readColor),
        ],
      );
    }

    if (isDelivered) {
      return Icon(Icons.done_all_rounded, size: tickSize, color: unreadColor);
    }

    return Icon(Icons.check_rounded, size: tickSize, color: unreadColor);
  }

  static Widget composerShell({
    required DashboardPalette palette,
    required Widget child,
  }) {
    return Container(
      color: composerBackground(palette),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(top: false, child: child),
    );
  }

  static Widget suspendedBanner(DashboardPalette palette) {
    return composerShell(
      palette: palette,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surfaceContainer,
          borderRadius: BorderRadius.circular(radiusControl),
          border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: palette.primaryContainer, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Messaging is disabled while your account is suspended.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: palette.body,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget composerIconButton({
    required DashboardPalette palette,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? iconColor,
    String? tooltip,
  }) {
    final color = iconColor ?? (palette.isDark ? Colors.white : palette.title);

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 24),
      tooltip: tooltip,
    );
  }

  static Widget composerTextFieldShell({
    required DashboardPalette palette,
    required Widget child,
  }) {
    final fill = palette.isDark
        ? palette.surfaceContainerHigh
        : const Color(0xFFF0F0F0);
    final border = palette.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : palette.outlineVariant.withValues(alpha: 0.25);

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  static Widget sendButton({
    required DashboardPalette palette,
    required VoidCallback onTap,
  }) {
    final borderShape = palette.isDark
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl));

    return Material(
      color: palette.primaryContainer,
      shape: borderShape,
      elevation: palette.isDark ? 0 : 2,
      shadowColor: palette.primaryContainer.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        customBorder: borderShape,
        child: Padding(
          padding: EdgeInsets.all(palette.isDark ? 14 : 12),
          child: Icon(
            Icons.send_rounded,
            color: _primaryButtonFg(palette),
            size: palette.isDark ? 22 : 20,
          ),
        ),
      ),
    );
  }

  static Widget voiceRecordingBar({
    required DashboardPalette palette,
    required String durationText,
    required String hintText,
    required bool micPulse,
    required bool voiceLocked,
    required bool voiceSlideToCancel,
    required VoidCallback onStop,
    required VoidCallback onCancel,
    required VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radiusControl),
        border: Border.all(color: palette.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: micPulse ? 1.08 : 0.96,
            child: Icon(Icons.mic_rounded, color: palette.error, size: 26),
          ),
          const SizedBox(width: 10),
          Text(
            durationText,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.title,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hintText,
              style: GoogleFonts.manrope(fontSize: 12, color: palette.body),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (voiceLocked && onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: palette.body, size: 22),
            ),
          IconButton(
            onPressed: voiceSlideToCancel ? onCancel : onStop,
            icon: Icon(
              voiceSlideToCancel ? Icons.close_rounded : Icons.stop_rounded,
              color: palette.primaryContainer,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  static Widget pendingVoiceBar({
    required DashboardPalette palette,
    required String durationLabel,
    required VoidCallback onContinue,
    required VoidCallback onSend,
    required VoidCallback onDiscard,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radiusControl),
        border: Border.all(color: palette.primaryContainer.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onContinue,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic_rounded, color: palette.primaryContainer, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Voice note $durationLabel',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.title,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSend,
            child: Text(
              'Send',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                color: palette.primaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onDiscard,
            child: Text(
              'Discard',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: palette.body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget pendingImageThumbnails({
    required DashboardPalette palette,
    required List<Widget> thumbnails,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: thumbnails),
      ),
    );
  }

  static Widget pendingImageThumb({
    required DashboardPalette palette,
    required Widget image,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image,
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: palette.isDark ? Colors.black87 : palette.title,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration composerInputDecoration(DashboardPalette palette) {
    final hint = palette.isDark ? Colors.white.withValues(alpha: 0.45) : palette.onSurfaceVariant;

    return InputDecoration(
      hintText: 'Aa',
      hintStyle: GoogleFonts.manrope(fontSize: 15, color: hint),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      prefixIcon: Icon(
        Icons.text_fields_rounded,
        color: palette.onSurfaceVariant,
        size: 20,
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 24),
      suffixIcon: Icon(
        Icons.emoji_emotions_outlined,
        color: palette.onSurfaceVariant,
        size: 22,
      ),
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 24),
    );
  }

  static Future<bool?> showDeleteDialog(BuildContext context, DashboardPalette palette) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
        title: Text(
          'Delete conversation',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: palette.title,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
          style: GoogleFonts.manrope(color: palette.body, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.montserrat(color: palette.body)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: palette.error),
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static void showEmojiPicker({
    required BuildContext context,
    required DashboardPalette palette,
    required List<String> emojis,
    required ValueChanged<String> onEmojiSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emojis
              .map(
                (e) => InkWell(
                  onTap: () {
                    onEmojiSelected(e);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(e, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  static Widget emptyConversationList(DashboardPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: palette.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.title,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget emptyChatSelection(DashboardPalette palette) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: palette.primaryContainer.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Text(
            'Select a conversation to start messaging',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 16, color: palette.body),
          ),
        ],
      ),
    );
  }

  static Widget loginRequired(DashboardPalette palette) {
    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: Text(
          'Please log in to view messages',
          style: GoogleFonts.manrope(fontSize: 16, color: palette.body),
        ),
      ),
    );
  }

  static Widget tabletListHeader(DashboardPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        'Messages',
        style: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: palette.title,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
