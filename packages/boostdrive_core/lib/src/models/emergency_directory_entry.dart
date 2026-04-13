import 'namibia_location.dart';

/// One row from `emergency_directory_entries` (Namibia / roadside directory).
/// [category] is plain text (e.g. `police`, `ambulance`) — not a PostgreSQL enum.
/// Location is resolved via [locationCode] + optional joined [NamibiaLocation] metadata.
class EmergencyDirectoryEntry {
  const EmergencyDirectoryEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.phone,
    this.secondaryPhone,
    required this.locationCode,
    required this.displayLocality,
    required this.locationKind,
    this.parentRegionCode,
    this.organization,
    this.notes,
    required this.displayOrder,
  });

  final String id;
  final String category;
  final String title;
  final String phone;
  final String? secondaryPhone;
  /// FK to `namibia_locations.code`
  final String locationCode;
  /// Human-readable place name (town/city/region/national).
  final String displayLocality;
  final String locationKind;
  final String? parentRegionCode;
  final String? organization;
  final String? notes;
  final int displayOrder;

  /// Region used for "region" filter chips: parent region for settlements, else own code for region-level rows.
  String get effectiveRegionCode => parentRegionCode ?? locationCode;

  factory EmergencyDirectoryEntry.fromMap(
    Map<String, dynamic> map, {
    NamibiaLocation? location,
  }) {
    String? nonEmpty(String? s) {
      final t = s?.trim() ?? '';
      return t.isEmpty ? null : t;
    }

    final locCode = nonEmpty(map['location_code']?.toString()) ??
        nonEmpty(map['region']?.toString()) ??
        'national';

    final locName = location?.name ??
        (locCode == 'national' ? 'National' : _titleCaseUnderscore(locCode));
    final kind = location?.kind ?? 'region';
    final parent = location?.parentCode;

    return EmergencyDirectoryEntry(
      id: map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? 'other',
      title: map['title']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      secondaryPhone: nonEmpty(map['secondary_phone']?.toString()),
      locationCode: locCode,
      displayLocality: locName,
      locationKind: kind,
      parentRegionCode: parent,
      organization: nonEmpty(map['organization']?.toString()),
      notes: nonEmpty(map['notes']?.toString()),
      displayOrder: (map['display_order'] as num?)?.round() ?? 0,
    );
  }

  static String _titleCaseUnderscore(String code) {
    return code.split('_').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }
}
