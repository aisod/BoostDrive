/// One person to reach for roadside / SOS context (stored in [UserProfile.emergencyContacts]).
class EmergencyContact {
  final String name;
  final String phone;

  const EmergencyContact({this.name = '', this.phone = ''});

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
      };

  factory EmergencyContact.fromMap(Map<String, dynamic> m) {
    return EmergencyContact(
      name: (m['name'] ?? '').toString().trim(),
      phone: (m['phone'] ?? '').toString().trim(),
    );
  }
}
