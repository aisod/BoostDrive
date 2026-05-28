import 'package:boostdrive_core/boostdrive_core.dart';

SosRequest pendingMechanicRequest({
  String id = 'sos-pending-1',
  String userId = 'customer-1',
}) {
  return SosRequest(
    id: id,
    userId: userId,
    type: 'mechanic',
    status: 'pending',
    lat: -22.5609,
    lng: 17.0658,
    userNote: 'Engine stalled on highway',
    createdAt: DateTime.utc(2026, 5, 27, 8),
    emergencyCategory: 'mechanical',
  );
}

SosRequest assignedToProviderRequest({
  String id = 'sos-assigned-1',
  String providerId = 'provider-1',
  String userId = 'customer-1',
  String status = 'assigned',
}) {
  return SosRequest(
    id: id,
    userId: userId,
    type: 'mechanic',
    status: status,
    lat: -22.5609,
    lng: 17.0658,
    userNote: 'Flat tire',
    createdAt: DateTime.utc(2026, 5, 27, 9),
    assignedProviderId: providerId,
    emergencyCategory: 'flat_tire',
  );
}
