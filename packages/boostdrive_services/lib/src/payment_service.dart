import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentService {
  final _supabase = Supabase.instance.client;

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
