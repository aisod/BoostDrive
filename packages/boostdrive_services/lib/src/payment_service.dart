import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentService {
  final _supabase = Supabase.instance.client;

  Future<bool> processPayment({
    required String productId,
    required String customerId,
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> cardDetails,
  }) async {
    try {
      // Mocking a payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate success (In a real app, this would call a payment gateway API)
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('transactions').insert({
        'id': transactionId,
        'product_id': productId,
        'customer_id': customerId,
        'amount': amount,
        'status': 'completed',
        'payment_method': paymentMethod,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Payment processing error: $e');
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getTransactions(String userId) {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('customer_id', userId)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getTransactionsFuture(String userId) async {
    final response = await _supabase
        .from('transactions')
        .select()
        .eq('customer_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});
