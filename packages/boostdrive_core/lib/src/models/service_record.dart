class ServiceRecord {
  final String id;
  final String vehicleId;
  final String providerId;
  final String serviceName;
  final double price;
  final DateTime completedAt;
  final List<String> receiptUrls;
  final int? mileageAtService;

  const ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.providerId,
    required this.serviceName,
    required this.price,
    required this.completedAt,
    this.receiptUrls = const [],
    this.mileageAtService,
  });

  factory ServiceRecord.fromMap(Map<String, dynamic> data) {
    try {
      return ServiceRecord(
        id: data['id']?.toString() ?? '',
        vehicleId: data['vehicle_id']?.toString() ?? '',
        providerId: data['provider_id']?.toString() ?? '',
        serviceName: data['service_name']?.toString() ?? 'Unnamed Service',
        price: (double.tryParse(data['price']?.toString() ?? '0.0') ?? 0.0),
        completedAt: DateTime.tryParse(data['completed_at']?.toString() ?? '') ?? DateTime.now(),
        receiptUrls: (() {
          try {
            if (data['receipt_urls'] is List) {
              return (data['receipt_urls'] as List).map((e) => e.toString()).toList();
            }
            if (data['receipt_url'] != null) {
              return [data['receipt_url'].toString()];
            }
          } catch (_) {}
          return <String>[];
        })(),
        mileageAtService: int.tryParse(data['mileage']?.toString() ?? '') ?? 
                         int.tryParse(data['mileage_at_service']?.toString() ?? ''),
      );
    } catch (e) {
      print("DEBUG: ServiceRecord.fromMap Error: $e for data $data");
      // Return a basic record instead of crashing the whole stream
      return ServiceRecord(
        id: 'error',
        vehicleId: '',
        providerId: '',
        serviceName: 'Error loading record',
        price: 0.0,
        completedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicle_id': vehicleId,
      'provider_id': providerId,
      'service_name': serviceName,
      'price': price,
      'completed_at': completedAt.toIso8601String(),
      'receipt_urls': receiptUrls,
      'mileage': mileageAtService,
    };
  }
}
