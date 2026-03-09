class Product {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final List<String> imageUrls;
  final String location;
  final bool isFeatured;
  final String category; // 'car', 'part', 'rental'
  /// How many times the listing was opened/clicked. Null if DB has no column or value.
  final int? clickCount;
  
  // REAL DATA FIELDS
  final String condition; // 'new', 'used', 'salvage'
  final String status; // 'active', 'sold', 'draft'
  final Map<String, dynamic>? fitment; // { 'make': 'Toyota', 'model': 'Hilux', 'year': 2020 }
  final String? sellerId;
  final DateTime? createdAt;
  final String description;

  const Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.imageUrls,
    required this.location,
    this.isFeatured = false,
    required this.category,
    this.clickCount,
    this.condition = 'used',
    this.status = 'active',
    this.fitment,
    this.sellerId,
    this.createdAt,
    this.description = '',
  });

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  /// Parses click_count from API/DB (may be null, int, or number string).
  static int? _parseClickCount(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final parsed = int.tryParse(v.toString());
    return parsed;
  }

  factory Product.fromMap(Map<String, dynamic> data, {String? id}) {
    return Product(
      id: id ?? data['id'] ?? '',
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrls: data['image_urls'] != null 
          ? List<String>.from(data['image_urls']) 
          : (data['image_url'] != null ? [data['image_url'] as String] : []),
      location: data['location'] ?? 'Namibia',
      isFeatured: data['is_featured'] ?? false,
      category: data['category'] ?? 'car',
      clickCount: _parseClickCount(data['click_count'] ?? data['clickCount']),
      condition: data['condition'] ?? 'used',
      status: data['status'] ?? 'active',
      fitment: data['fitment'] != null ? Map<String, dynamic>.from(data['fitment']) : null,
      sellerId: data['seller_id'],
      createdAt: data['created_at'] != null 
          ? DateTime.tryParse(data['created_at'].toString()) 
          : null,
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'price': price,
      'image_urls': imageUrls,
      'image_url': imageUrl, 
      'location': location,
      'is_featured': isFeatured,
      'category': category,
      if (clickCount != null) 'click_count': clickCount,
      'condition': condition,
      'status': status,
      if (fitment != null) 'fitment': fitment,
      if (sellerId != null) 'seller_id': sellerId,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'description': description,
    };
  }

  Product copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? price,
    List<String>? imageUrls,
    String? location,
    bool? isFeatured,
    String? category,
    int? clickCount,
    String? condition,
    String? status,
    Map<String, dynamic>? fitment,
    String? sellerId,
    DateTime? createdAt,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      isFeatured: isFeatured ?? this.isFeatured,
      category: category ?? this.category,
      clickCount: clickCount ?? this.clickCount,
      condition: condition ?? this.condition,
      status: status ?? this.status,
      fitment: fitment ?? this.fitment,
      sellerId: sellerId ?? this.sellerId,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }
}
