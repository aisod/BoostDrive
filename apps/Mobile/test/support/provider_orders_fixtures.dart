import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sos_fixtures.dart';

User testProviderUser({String id = 'provider-1'}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime.utc(2026, 1, 1).toIso8601String(),
    email: 'provider@test.com',
  );
}

UserProfile mechanicProviderProfile({String uid = 'provider-1'}) {
  return UserProfile(
    uid: uid,
    fullName: 'Test Mechanic',
    phoneNumber: '+264811111111',
    role: 'mechanic',
    createdAt: DateTime.utc(2026, 1, 1),
    lastActive: DateTime.utc(2026, 5, 27),
    providerServiceTypes: const ['mechanic'],
  );
}

UserProfile emptyServiceTypesProfile({String uid = 'provider-1'}) {
  return UserProfile(
    uid: uid,
    fullName: 'Test Provider',
    phoneNumber: '+264811111111',
    role: 'mechanic',
    createdAt: DateTime.utc(2026, 1, 1),
    lastActive: DateTime.utc(2026, 5, 27),
    providerServiceTypes: const [],
  );
}

SosRequest pendingForOrdersPool() => pendingMechanicRequest(id: 'pool-1');

Map<String, dynamic> sampleExecutionJobCard({String id = 'job-1'}) {
  return {
    'id': id,
    'vehicle_label': 'Toyota Hilux',
    'concern_summary': 'Brake inspection',
    'status': 'accepted',
    'labor_amount': 450.0,
  };
}

Map<String, dynamic> sampleServiceRequest({String id = 'req-1'}) {
  return {
    'id': id,
    'title': 'Oil change',
    'status': 'pending',
    'request_kind': 'service',
  };
}

Map<String, dynamic> sampleHistoryJobCard({String id = 'job-h1'}) {
  return {
    'id': id,
    'vehicle_label': 'Ford Ranger',
    'status': 'completed',
    'completed_at': '2026-05-20',
  };
}
