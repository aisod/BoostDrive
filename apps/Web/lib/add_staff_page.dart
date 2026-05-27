import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'add_staff_sheet.dart';

/// Legacy route — opens the quick-add staff sheet.
class AddStaffPage extends ConsumerWidget {
  const AddStaffPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await showAddStaffSheet(context, ref);
      if (context.mounted) Navigator.maybePop(context);
    });
    return Scaffold(
      backgroundColor: DashboardPalette.of(context).background,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
