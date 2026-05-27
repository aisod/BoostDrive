import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:flutter/material.dart';

/// Standard app-bar trailing actions for mobile screens (theme toggle + optional icons).
List<Widget> mobileAppBarActions({
  List<Widget>? trailing,
  bool onColoredHeader = true,
}) {
  return MobileCustomerUi.appBarActions(
    trailing: trailing,
    onColoredHeader: onColoredHeader,
  );
}
