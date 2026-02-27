class Vehicle {
  final String id;
  final String ownerId;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final String healthStatus;
  final String fuelLevel;
  final String type; // 'personal', 'logistics'
  final List<String> imageUrls;
  final DateTime createdAt;

  // Existing "New" Fields (V2)
  final int mileage;
  final String tireHealth;
  final String serviceHistoryType;
  final DateTime? lastServiceDate;
  final int? lastServiceMileage;
  final String transmission;
  final String fuelType;
  final String driveType;
  final String? engineCapacity;
  final DateTime? nextLicenseRenewal;
  final String accidentHistory;
  final String? modifications;
  final bool spareKey;
  final String interiorMaterial;
  final String? safetyTech;
  final String? towingCapacity;
  final String? description;

  // V3 Fields
  final int? nextServiceDueMileage;
  final String? oilLife;
  final String? brakeFluidStatus;
  final String? activeFaults;
  final String? vin;
  final DateTime? insuranceExpiry;
  final DateTime? warrantyExpiry;
  final String? fuelEfficiency;
  final String? exteriorCondition;

  const Vehicle({
    required this.id,
    required this.ownerId,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    this.healthStatus = 'Healthy',
    this.fuelLevel = '100%',
    this.type = 'personal',
    this.imageUrls = const [],
    required this.createdAt,
    this.mileage = 0,
    this.tireHealth = 'Brand New',
    this.serviceHistoryType = 'None',
    this.lastServiceDate,
    this.lastServiceMileage,
    this.transmission = 'Automatic',
    this.fuelType = 'Petrol',
    this.driveType = '4x2',
    this.engineCapacity,
    this.nextLicenseRenewal,
    this.accidentHistory = 'No',
    this.modifications,
    this.spareKey = false,
    this.interiorMaterial = 'Cloth',
    this.safetyTech,
    this.towingCapacity,
    this.description,
    this.nextServiceDueMileage,
    this.oilLife,
    this.brakeFluidStatus,
    this.activeFaults,
    this.vin,
    this.insuranceExpiry,
    this.warrantyExpiry,
    this.fuelEfficiency,
    this.exteriorCondition,
  });

  factory Vehicle.fromMap(Map<String, dynamic> data) {
    return Vehicle(
      id: data['id']?.toString() ?? '',
      ownerId: data['owner_id']?.toString() ?? '',
      make: data['make'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      plateNumber: data['plate_number'] ?? '',
      healthStatus: data['health_status'] ?? 'Healthy',
      fuelLevel: data['fuel_level'] ?? '100%',
      type: data['type'] ?? 'personal',
      imageUrls: (data['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
      mileage: data['mileage'] ?? 0,
      tireHealth: data['tire_health'] ?? 'Brand New',
      serviceHistoryType: data['service_history_type'] ?? 'None',
      lastServiceDate: DateTime.tryParse(data['last_service_date']?.toString() ?? ''),
      lastServiceMileage: data['last_service_mileage'],
      transmission: data['transmission'] ?? 'Automatic',
      fuelType: data['fuel_type'] ?? 'Petrol',
      driveType: data['drive_type'] ?? '4x2',
      engineCapacity: data['engine_capacity'],
      nextLicenseRenewal: DateTime.tryParse(data['next_license_renewal']?.toString() ?? ''),
      accidentHistory: data['accident_history'] ?? 'No',
      modifications: data['modifications'],
      spareKey: data['spare_key'] ?? false,
      interiorMaterial: data['interior_material'] ?? 'Cloth',
      safetyTech: data['safety_tech'],
      towingCapacity: data['towing_capacity'],
      description: data['description'],
      nextServiceDueMileage: data['next_service_due_mileage'],
      oilLife: data['oil_life'],
      brakeFluidStatus: data['brake_fluid_status'],
      activeFaults: data['active_faults'],
      vin: data['vin'],
      insuranceExpiry: DateTime.tryParse(data['insurance_expiry']?.toString() ?? ''),
      warrantyExpiry: DateTime.tryParse(data['warranty_expiry']?.toString() ?? ''),
      fuelEfficiency: data['fuel_efficiency'],
      exteriorCondition: data['exterior_condition'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'make': make,
      'model': model,
      'year': year,
      'plate_number': plateNumber,
      'health_status': healthStatus,
      'fuel_level': fuelLevel,
      'type': type,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'mileage': mileage,
      'tire_health': tireHealth,
      'service_history_type': serviceHistoryType,
      'last_service_date': lastServiceDate?.toIso8601String(),
      'last_service_mileage': lastServiceMileage,
      'transmission': transmission,
      'fuel_type': fuelType,
      'drive_type': driveType,
      'engine_capacity': engineCapacity,
      'next_license_renewal': nextLicenseRenewal?.toIso8601String(),
      'accident_history': accidentHistory,
      'modifications': modifications,
      'spare_key': spareKey,
      'interior_material': interiorMaterial,
      'safety_tech': safetyTech,
      'towing_capacity': towingCapacity,
      'description': description,
      'next_service_due_mileage': nextServiceDueMileage,
      'oil_life': oilLife,
      'brake_fluid_status': brakeFluidStatus,
      'active_faults': activeFaults,
      'vin': vin,
      'insurance_expiry': insuranceExpiry?.toIso8601String(),
      'warranty_expiry': warrantyExpiry?.toIso8601String(),
      'fuel_efficiency': fuelEfficiency,
      'exterior_condition': exteriorCondition,
    };
  }
}
