import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the device dialer with [phone] pre-filled, or copies the number on failure (e.g. web).
class PhoneLaunchUtil {
  PhoneLaunchUtil._();

  static String sanitize(String phone) {
    final buffer = StringBuffer();
    for (final rune in phone.trim().runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '+' || (rune >= 0x30 && rune <= 0x39)) {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  static Future<void> launchDialer(BuildContext context, String phone) async {
    final digits = sanitize(phone);
    if (digits.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available.')),
        );
      }
      return;
    }

    final uri = Uri.parse('tel:$digits');
    try {
      final launched = await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        await _copyAndNotify(context, digits);
      }
    } catch (_) {
      if (context.mounted) await _copyAndNotify(context, digits);
    }
  }

  static Future<void> _copyAndNotify(BuildContext context, String digits) async {
    await Clipboard.setData(ClipboardData(text: digits));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          kIsWeb
              ? 'Number copied ($digits). Open your phone app and paste to call.'
              : 'Could not open the dialer. Number copied: $digits',
        ),
      ),
    );
  }
}
