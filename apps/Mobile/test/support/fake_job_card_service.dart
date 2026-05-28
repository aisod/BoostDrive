import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory job cards for Orders tab widget tests.
class FakeJobCardService extends JobCardService {
  FakeJobCardService() : super(Supabase.instance.client);

  final Map<String, List<Map<String, dynamic>>> executionByProvider = {};
  final Map<String, List<Map<String, dynamic>>> historyByProvider = {};

  final List<(String jobCardId, String providerId, String status)> statusUpdates = [];

  @override
  Future<List<Map<String, dynamic>>> listExecutionJobCardsForProvider(String providerId) async {
    return List<Map<String, dynamic>>.from(executionByProvider[providerId] ?? const []);
  }

  @override
  Future<List<Map<String, dynamic>>> listExecutionJobCardHistoryForProvider(String providerId) async {
    return List<Map<String, dynamic>>.from(historyByProvider[providerId] ?? const []);
  }

  @override
  Future<void> setExecutionStatus({
    required String jobCardId,
    required String providerId,
    required String status,
  }) async {
    statusUpdates.add((jobCardId, providerId, status));
  }
}
