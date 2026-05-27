import 'dart:async';

import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_palette.dart';
import 'profile_settings_page.dart';
import 'provider_profile_ui.dart';
import 'theme.dart';

/// Re-shows a setup reminder dialog while the provider profile is incomplete.
class ProviderProfileSetupReminderScope extends ConsumerStatefulWidget {
  const ProviderProfileSetupReminderScope({
    super.key,
    required this.profile,
    required this.child,
    this.reminderInterval = const Duration(minutes: 3),
  });

  final UserProfile profile;
  final Widget child;

  /// How long after dismissing before the reminder appears again.
  final Duration reminderInterval;

  @override
  ConsumerState<ProviderProfileSetupReminderScope> createState() =>
      _ProviderProfileSetupReminderScopeState();
}

class _ProviderProfileSetupReminderScopeState
    extends ConsumerState<ProviderProfileSetupReminderScope> {
  Timer? _reminderTimer;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    _scheduleReminderLoop();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowReminder());
  }

  @override
  void didUpdateWidget(ProviderProfileSetupReminderScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.uid != widget.profile.uid ||
        oldWidget.profile.galleryUrls != widget.profile.galleryUrls ||
        oldWidget.profile.tradingName != widget.profile.tradingName ||
        oldWidget.profile.registeredBusinessName != widget.profile.registeredBusinessName) {
      _maybeShowReminder();
    }
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _scheduleReminderLoop() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(widget.reminderInterval, (_) {
      if (!mounted) return;
      _maybeShowReminder();
    });
  }

  ProviderProfileCompletionStatus get _status =>
      ProviderProfileCompletion.evaluate(widget.profile);

  void _maybeShowReminder() {
    if (!mounted || _dialogVisible) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    if (_status.isComplete) return;
    if (!widget.profile.isProvider) return;
    if (widget.profile.role.toLowerCase().contains('seller')) return;

    _showReminderDialog();
  }

  Future<void> _showReminderDialog() async {
    if (!mounted || _dialogVisible || _status.isComplete) return;
    _dialogVisible = true;

    final palette = DashboardPalette.of(context);
    final missing = _status.missingStepLabels;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: palette.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: palette.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Complete your profile',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: palette.onBackground,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your provider profile is not finished. Customers may not see your full listing until setup is complete.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    height: 1.45,
                    color: palette.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Remaining steps (${_status.completedSteps}/${_status.totalSteps} done):',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: palette.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                ...missing.map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.radio_button_unchecked, size: 18, color: palette.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              color: palette.onBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Remind me later',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
              ),
              ElevatedButton(
                style: ProviderProfileUi.primaryButtonStyle(palette).copyWith(
                  backgroundColor: WidgetStatePropertyAll(
                    palette.primary,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileSettingsPage(initialProviderEditMode: true),
                    ),
                  );
                },
                child: Text(
                  'Finish setup',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _dialogVisible = false);
    } else {
      _dialogVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Orange-themed reminder for mobile [ProviderHub] (no dashboard palette).
class ProviderProfileSetupReminderScopeMobile extends ConsumerStatefulWidget {
  const ProviderProfileSetupReminderScopeMobile({
    super.key,
    required this.profile,
    required this.child,
    this.reminderInterval = const Duration(minutes: 3),
  });

  final UserProfile profile;
  final Widget child;
  final Duration reminderInterval;

  @override
  ConsumerState<ProviderProfileSetupReminderScopeMobile> createState() =>
      _ProviderProfileSetupReminderScopeMobileState();
}

class _ProviderProfileSetupReminderScopeMobileState
    extends ConsumerState<ProviderProfileSetupReminderScopeMobile> {
  Timer? _reminderTimer;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    _reminderTimer = Timer.periodic(widget.reminderInterval, (_) {
      if (mounted) _maybeShowReminder();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowReminder());
  }

  @override
  void didUpdateWidget(ProviderProfileSetupReminderScopeMobile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.galleryUrls != widget.profile.galleryUrls ||
        oldWidget.profile.tradingName != widget.profile.tradingName ||
        oldWidget.profile.registeredBusinessName != widget.profile.registeredBusinessName) {
      _maybeShowReminder();
    }
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _maybeShowReminder() {
    final status = ProviderProfileCompletion.evaluate(widget.profile);
    if (!mounted || _dialogVisible || status.isComplete) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    if (!widget.profile.isProvider || widget.profile.role.toLowerCase().contains('seller')) {
      return;
    }
    _showDialog(status);
  }

  Future<void> _showDialog(ProviderProfileCompletionStatus status) async {
    if (!mounted) return;
    _dialogVisible = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: BoostDriveTheme.primaryColor),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete your profile',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Finish setting up your provider profile so customers can find and trust your business.',
              ),
              const SizedBox(height: 16),
              Text(
                'Remaining (${status.completedSteps}/${status.totalSteps}):',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...status.missingStepLabels.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_unchecked,
                          size: 18, color: BoostDriveTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(step, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Remind me later'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BoostDriveTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileSettingsPage(initialProviderEditMode: true),
                  ),
                );
              },
              child: const Text('Finish setup'),
            ),
          ],
        ),
      ),
    );

    if (mounted) setState(() => _dialogVisible = false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
