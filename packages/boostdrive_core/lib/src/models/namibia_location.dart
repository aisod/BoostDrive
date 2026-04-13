/// One row from `namibia_locations` (regions, cities, towns, or national).
/// [kind] is plain text: `national`, `region`, `city`, or `town`.
class NamibiaLocation {
  const NamibiaLocation({
    required this.code,
    required this.name,
    required this.kind,
    this.parentCode,
    required this.sortOrder,
  });

  final String code;
  final String name;
  final String kind;
  final String? parentCode;
  final int sortOrder;

  bool get isNational => kind == 'national';
  bool get isRegion => kind == 'region';

  factory NamibiaLocation.fromMap(Map<String, dynamic> map) {
    return NamibiaLocation(
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      kind: map['kind']?.toString() ?? 'town',
      parentCode: (map['parent_code']?.toString().trim().isEmpty ?? true)
          ? null
          : map['parent_code']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.round() ?? 0,
    );
  }
}
