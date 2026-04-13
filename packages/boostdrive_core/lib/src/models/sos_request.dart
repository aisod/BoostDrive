class SosRequest {
  final String id;
  final String userId;
  final String type;
  final String status; // 'pending' | 'accepted' | 'assigned' | 'cancelled' | 'resolved'
  final double lat;
  final double lng;
  final String userNote;
  final DateTime createdAt;
  final String? assignedProviderId;
  final DateTime? respondedAt;
  final String? vehicleId;
  final String? emergencyCategory;
  final double? providerLastLat;
  final double? providerLastLng;
  final DateTime? providerLocationUpdatedAt;
  final int? etaMinutes;

  const SosRequest({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.lat,
    required this.lng,
    required this.userNote,
    required this.createdAt,
    this.assignedProviderId,
    this.respondedAt,
    this.vehicleId,
    this.emergencyCategory,
    this.providerLastLat,
    this.providerLastLng,
    this.providerLocationUpdatedAt,
    this.etaMinutes,
  });

  factory SosRequest.fromMap(Map<String, dynamic> map) {
    final location = map['location'] as Map<String, dynamic>? ?? {};
    return SosRequest(
      id: map['id']?.toString() ?? map['sos_request_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'emergency',
      status: map['status']?.toString() ?? 'pending',
      lat: (location['lat'] ?? 0.0).toDouble(),
      lng: (location['lng'] ?? 0.0).toDouble(),
      userNote: map['user_note']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      assignedProviderId: map['assigned_provider_id']?.toString(),
      respondedAt: map['responded_at'] != null ? DateTime.tryParse(map['responded_at'].toString()) : null,
      vehicleId: map['vehicle_id']?.toString(),
      emergencyCategory: map['emergency_category']?.toString(),
      providerLastLat: _toDoubleOrNull(map['provider_last_lat']),
      providerLastLng: _toDoubleOrNull(map['provider_last_lng']),
      providerLocationUpdatedAt: map['provider_location_updated_at'] != null
          ? DateTime.tryParse(map['provider_location_updated_at'].toString())
          : null,
      etaMinutes: _toIntOrNull(map['eta_minutes']),
    );
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  /// Statuses that show the customer live SOS UI and allow cancel (aligned with active SOS stream filter / RPC).
  static const Set<String> _customerLiveStatuses = {
    'pending',
    'assigned',
    'accepted',
    'active',
  };

  /// Whether this row is an open customer SOS (show live card, enable Cancel).
  bool get isCustomerSosLive {
    final s = status.toLowerCase().trim();
    return _customerLiveStatuses.contains(s);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'status': status,
      'location': {'lat': lat, 'lng': lng},
      'user_note': userNote,
      'created_at': createdAt.toIso8601String(),
      'assigned_provider_id': assignedProviderId,
      'responded_at': respondedAt?.toIso8601String(),
      'vehicle_id': vehicleId,
      'emergency_category': emergencyCategory,
      'provider_last_lat': providerLastLat,
      'provider_last_lng': providerLastLng,
      'provider_location_updated_at': providerLocationUpdatedAt?.toIso8601String(),
      'eta_minutes': etaMinutes,
    };
  }

  SosRequest copyWith({
    String? status,
    String? assignedProviderId,
    DateTime? respondedAt,
    String? vehicleId,
    String? emergencyCategory,
    double? providerLastLat,
    double? providerLastLng,
    DateTime? providerLocationUpdatedAt,
    int? etaMinutes,
  }) {
    return SosRequest(
      id: id,
      userId: userId,
      type: type,
      status: status ?? this.status,
      lat: lat,
      lng: lng,
      userNote: userNote,
      createdAt: createdAt,
      assignedProviderId: assignedProviderId ?? this.assignedProviderId,
      respondedAt: respondedAt ?? this.respondedAt,
      vehicleId: vehicleId ?? this.vehicleId,
      emergencyCategory: emergencyCategory ?? this.emergencyCategory,
      providerLastLat: providerLastLat ?? this.providerLastLat,
      providerLastLng: providerLastLng ?? this.providerLastLng,
      providerLocationUpdatedAt: providerLocationUpdatedAt ?? this.providerLocationUpdatedAt,
      etaMinutes: etaMinutes ?? this.etaMinutes,
    );
  }
}
