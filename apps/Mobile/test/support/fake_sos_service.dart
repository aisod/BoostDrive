import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:geolocator/geolocator.dart';

/// In-memory SOS service for widget and flow tests.
class FakeSosService extends SosService {
  final List<(String requestId, String providerId)> acceptCalls = [];
  final List<String> cancelCustomerCalls = [];
  final List<String> cancelAssignmentCalls = [];
  final List<String> completeCalls = [];
  final List<String> respondingUpserts = [];
  final List<String> respondingDeletes = [];

  /// Active SOS rows per customer user id (survives provider invalidation in tests).
  final Map<String, List<SosRequest>> userActiveRequests = {};

  /// Global pending pool for provider Orders SOS tab.
  List<SosRequest> globalPending = [];

  /// Assigned SOS jobs per provider id.
  final Map<String, List<SosRequest>> assignedByProvider = {};

  String? lastRecordedRequestId;
  Exception? acceptError;
  Exception? completeError;
  Exception? cancelAssignmentError;

  @override
  Future<String?> recordSosRequest({
    required String userId,
    required Position position,
    required String type,
    String? userNote,
    String? vehicleId,
    String? emergencyCategory,
  }) async {
    lastRecordedRequestId = 'fake-sos-${DateTime.now().millisecondsSinceEpoch}';
    return lastRecordedRequestId;
  }

  @override
  Future<void> acceptRequest(String requestId, String providerId) async {
    if (acceptError != null) throw acceptError!;
    acceptCalls.add((requestId, providerId));
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    cancelCustomerCalls.add(requestId);
  }

  @override
  Future<void> cancelAssignmentByProvider({
    required String requestId,
    String? reason,
  }) async {
    if (cancelAssignmentError != null) throw cancelAssignmentError!;
    cancelAssignmentCalls.add(requestId);
  }

  @override
  Future<void> completeAssignment({
    required String requestId,
    String? completionNote,
    int requiredDistanceMeters = 300,
  }) async {
    if (completeError != null) throw completeError!;
    completeCalls.add(requestId);
  }

  @override
  Future<void> upsertProviderResponding(String requestId) async {
    respondingUpserts.add(requestId);
  }

  @override
  Future<void> deleteMyProviderResponding(String requestId) async {
    respondingDeletes.add(requestId);
  }

  @override
  Stream<List<SosRequest>> streamActiveRequest(String userId) {
    return Stream.value(List<SosRequest>.from(userActiveRequests[userId] ?? const []));
  }

  @override
  Stream<List<SosRequest>> getGlobalActiveRequests() {
    return Stream.value(List<SosRequest>.from(globalPending));
  }

  @override
  Stream<List<SosRequest>> streamProviderAssignedRequests(String providerId) {
    return Stream.value(List<SosRequest>.from(assignedByProvider[providerId] ?? const []));
  }

  @override
  Future<Position?> getCurrentLocation() async {
    return Position(
      latitude: -22.5609,
      longitude: 17.0658,
      timestamp: DateTime.utc(2026, 5, 27),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
