class UserProfile {
  final String uid;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String role; // 'customer', 'mechanic', 'towing', 'admin'
  final String profileImg;
  final bool isBuyer;
  final bool isSeller;
  final DateTime createdAt;
  final DateTime lastActive;
  final int loyaltyPoints;
  final bool isOnline;
  final String verificationStatus; // 'pending' | 'approved' | 'rejected' | 'unverified'
  final String status; // 'active' | 'banned' | 'frozen'
  final bool isAdmin;

  static const Map<String, String> brandOptions = {
    'toyota': 'Toyota', 'bmw': 'BMW', 'land_rover': 'Land Rover', 'ford': 'Ford',
    'mercedes': 'Mercedes', 'nissan': 'Nissan', 'volkswagen': 'Volkswagen',
  };

  static const Map<String, String> serviceTagOptions = {
    'diagnostics': 'Diagnostics', 'hybrid_electric': 'Hybrid/Electric', 'panel_beating': 'Panel Beating',
    'ac_repair': 'AC Repair', 'gearbox': 'Gearbox Specialist', 'brakes': 'Brakes', 'engine': 'Engine',
  };

  static const Map<String, String> towingOptions = {
    'flatbed': 'Flatbed', 'wheel_lift': 'Wheel Lift', 'heavy_duty': 'Heavy Duty (trucks)',
  };

  static String getSpecializationLabel(String key) {
    if (brandOptions.containsKey(key)) return brandOptions[key]!;
    if (serviceTagOptions.containsKey(key)) return serviceTagOptions[key]!;
    if (towingOptions.containsKey(key)) return towingOptions[key]!;
    
    // Handle custom keys
    if (key.startsWith('custom_brand_')) {
      final label = key.substring('custom_brand_'.length).replaceAll('_', ' ');
      return label.isNotEmpty ? (label[0].toUpperCase() + label.substring(1)) : label;
    }
    if (key.startsWith('custom_service_')) {
      final label = key.substring('custom_service_'.length).replaceAll('_', ' ');
      return label.isNotEmpty ? (label[0].toUpperCase() + label.substring(1)) : label;
    }
    
    // Fallback to humanizing the key
    return key.replaceAll('_', ' ').split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s).join(' ');
  }

  final double totalEarnings;
  final bool remindersEnabled;
  final bool dealsEnabled;
  final String emergencyContactName;
  final String emergencyContactPhone;
  /// Optional username (unique).
  final String? username;
  /// Provider business contact number shown to customers in listings.
  final String? businessContactNumber;
  // Provider business identity details.
  final String? registeredBusinessName;
  final String? tradingName;
  final String? businessType; // cc | pty_ltd | sole_prop
  final String? registrationNumber;
  final int? yearsInOperation;
  final String? primaryServiceCategory; // mechanic | towing | parts
  /// Provider: e.g. "Within 50 km of Windhoek" or "City centre"
  final String serviceAreaDescription;
  /// Provider: e.g. "Mon–Fri 8am–6pm, Sat 9am–1pm" or "24/7"
  final String workingHours;
  /// Provider (mobile): service types they offer, e.g. ['mechanic', 'towing', 'parts']. Min 1 when role is provider.
  final List<String> providerServiceTypes;

  // --- Operational & Business Details ---
  /// Business hours 24/7 toggle (Towing/SOS). Null-safe for DB rows missing the column.
  final bool? businessHours24_7;
  /// Max distance (km) willing to travel.
  final int? serviceRadiusKm;
  final String? workshopAddress;
  final double? workshopLat;
  final double? workshopLng;
  final String? socialFacebook;
  final String? socialInstagram;
  final String? websiteUrl;

  // --- Service Specializations (filters) ---
  final List<String> brandExpertise;
  final List<String> serviceTags;
  final List<String> towingCapabilities;

  // --- Financial & Payout ---
  final String? bankAccountNumber;
  final String? bankBranch;
  final String? bankName;
  final double? standardLaborRate;
  final String? taxVatNumber;

  // --- Trust & Experience ---
  final String? businessBio;
  final String? storeBiography;
  final List<String> galleryUrls;
  final int? teamSize;

  // --- Notification & Alert ---
  /// Null-safe for DB rows missing the column.
  final bool? sosAlertsEnabled;
  /// 'app_chat' | 'phone' | 'whatsapp'
  final String? preferredCommunication;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    this.email = '',
    this.role = 'customer',
    this.profileImg = '',
    this.isBuyer = true,
    this.isSeller = false,
    required this.createdAt,
    required this.lastActive,
    this.loyaltyPoints = 0,
    this.isOnline = true,
    this.verificationStatus = 'pending',
    this.isAdmin = false,
    this.totalEarnings = 0.0,
    this.remindersEnabled = true,
    this.dealsEnabled = false,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.username,
    this.businessContactNumber = '',
    this.registeredBusinessName = '',
    this.tradingName = '',
    this.businessType = 'cc',
    this.registrationNumber = '',
    this.yearsInOperation,
    this.primaryServiceCategory = 'mechanic',
    this.serviceAreaDescription = '',
    this.workingHours = '',
    this.providerServiceTypes = const [],
    this.businessHours24_7 = false,
    this.serviceRadiusKm,
    this.workshopAddress = '',
    this.workshopLat,
    this.workshopLng,
    this.socialFacebook = '',
    this.socialInstagram = '',
    this.websiteUrl = '',
    this.brandExpertise = const [],
    this.serviceTags = const [],
    this.towingCapabilities = const [],
    this.bankAccountNumber = '',
    this.bankBranch = '',
    this.bankName = '',
    this.standardLaborRate,
    this.taxVatNumber = '',
    this.businessBio = '',
    this.storeBiography = '',
    this.galleryUrls = const [],
    this.teamSize,
    this.sosAlertsEnabled = true,
    this.preferredCommunication = 'app_chat',
    this.status = 'active',
  });

  /// Coerces any value to non-null String (avoids "null is not a subtype of String" from API).
  static String _str(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v is String ? v : v.toString();
  }

  static bool _parseBool(dynamic v, [bool fallback = false]) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v == 1 || v == '1' || v == true || v == 'true') return true;
    if (v == 0 || v == '0' || v == false || v == 'false') return false;
    return fallback;
  }

  factory UserProfile.fromMap(Map<String, dynamic> data, {String? uid}) {
    return UserProfile(
      uid: _str(uid ?? data['id'] ?? data['uid']),
      fullName: _str(data['full_name'] ?? data['fullName']),
      phoneNumber: _str(data['phone_number'] ?? data['phoneNumber']),
      email: _str(data['email']),
      role: _str(data['role'], 'customer'),
      profileImg: _str(data['profile_img'] ?? data['profileImg']),
      isBuyer: _parseBool(data['is_buyer'] ?? data['isBuyer'], true),
      isSeller: _parseBool(data['is_seller'] ?? data['isSeller'], false),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastActive: data['last_active'] != null
          ? DateTime.tryParse(data['last_active'].toString()) ?? DateTime.now()
          : DateTime.now(),
      loyaltyPoints: data['loyalty_points'] ?? 0,
      isOnline: _parseBool(data['is_online'], true),
      verificationStatus: _str(data['verification_status'], 'pending'),
      status: _str(data['status'], 'active'),
      isAdmin: _parseBool(data['is_admin'], false),
      totalEarnings: (data['total_earnings'] ?? 0.0).toDouble(),
      remindersEnabled: _parseBool(data['reminders_enabled'], true),
      dealsEnabled: _parseBool(data['deals_enabled'], false),
      emergencyContactName: _str(data['emergency_contact_name'] ?? data['emergencyContactName']),
      emergencyContactPhone: _str(data['emergency_contact_phone'] ?? data['emergencyContactPhone']),
      username: data['username'] as String?,
      businessContactNumber: _str(data['business_contact_number'] ?? data['businessContactNumber']),
      registeredBusinessName: _str(data['registered_business_name'] ?? data['registeredBusinessName']),
      tradingName: _str(data['trading_name'] ?? data['tradingName']),
      businessType: _str(data['business_type'] ?? data['businessType'], 'cc'),
      registrationNumber: _str(data['registration_number'] ?? data['registrationNumber']),
      yearsInOperation: _parseInt(data['years_in_operation'] ?? data['yearsInOperation']),
      primaryServiceCategory: _str(data['primary_service_category'] ?? data['primaryServiceCategory'], 'mechanic'),
      serviceAreaDescription: _str(data['service_area_description'] ?? data['serviceAreaDescription']),
      workingHours: _str(data['working_hours'] ?? data['workingHours']),
      providerServiceTypes: _parseServiceTypes(data['provider_service_types'] ?? data['providerServiceTypes']),
      businessHours24_7: _parseBool(data['business_hours_24_7'], false),
      serviceRadiusKm: _parseInt(data['service_radius_km'] ?? data['serviceRadiusKm']),
      workshopAddress: _str(data['workshop_address'] ?? data['workshopAddress']),
      workshopLat: _parseDouble(data['workshop_lat'] ?? data['workshopLat']),
      workshopLng: _parseDouble(data['workshop_lng'] ?? data['workshopLng']),
      socialFacebook: _str(data['social_facebook'] ?? data['socialFacebook']),
      socialInstagram: _str(data['social_instagram'] ?? data['socialInstagram']),
      websiteUrl: _str(data['website_url'] ?? data['websiteUrl']),
      brandExpertise: _parseList(data['brand_expertise'] ?? data['brandExpertise']),
      serviceTags: _parseList(data['service_tags'] ?? data['serviceTags']),
      towingCapabilities: _parseList(data['towing_capabilities'] ?? data['towingCapabilities']),
      bankAccountNumber: _str(data['bank_account_number'] ?? data['bankAccountNumber']),
      bankBranch: _str(data['bank_branch'] ?? data['bankBranch']),
      bankName: _str(data['bank_name'] ?? data['bankName']),
      standardLaborRate: _parseDouble(data['standard_labor_rate'] ?? data['standardLaborRate']),
      taxVatNumber: _str(data['tax_vat_number'] ?? data['taxVatNumber']),
      businessBio: _str(data['business_bio'] ?? data['businessBio']),
      storeBiography: _str(data['store_biography'] ?? data['storeBiography']),
      galleryUrls: _parseList(data['gallery_urls'] ?? data['galleryUrls'], preserveEmpty: true),
      teamSize: _parseInt(data['team_size'] ?? data['teamSize']),
      sosAlertsEnabled: _parseBool(data['sos_alerts_enabled'], true),
      preferredCommunication: _str(data['preferred_communication'] ?? data['preferredCommunication'], 'app_chat'),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    final n = int.tryParse(v.toString());
    return n;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static List<String> _parseList(dynamic v, {bool preserveEmpty = false}) {
    if (v == null) return [];
    if (v is List) {
      return v.map((e) => e?.toString().trim() ?? '').where((s) => preserveEmpty || s.isNotEmpty).toList();
    }
    final s = v.toString().trim();
    if (s.isEmpty) return [];
    return s.split(',').map((e) => e.trim()).where((e) => preserveEmpty || e.isNotEmpty).toList();
  }

  static List<String> _parseServiceTypes(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e?.toString().trim() ?? '').where((s) => s.isNotEmpty).toList();
    final s = v.toString().trim();
    if (s.isEmpty) return [];
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'role': role,
      'profile_img': profileImg,
      'is_buyer': isBuyer,
      'is_seller': isSeller,
      'created_at': createdAt.toIso8601String(),
      'last_active': DateTime.now().toIso8601String(),
      'loyalty_points': loyaltyPoints,
      'is_online': isOnline,
      'verification_status': verificationStatus,
      'is_admin': isAdmin,
      'total_earnings': totalEarnings,
      'reminders_enabled': remindersEnabled,
      'deals_enabled': dealsEnabled,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      if (username != null) 'username': username,
      'business_contact_number': businessContactNumber ?? '',
      'registered_business_name': registeredBusinessName ?? '',
      'trading_name': tradingName ?? '',
      'business_type': businessType ?? 'cc',
      'registration_number': registrationNumber ?? '',
      'years_in_operation': yearsInOperation,
      'primary_service_category': primaryServiceCategory ?? 'mechanic',
      'service_area_description': serviceAreaDescription,
      'working_hours': workingHours,
      'provider_service_types': providerServiceTypes.isEmpty ? '' : providerServiceTypes.join(','),
      'business_hours_24_7': businessHours24_7 ?? false,
      'service_radius_km': serviceRadiusKm,
      'workshop_address': workshopAddress ?? '',
      'workshop_lat': workshopLat,
      'workshop_lng': workshopLng,
      'social_facebook': socialFacebook ?? '',
      'social_instagram': socialInstagram ?? '',
      'website_url': websiteUrl ?? '',
      'brand_expertise': brandExpertise.isEmpty ? '' : brandExpertise.join(','),
      'service_tags': serviceTags.isEmpty ? '' : serviceTags.join(','),
      'towing_capabilities': towingCapabilities.isEmpty ? '' : towingCapabilities.join(','),
      'bank_account_number': bankAccountNumber ?? '',
      'bank_branch': bankBranch ?? '',
      'bank_name': bankName ?? '',
      'standard_labor_rate': standardLaborRate,
      'tax_vat_number': taxVatNumber ?? '',
      'business_bio': businessBio ?? '',
      'store_biography': storeBiography ?? '',
      'gallery_urls': galleryUrls.isEmpty ? '' : galleryUrls.join(','),
      'team_size': teamSize,
      'sos_alerts_enabled': sosAlertsEnabled ?? true,
      'preferred_communication': preferredCommunication ?? 'app_chat',
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? role,
    String? profileImg,
    bool? isBuyer,
    bool? isSeller,
    DateTime? lastActive,
    int? loyaltyPoints,
    bool? isOnline,
    String? verificationStatus,
    bool? isAdmin,
    double? totalEarnings,
    bool? remindersEnabled,
    bool? dealsEnabled,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? username,
    String? businessContactNumber,
    String? registeredBusinessName,
    String? tradingName,
    String? businessType,
    String? registrationNumber,
    int? yearsInOperation,
    String? primaryServiceCategory,
    String? serviceAreaDescription,
    String? workingHours,
    List<String>? providerServiceTypes,
    bool? businessHours24_7,
    int? serviceRadiusKm,
    String? workshopAddress,
    double? workshopLat,
    double? workshopLng,
    String? socialFacebook,
    String? socialInstagram,
    String? websiteUrl,
    List<String>? brandExpertise,
    List<String>? serviceTags,
    List<String>? towingCapabilities,
    String? bankAccountNumber,
    String? bankBranch,
    String? bankName,
    double? standardLaborRate,
    String? taxVatNumber,
    String? businessBio,
    String? storeBiography,
    List<String>? galleryUrls,
    int? teamSize,
    bool? sosAlertsEnabled,
    String? preferredCommunication,
    String? status,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImg: profileImg ?? this.profileImg,
      isBuyer: isBuyer ?? this.isBuyer,
      isSeller: isSeller ?? this.isSeller,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      isOnline: isOnline ?? this.isOnline,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isAdmin: isAdmin ?? this.isAdmin,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      dealsEnabled: dealsEnabled ?? this.dealsEnabled,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      username: username ?? this.username,
      businessContactNumber: businessContactNumber ?? this.businessContactNumber,
      registeredBusinessName: registeredBusinessName ?? this.registeredBusinessName,
      tradingName: tradingName ?? this.tradingName,
      businessType: businessType ?? this.businessType,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      yearsInOperation: yearsInOperation ?? this.yearsInOperation,
      primaryServiceCategory: primaryServiceCategory ?? this.primaryServiceCategory,
      serviceAreaDescription: serviceAreaDescription ?? this.serviceAreaDescription,
      workingHours: workingHours ?? this.workingHours,
      providerServiceTypes: providerServiceTypes ?? this.providerServiceTypes,
      businessHours24_7: businessHours24_7 ?? this.businessHours24_7,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      workshopAddress: workshopAddress ?? this.workshopAddress,
      workshopLat: workshopLat ?? this.workshopLat,
      workshopLng: workshopLng ?? this.workshopLng,
      socialFacebook: socialFacebook ?? this.socialFacebook,
      socialInstagram: socialInstagram ?? this.socialInstagram,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      brandExpertise: brandExpertise ?? this.brandExpertise,
      serviceTags: serviceTags ?? this.serviceTags,
      towingCapabilities: towingCapabilities ?? this.towingCapabilities,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankBranch: bankBranch ?? this.bankBranch,
      bankName: bankName ?? this.bankName,
      standardLaborRate: standardLaborRate ?? this.standardLaborRate,
      taxVatNumber: taxVatNumber ?? this.taxVatNumber,
      businessBio: businessBio ?? this.businessBio,
      storeBiography: storeBiography ?? this.storeBiography,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      teamSize: teamSize ?? this.teamSize,
      sosAlertsEnabled: sosAlertsEnabled ?? this.sosAlertsEnabled,
      preferredCommunication: preferredCommunication ?? this.preferredCommunication,
      status: status ?? this.status,
    );
  }
}
