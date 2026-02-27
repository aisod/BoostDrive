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
  final String verificationStatus;
  final double totalEarnings;
  final bool remindersEnabled;
  final bool dealsEnabled;
  final String emergencyContactName;
  final String emergencyContactPhone;

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
    this.totalEarnings = 0.0,
    this.remindersEnabled = true,
    this.dealsEnabled = false,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, {String? uid}) {
    return UserProfile(
      uid: uid ?? data['id'] ?? data['uid'] ?? '',
      fullName: data['full_name'] ?? data['fullName'] ?? '',
      phoneNumber: data['phone_number'] ?? data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      profileImg: data['profile_img'] ?? data['profileImg'] ?? '',
      isBuyer: data['is_buyer'] ?? data['isBuyer'] ?? true,
      isSeller: data['is_seller'] ?? data['isSeller'] ?? false,
      createdAt: data['created_at'] != null 
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastActive: data['last_active'] != null 
          ? DateTime.tryParse(data['last_active'].toString()) ?? DateTime.now()
          : DateTime.now(),
      loyaltyPoints: data['loyalty_points'] ?? 0,
      isOnline: data['is_online'] ?? true,
      verificationStatus: data['verification_status'] ?? 'pending',
      totalEarnings: (data['total_earnings'] ?? 0.0).toDouble(),
      remindersEnabled: data['reminders_enabled'] ?? true,
      dealsEnabled: data['deals_enabled'] ?? false,
      emergencyContactName: data['emergency_contact_name'] ?? '',
      emergencyContactPhone: data['emergency_contact_phone'] ?? '',
    );
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
      'total_earnings': totalEarnings,
      'reminders_enabled': remindersEnabled,
      'deals_enabled': dealsEnabled,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? role,
    String? profileImg,
    bool? isBuyer,
    bool? isSeller,
    DateTime? lastActive,
    int? loyaltyPoints,
    bool? isOnline,
    String? verificationStatus,
    double? totalEarnings,
    bool? remindersEnabled,
    bool? dealsEnabled,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber,
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
      totalEarnings: totalEarnings ?? this.totalEarnings,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      dealsEnabled: dealsEnabled ?? this.dealsEnabled,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }
}
