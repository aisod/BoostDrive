import 'package:flutter_test/flutter_test.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

void main() {
  test('theme has primaryColor', () {
    expect(BoostDriveTheme.primaryColor, isNotNull);
  });
}
