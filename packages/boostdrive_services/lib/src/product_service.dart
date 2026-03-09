import 'dart:typed_data';
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

      final list = response is List ? response : (response != null ? [response] : <dynamic>[]);
      return list.map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      print('Error fetching featured products: $e');
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

      final list = response is List ? response : (response != null ? [response] : <dynamic>[]);
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
      final list = response is List ? response : (response != null ? [response] : <dynamic>[]);
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
      final list = response is List ? response : (response != null ? [response] : <dynamic>[]);
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
}

final sellerProductsProvider = StreamProvider.family<List<Product>, String>((ref, sellerId) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('products')
      .stream(primaryKey: ['id'])
      .eq('seller_id', sellerId)
      .map((data) => data.map((e) => Product.fromMap(e)).toList());
});
