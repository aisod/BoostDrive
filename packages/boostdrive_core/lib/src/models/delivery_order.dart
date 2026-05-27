class DeliveryOrder {
  final String id;
  final String customerId;
  final String sellerId;
  final String? driverId;
  final String status; // 'pending', 'picking_up', 'in_transit', 'delivered'
  final double? driverLastLat;
  final double? driverLastLng;
  final DateTime? driverLocationUpdatedAt;
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> dropoffLocation;
  final Map<String, dynamic> items;
  final String eta;
  final double? deliveryFee;
  final String? vehicleId;
  final DateTime? updatedAt;
  final DateTime createdAt;

  const DeliveryOrder({
    required this.id,
    required this.customerId,
    required this.sellerId,
    this.driverId,
    this.status = 'pending',
    this.driverLastLat,
    this.driverLastLng,
    this.driverLocationUpdatedAt,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.items,
    this.eta = '',
    this.deliveryFee,
    this.vehicleId,
    this.updatedAt,
    required this.createdAt,
  });

  factory DeliveryOrder.fromMap(Map<String, dynamic> data) {
    return DeliveryOrder(
      id: data['id']?.toString() ?? '',
      customerId: data['customer_id']?.toString() ?? '',
      sellerId: data['seller_id']?.toString() ?? '',
      driverId: data['driver_id']?.toString(),
      status: data['status']?.toString() ?? 'pending',
      driverLastLat: _toDoubleOrNull(data['driver_last_lat']),
      driverLastLng: _toDoubleOrNull(data['driver_last_lng']),
      driverLocationUpdatedAt: data['driver_location_updated_at'] != null
          ? DateTime.tryParse(data['driver_location_updated_at'].toString())
          : null,
      pickupLocation: Map<String, dynamic>.from(data['pickup_location'] ?? {}),
      dropoffLocation: Map<String, dynamic>.from(data['dropoff_location'] ?? {}),
      items: Map<String, dynamic>.from(data['items'] ?? {}),
      eta: data['eta']?.toString() ?? '',
      deliveryFee: _toDoubleOrNull(data['delivery_fee']),
      vehicleId: data['vehicle_id']?.toString(),
      updatedAt: data['updated_at'] != null ? DateTime.tryParse(data['updated_at'].toString()) : null,
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Map marker position: live driver coords when available, else pickup/dropoff by status.
  ({double lat, double lng}) markerCoordinates({double fallbackLat = -22.5609, double fallbackLng = 17.0658}) {
    if (driverLastLat != null && driverLastLng != null) {
      return (lat: driverLastLat!, lng: driverLastLng!);
    }
    final usePickup = status == 'pending' || status == 'picking_up';
    final loc = usePickup ? pickupLocation : dropoffLocation;
    final lat = _toDoubleOrNull(loc['lat']) ?? fallbackLat;
    final lng = _toDoubleOrNull(loc['lng']) ?? fallbackLng;
    return (lat: lat, lng: lng);
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'seller_id': sellerId,
      'driver_id': driverId,
      'status': status,
      'driver_last_lat': driverLastLat,
      'driver_last_lng': driverLastLng,
      'driver_location_updated_at': driverLocationUpdatedAt?.toIso8601String(),
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'items': items,
      'eta': eta,
      'delivery_fee': deliveryFee,
      'vehicle_id': vehicleId,
      'updated_at': updatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
