import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'main_shell.dart';
import 'login_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        if (state.session != null) {
          final mustSetNewPassword = ref.watch(passwordResetPendingProvider);
          if (mustSetNewPassword) {
            return ResetPasswordPage(
              popOnSuccess: false,
              onPasswordChanged: () {
                ref.read(passwordResetPendingProvider.notifier).state = false;
              },
            );
          }
          return const KeyedSubtree(
            key: ValueKey('main_shell'),
            child: MainShell(),
          );
        } else {
          return const KeyedSubtree(
            key: ValueKey('login'),
            child: LoginPage(),
          );
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, stack) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
