import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory provider ops for Orders tab widget tests.
class FakeProviderOpsService extends ProviderOpsService {
  FakeProviderOpsService() : super(Supabase.instance.client);

  final Map<String, List<Map<String, dynamic>>> activeRequestsByProvider = {};
  final Map<String, List<Map<String, dynamic>>> historyByProvider = {};

  @override
  Future<List<Map<String, dynamic>>> listServiceRequestsForProvider(String providerId) async {
    return List<Map<String, dynamic>>.from(activeRequestsByProvider[providerId] ?? const []);
  }

  @override
  Future<List<Map<String, dynamic>>> listServiceRequestsHistory(String providerId) async {
    return List<Map<String, dynamic>>.from(historyByProvider[providerId] ?? const []);
  }
}
