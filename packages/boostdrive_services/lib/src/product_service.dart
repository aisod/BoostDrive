import 'dart:typed_data';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This is the "Global Key" to your Product Service
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

/// Single product by id (e.g. for conversation list/header product context).
final productByIdProvider = FutureProvider.family<Product?, String>((ref, productId) {
  return ref.watch(productServiceProvider).getProductById(productId);
});

final pendingListingsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productServiceProvider).streamPendingListings();
});

final adminListingsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productServiceProvider).streamAdminListings();
});

class ProductService {
  final _supabase = Supabase.instance.client;

  /// Tracks a listing click/open and returns the updated click count (best effort).
  ///
  /// Uses a Postgres RPC (`increment_product_click_count`) to avoid race conditions.
  Future<int?> trackListingClick(String productId) async {
    try {
      final result = await _supabase.rpc('increment_product_click_count', params: {
        'p_product_id': productId,
      });
      if (result == null) return null;
      if (result is int) return result;
      return int.tryParse(result.toString());
    } catch (e) {
      // Non-critical: click tracking should never block browsing.
      print('Error tracking listing click: $e');
      return null;
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('status', 'available')
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(10);

      final list = response as List;
      return list.map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      print('Error fetching featured products: $e');
      return [];
    }
  }

  /// Returns all available marketplace listings (not just featured).
  Future<List<Product>> getMarketplaceProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      final list = response as List;
      final products = list
          .map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      print('DEBUG: getMarketplaceProducts fetched ${products.length} rows');
      return products;
    } catch (e) {
      print('Error fetching marketplace products: $e');
      return [];
    }
  }

  Future<List<Product>> getNewArrivals() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final response = await _supabase
          .from('products')
          .select()
          .eq('status', 'available')
          .gte('created_at', yesterday.toIso8601String())
          .order('created_at', ascending: false);

      final list = response as List;
      return list.map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      print('Error fetching new arrivals: $e');
      return [];
    }
  }

  /// Fetches a single product by id (e.g. for conversation product context).
  Future<Product?> getProductById(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();
      if (response == null) return null;
      return Product.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error fetching product by id: $e');
      return null;
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    return searchProducts(category: category);
  }

  Future<List<Product>> searchProducts({
    String? category,
    String? query,
    String? make,
    String? model,
    int? year,
    String? condition,
  }) async {
    try {
      var supabaseQuery = _supabase
          .from('products')
          .select();

      if (category != null && category != 'all') {
        supabaseQuery = supabaseQuery.eq('category', category);
      }

      if (query != null && query.isNotEmpty) {
        supabaseQuery = supabaseQuery.ilike('title', '%$query%');
      }
      
      if (make != null) supabaseQuery = supabaseQuery.eq('fitment->>make', make);
      if (model != null) supabaseQuery = supabaseQuery.eq('fitment->>model', model);
      if (year != null) supabaseQuery = supabaseQuery.eq('fitment->>year', year.toString());
      if (condition != null) supabaseQuery = supabaseQuery.eq('condition', condition);

      final response = await supabaseQuery.order('created_at', ascending: false);
      final list = response as List;
      return list.map((data) => Product.fromMap(Map<String, dynamic>.from(data as Map))).toList();
    } catch (e) {
      print('DEBUG: Error searching products: $e');
      if (e is PostgrestException) {
        print('DEBUG: Supabase Error Details: ${e.message}, Code: ${e.code}, Details: ${e.details}, Hint: ${e.hint}');
      }
      return [];
    }
  }

  Future<List<Product>> searchParts({
    String? make,
    String? model,
    int? year,
    String? condition,
    String? query,
  }) async {
    try {
      var supabaseQuery = _supabase.from('products').select().eq('category', 'part');

      if (make != null) supabaseQuery = supabaseQuery.eq('fitment->>make', make);
      if (model != null) supabaseQuery = supabaseQuery.eq('fitment->>model', model);
      if (year != null) supabaseQuery = supabaseQuery.eq('fitment->>year', year.toString());
      if (condition != null) supabaseQuery = supabaseQuery.eq('condition', condition);
      if (query != null && query.isNotEmpty) {
        supabaseQuery = supabaseQuery.ilike('title', '%$query%');
      }

      final response = await supabaseQuery.order('created_at', ascending: false);
      final list = response as List;
      return list.map((data) => Product.fromMap(Map<String, dynamic>.from(data as Map))).toList();
    } catch (e) {
      print('DEBUG: Error searching parts: $e');
      if (e is PostgrestException) {
        print('DEBUG: Supabase Error Details: ${e.message}, Code: ${e.code}, Details: ${e.details}, Hint: ${e.hint}');
      }
      return [];
    }
  }

  Future<String?> addProduct(Product product) async {
    try {
      final response = await _supabase.from('products').insert(product.toMap()).select('id').single();
      return response['id'].toString();
    } catch (e) {
      print('Error adding product: $e');
      rethrow; 
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _supabase
          .from('products')
          .update(product.toMap())
          .eq('id', product.id);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _supabase
          .from('products')
          .delete()
          .eq('id', productId);
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<String> uploadProductImage(List<int> bytes, String fileName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User must be logged in to upload images');

      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await _supabase.storage.from('product-images').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl = _supabase.storage.from('product-images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Stream<List<Product>> streamPendingListings() {
    final realtime = _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => Product.fromMap(e)).toList());
    return _withPollingFallback(
      realtime,
      _fetchPendingListingsSnapshot,
      label: 'streamPendingListings',
    );
  }

  Stream<List<Product>> streamAdminListings() {
    final realtime = _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => Product.fromMap(e)).toList());
    return _withPollingFallback(
      realtime,
      _fetchAdminListingsSnapshot,
      label: 'streamAdminListings',
    );
  }

  Stream<List<Product>> streamSellerProducts(String sellerId) {
    final realtime = _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('seller_id', sellerId)
        .map((data) => data.map((e) => Product.fromMap(e)).toList());
    return _withPollingFallback(
      realtime,
      () => _fetchSellerProductsSnapshot(sellerId),
      label: 'streamSellerProducts',
      interval: const Duration(seconds: 6),
    );
  }

  Future<void> updateListingStatus(String productId, String status, {String? rejectionReason}) async {
    try {
      final response = await _supabase
          .from('products')
          .update({
            'status': status,
            'rejection_reason': rejectionReason,
          })
          .eq('id', productId)
          .select()
          .maybeSingle();
          
      if (response == null) {
        throw Exception('Update failed: Listing not found or permission denied (RLS).');
      }
    } catch (e) {
      print('Error updating listing status: $e');
      rethrow;
    }
  }

  Stream<List<Product>> _withPollingFallback(
    Stream<List<Product>> realtime,
    Future<List<Product>> Function() fetchSnapshot, {
    required String label,
    Duration interval = const Duration(seconds: 8),
  }) async* {
    try {
      yield* realtime;
      return;
    } catch (e) {
      print('DEBUG: $label realtime failed, switching to polling: $e');
    }

    while (true) {
      try {
        yield await fetchSnapshot();
      } catch (e) {
        print('DEBUG: $label polling fetch failed: $e');
        yield const <Product>[];
      }
      await Future<void>.delayed(interval);
    }
  }

  Future<List<Product>> _fetchPendingListingsSnapshot() async {
    final rows = await _supabase
        .from('products')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Product>> _fetchAdminListingsSnapshot() async {
    final rows = await _supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Product>> _fetchSellerProductsSnapshot(String sellerId) async {
    final rows = await _supabase
        .from('products')
        .select()
        .eq('seller_id', sellerId);
    return (rows as List<dynamic>)
        .map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

final sellerProductsProvider = StreamProvider.family<List<Product>, String>((ref, sellerId) {
  return ref.watch(productServiceProvider).streamSellerProducts(sellerId);
});
