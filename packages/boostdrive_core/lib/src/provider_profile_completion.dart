import 'models/user_profile.dart';

/// Result of evaluating whether a service provider finished profile setup.
class ProviderProfileCompletionStatus {
  const ProviderProfileCompletionStatus({
    required this.isComplete,
    required this.missingStepLabels,
  });

  final bool isComplete;
  final List<String> missingStepLabels;

  int get completedSteps => 2 - missingStepLabels.length;
  int get totalSteps => 2;
}

/// Mirrors validation in [ProfileSettingsPage] provider stepper (steps 0–1).
class ProviderProfileCompletion {
  ProviderProfileCompletion._();

  static ProviderProfileCompletionStatus evaluate(UserProfile profile) {
    if (!profile.isProvider) {
      return const ProviderProfileCompletionStatus(isComplete: true, missingStepLabels: []);
    }
    if (profile.role.toLowerCase().contains('seller')) {
      return const ProviderProfileCompletionStatus(isComplete: true, missingStepLabels: []);
    }

    final missing = <String>[];
    if (!_isBusinessProfileComplete(profile)) {
      missing.add('Business Profile');
    }
    if (!_isLegalDocsComplete(profile)) {
      missing.add('Legal Docs & Certs');
    }

    return ProviderProfileCompletionStatus(
      isComplete: missing.isEmpty,
      missingStepLabels: missing,
    );
  }

  static bool _isBusinessProfileComplete(UserProfile profile) {
    final trading = (profile.tradingName ?? '').trim();
    final registered = (profile.registeredBusinessName ?? '').trim();
    return trading.isNotEmpty || registered.isNotEmpty;
  }

  static bool _isLegalDocsComplete(UserProfile profile) {
    final isTowingProvider = profile.role.toLowerCase() == 'towing' ||
        (profile.primaryServiceCategory?.toLowerCase() == 'towing');
    final requiredSlots = <int>[0, 1, 2, 3, 5, 6];
    if (isTowingProvider) requiredSlots.add(4);
    return requiredSlots.every((i) => _slotHasDoc(profile, i));
  }

  static bool _slotHasDoc(UserProfile profile, int index) {
    if (index >= profile.galleryUrls.length) return false;
    return profile.galleryUrls[index].trim().isNotEmpty;
  }
}
