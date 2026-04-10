import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';


// Simple Cart Item model
class CartItem {
  final Product product;
  final int quantity;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.rentalStartDate,
    this.rentalEndDate,
  });

  double get totalPrice {
    if (product.category == 'rental' && rentalStartDate != null && rentalEndDate != null) {
      final days = rentalEndDate!.difference(rentalStartDate!).inDays;
      return product.price * (days == 0 ? 1 : days); // Minimum 1 day
    }
    return product.price * quantity;
  }
}

// Cart State Notifier
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    unawaited(_loadPersistedCart());
  }

  static const String _cartStoragePrefix = 'boostdrive_cart_';

  String _storageKey() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return '$_cartStoragePrefix${userId ?? 'guest'}';
  }

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((item) {
      return {
        'product': item.product.toMap(),
        'quantity': item.quantity,
        'rentalStartDate': item.rentalStartDate?.toIso8601String(),
        'rentalEndDate': item.rentalEndDate?.toIso8601String(),
      };
    }).toList());
    await prefs.setString(_storageKey(), encoded);
  }

  Future<void> _loadPersistedCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey());
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final loaded = decoded.map((entry) {
        final map = Map<String, dynamic>.from(entry as Map);
        final productMap = Map<String, dynamic>.from(map['product'] as Map);
        return CartItem(
          product: Product.fromMap(productMap),
          quantity: (map['quantity'] as num?)?.toInt() ?? 1,
          rentalStartDate: map['rentalStartDate'] != null
              ? DateTime.tryParse(map['rentalStartDate'].toString())
              : null,
          rentalEndDate: map['rentalEndDate'] != null
              ? DateTime.tryParse(map['rentalEndDate'].toString())
              : null,
        );
      }).toList();
      state = loaded;
    } catch (_) {
      // If corrupted, clear persisted copy to avoid repeated parse failures.
      await prefs.remove(_storageKey());
    }
  }

  String _productIdentity(Product p) {
    final id = p.id.trim();
    if (id.isNotEmpty) return 'id:$id';
    // Fallback for malformed/legacy rows where id can be empty in client data.
    return 'fallback:${p.sellerId ?? ''}|${p.category}|${p.title}|${p.subtitle}|${p.price}';
  }

  bool _isSameProduct(Product a, Product b) {
    final aId = a.id.trim();
    final bId = b.id.trim();
    if (aId.isNotEmpty && bId.isNotEmpty) {
      return aId == bId;
    }
    return _productIdentity(a) == _productIdentity(b);
  }

  void addItem(
    Product product, {
    DateTime? startDate,
    DateTime? endDate,
    int quantity = 1,
  }) {
    // Match by id when present, otherwise by a stable fallback identity.
    final existingIndex = state.indexWhere((item) => _isSameProduct(item.product, product));
    
    if (existingIndex >= 0 && product.category != 'rental') {
      // Increment quantity for non-rentals
      final existingItem = state[existingIndex];
      final safeQuantity = quantity < 1 ? 1 : quantity;
      final newQuantity = existingItem.quantity + safeQuantity;
      
      final updatedItem = CartItem(
        product: product,
        quantity: newQuantity,
      );
      
      final newState = [...state];
      newState[existingIndex] = updatedItem;
      state = newState;
      unawaited(_persistCart());
    } else {
      // Add new
      state = [
        ...state,
        CartItem(
          product: product, 
          quantity: product.category == 'rental' ? 1 : (quantity < 1 ? 1 : quantity),
          rentalStartDate: startDate,
          rentalEndDate: endDate
        )
      ];
      unawaited(_persistCart());
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
    unawaited(_persistCart());
  }

  void clearCart() {
    state = [];
    unawaited(_persistCart());
  }

  double get grandTotal => state.fold(0, (sum, item) => sum + item.totalPrice);
}

// Providers
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// Checkout Service
final checkoutServiceProvider = Provider((ref) => CheckoutService());

class CheckoutService {
  final _supabase = Supabase.instance.client;

  Future<String> placeOrder(String userId, List<CartItem> items, double total) async {
    // 1. Create Order
    final response = await _supabase.from('orders').insert({
      'user_id': userId,
      'status': 'pending', // pending, paid, shipped, completed
      'created_at': DateTime.now().toIso8601String(),
      'total': total,
      'items': items.map((item) => {
        'productId': item.product.id,
        'title': item.product.title,
        'price': item.product.price,
        'quantity': item.quantity,
        'category': item.product.category,
        'rentalStart': item.rentalStartDate?.toIso8601String(),
        'rentalEnd': item.rentalEndDate?.toIso8601String(),
      }).toList(),
    }).select('id').single();

    return response['id'].toString();
  }
}
