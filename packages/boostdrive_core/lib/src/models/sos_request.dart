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
  });

  factory SosRequest.fromMap(Map<String, dynamic> map) {
    final location = map['location'] as Map<String, dynamic>? ?? {};
    return SosRequest(
      id: map['id']?.toString() ?? '',
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
      respondedAt: map['responded_at'] != null 
          ? DateTime.tryParse(map['responded_at'].toString())
          : null,
    );
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
    };
  }

  SosRequest copyWith({
    String? status,
    String? assignedProviderId,
    DateTime? respondedAt,
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
    );
  }
}
