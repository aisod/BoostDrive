import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';

/// Pill switch for [themeModeProvider] (light / dark). Matches authenticated nav styling.
class DashboardThemeToggle extends ConsumerWidget {
  const DashboardThemeToggle({
    super.key,
    this.compact = false,
    this.onColoredHeader = false,
  });

  final bool compact;
  /// When true, styles for orange/primary app bars (white track).
  final bool onColoredHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final trackWidth = compact ? 40.0 : 46.0;
    final trackHeight = compact ? 22.0 : 26.0;
    final knobSize = compact ? 16.0 : 20.0;

    final trackColor = onColoredHeader
        ? (isDarkMode ? Colors.white.withValues(alpha: 0.22) : Colors.white)
        : (isDarkMode ? BoostDriveTheme.surfaceDark : Colors.white);
    final borderColor = onColoredHeader
        ? Colors.white.withValues(alpha: isDarkMode ? 0.35 : 0.9)
        : (isDarkMode ? Colors.white.withValues(alpha: 0.18) : const Color(0xFF221C20));
    final knobColor = onColoredHeader
        ? (isDarkMode ? Colors.white : BoostDriveTheme.primaryColor)
        : (isDarkMode ? Colors.white : const Color(0xFF221C20));

    return Tooltip(
      message: 'Switch to ${isDarkMode ? 'light' : 'dark'} mode',
      child: Semantics(
        label: 'Theme mode',
        value: isDarkMode ? 'Dark' : 'Light',
        button: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              ref.read(themeModeProvider.notifier).state =
                  isDarkMode ? ThemeMode.light : ThemeMode.dark;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: trackWidth,
              height: trackHeight,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor, width: 1.4),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: knobSize,
                  height: knobSize,
                  decoration: BoxDecoration(
                    color: knobColor,
                    shape: BoxShape.circle,
                    boxShadow: onColoredHeader && !isDarkMode
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
