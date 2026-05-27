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

  /// Payouts and delivery fees credited to a logistics provider.
  Future<List<Map<String, dynamic>>> getProviderTransactions(String providerId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .or('provider_id.eq.$providerId,seller_id.eq.$providerId')
          .order('created_at', ascending: false)
          .limit(50);
      return (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      final fallback = await _supabase
          .from('transactions')
          .select()
          .eq('seller_id', providerId)
          .order('created_at', ascending: false)
          .limit(50);
      return (fallback as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});
