import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_service.dart';




final featuredProductsProvider = FutureProvider((ref) async {
  final productService = ref.watch(productServiceProvider);
  return productService.getFeaturedProducts();
});

/// A global trigger to force dashboard refreshes after CRUD operations
final dashboardRefreshProvider = StateProvider<int>((ref) => 0);
