import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/src/cart_service.dart';
import 'package:flutter_test/flutter_test.dart';

Product _buildProduct({
  required String id,
  required String category,
  required double price,
}) {
  return Product(
    id: id,
    title: 'Demo',
    subtitle: 'Demo subtitle',
    price: price,
    imageUrls: const [],
    location: 'Windhoek',
    category: category,
  );
}

void main() {
  group('CartItem.totalPrice', () {
    test('multiplies quantity for non-rental products', () {
      final item = CartItem(
        product: _buildProduct(id: 'part-1', category: 'part', price: 150),
        quantity: 3,
      );

      expect(item.totalPrice, 450);
    });

    test('uses day range for rental products', () {
      final item = CartItem(
        product: _buildProduct(id: 'rent-1', category: 'rental', price: 800),
        rentalStartDate: DateTime(2026, 4, 20),
        rentalEndDate: DateTime(2026, 4, 23),
      );

      expect(item.totalPrice, 2400);
    });

    test('enforces minimum one rental day', () {
      final day = DateTime(2026, 4, 20);
      final item = CartItem(
        product: _buildProduct(id: 'rent-2', category: 'rental', price: 800),
        rentalStartDate: day,
        rentalEndDate: day,
      );

      expect(item.totalPrice, 800);
    });
  });
}
