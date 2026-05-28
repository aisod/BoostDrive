import '../models/sos_request.dart';

/// Normalizes SOS status strings from API rows.
String normalizeSosStatus(String status) => status.toLowerCase().trim();

/// Statuses shown on the customer live SOS card and eligible for cancel.
const Set<String> sosCustomerLiveStatuses = {
  'pending',
  'assigned',
  'accepted',
  'active',
};

/// Pending requests visible in the provider global pool.
const Set<String> sosGlobalPendingStatuses = {'pending'};

/// Active SOS rows for admin operational monitoring.
const Set<String> sosOperationalActiveStatuses = {
  'pending',
  'assigned',
  'accepted',
  'active',
};

/// Assigned jobs for a provider inbox.
const Set<String> sosProviderAssignedStatuses = {
  'accepted',
  'assigned',
};

bool sosStatusIsCustomerLive(String status) =>
    sosCustomerLiveStatuses.contains(normalizeSosStatus(status));

bool sosStatusIsGlobalPending(String status) =>
    sosGlobalPendingStatuses.contains(normalizeSosStatus(status));

bool sosStatusIsOperationalActive(String status) =>
    sosOperationalActiveStatuses.contains(normalizeSosStatus(status));

bool sosStatusIsProviderAssigned(String status) =>
    sosProviderAssignedStatuses.contains(normalizeSosStatus(status));

/// True when SOS type or emergency category matches provider capability tags.
bool sosRequestMatchesProviderServiceTypes(
  SosRequest request,
  List<String> providerServiceTypes,
) {
  if (providerServiceTypes.isEmpty) return false;
  final caps = providerServiceTypes
      .map((e) => e.toLowerCase().trim())
      .where((e) => e.isNotEmpty)
      .toSet();
  final t = request.type.toLowerCase().trim();
  if (t.isNotEmpty && caps.contains(t)) return true;
  final cat = request.emergencyCategory?.toLowerCase().trim();
  if (cat != null && cat.isNotEmpty && caps.contains(cat)) return true;
  return false;
}

/// Provider SOS detail screen action eligibility.
class SosProviderUiRules {
  SosProviderUiRules._();

  static bool hasValidRequesterLocation(SosRequest request) {
    final lat = request.lat;
    final lng = request.lng;
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    return true;
  }

  static bool canAccept({required SosRequest request, required String? userId}) {
    if (userId == null || userId.isEmpty || request.id.isEmpty) return false;
    final status = normalizeSosStatus(request.status);
    final isPending = status == 'pending';
    final isAlreadyAssigned = request.assignedProviderId != null &&
        request.assignedProviderId!.trim().isNotEmpty;
    return isPending || !isAlreadyAssigned;
  }

  static bool isAssignedToMe({required SosRequest request, required String? userId}) {
    if (userId == null || userId.isEmpty) return false;
    return request.assignedProviderId == userId;
  }

  static bool canComplete({required SosRequest request, required String? userId}) {
    if (!isAssignedToMe(request: request, userId: userId)) return false;
    return const {'assigned', 'accepted', 'active'}
        .contains(normalizeSosStatus(request.status));
  }

  static bool canCancelAssignment({required SosRequest request, required String? userId}) {
    return canComplete(request: request, userId: userId);
  }

  static String actionLabel({required SosRequest request, required String? userId}) {
    if (canAccept(request: request, userId: userId)) return 'ACCEPT REQUEST';
    if (isAssignedToMe(request: request, userId: userId)) return 'ASSIGNED TO YOU';
    return 'ALREADY ASSIGNED';
  }
}

/// Customer hub filters active stream rows for the live card.
List<SosRequest> filterCustomerLiveRequests(List<SosRequest> requests) {
  return requests.where((r) => r.isCustomerSosLive).toList();
}

/// Provider orders tab filters the global pending pool by service types.
List<SosRequest> filterProviderPendingPool({
  required List<SosRequest> allPending,
  required List<String> providerServiceTypes,
}) {
  return allPending
      .where((r) => sosRequestMatchesProviderServiceTypes(r, providerServiceTypes))
      .toList();
}
