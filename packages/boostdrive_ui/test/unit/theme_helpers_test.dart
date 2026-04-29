import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getInitials', () {
    test('returns U for empty value', () {
      expect(getInitials(''), 'U');
    });

    test('returns first letter for single-name values', () {
      expect(getInitials('boostdrive'), 'B');
    });

    test('returns first and last initials for full names', () {
      expect(getInitials('Saya Driver'), 'SD');
    });
  });
}
