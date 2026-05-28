import 'package:supabase_flutter/supabase_flutter.dart';

/// Stable demo identities for linked showcase flows across mobile + web.
class DemoSeedIds {
  DemoSeedIds._();

  static const String carlosProvider = '11111111-1111-4111-8111-111111111111';
  static const String sayaCustomerSeller = '22222222-2222-4222-8222-222222222222';
  static const String batlorrihLogistics = '33333333-3333-4333-8333-333333333333';

  static const String providerServiceInspect = '44444444-4444-4444-8444-444444444441';
  static const String providerServiceTow = '44444444-4444-4444-8444-444444444442';
  static const String providerServiceDiagnostic = '44444444-4444-4444-8444-444444444443';

  static const String demoSosRequest = '55555555-5555-4555-8555-555555555555';
  static const String demoJobCard = '66666666-6666-4666-8666-666666666666';
  static const String demoServiceRequest = '77777777-7777-4777-8777-777777777777';
  static const String demoProduct = '88888888-8888-4888-8888-888888888888';
  static const String demoDeliveryOrder = '99999999-9999-4999-8999-999999999999';
}

Future<void> _safeUpsert({
  required SupabaseClient client,
  required String table,
  required Map<String, dynamic> row,
  String? onConflict,
}) async {
  try {
    await client.from(table).upsert(row, onConflict: onConflict);
  } catch (e) {
    // Demo seeding should be resilient across schema revisions.
    print('seed warning [$table upsert]: $e');
  }
}

Future<void> _safeInsert({
  required SupabaseClient client,
  required String table,
  required Map<String, dynamic> row,
}) async {
  try {
    await client.from(table).insert(row);
  } catch (e) {
    print('seed warning [$table insert]: $e');
  }
}

Future<String?> _findProfileId({
  required SupabaseClient client,
  required String fullName,
}) async {
  try {
    final row = await client
        .from('profiles')
        .select('id,full_name')
        .ilike('full_name', fullName)
        .maybeSingle();
    return row?['id']?.toString();
  } catch (_) {
    return null;
  }
}

/// Inserts a single connected demo scenario:
/// - Provider: Carlos Mechanical Services
/// - Customer/Seller: Saya Mubiana
/// - Logistics: BaTLorriH Logistics
/// - Linked records for provider services, SOS, job card, marketplace listing, and delivery.
///
/// Intended for demonstrations in both mobile and web apps.
Future<void> seedDemoShowcaseData({SupabaseClient? client}) async {
  final supabase = client ?? Supabase.instance.client;
  final now = DateTime.now().toUtc();
  final carlosId = await _findProfileId(
        client: supabase,
        fullName: 'Carlos Mechanical Services',
      ) ??
      DemoSeedIds.carlosProvider;
  final sayaId = await _findProfileId(
        client: supabase,
        fullName: 'Saya Mubiana',
      ) ??
      DemoSeedIds.sayaCustomerSeller;
  final batlorrihId = await _findProfileId(
        client: supabase,
        fullName: 'BaTLorriH Logistics',
      ) ??
      DemoSeedIds.batlorrihLogistics;

  final isCarlosExisting = carlosId != DemoSeedIds.carlosProvider;
  final isSayaExisting = sayaId != DemoSeedIds.sayaCustomerSeller;
  final isBatlorrihExisting = batlorrihId != DemoSeedIds.batlorrihLogistics;

  final profiles = <Map<String, dynamic>>[
    {
      'id': carlosId,
      'full_name': 'Carlos Mechanical Services',
      if (!isCarlosExisting) 'email': 'carlos.mechanical.demo@boostdrive.app',
      'phone_number': '+264811100001',
      'role': 'mechanic',
      'is_buyer': false,
      'is_seller': true,
      'verification_status': 'approved',
      'status': 'active',
      'is_online': true,
      'registered_business_name': 'Carlos Mechanical Services CC',
      'trading_name': 'Carlos Mechanical Services',
      'primary_service_category': 'mechanic',
      'provider_service_types': 'mechanic,towing',
      'service_area_description': 'Windhoek and nearby areas',
      'working_hours': 'Mon-Sat 07:00-19:00',
      'business_hours_24_7': true,
      'service_radius_km': 120,
      'workshop_address': 'Lafrenz Industrial, Windhoek',
      'workshop_lat': -22.5149,
      'workshop_lng': 17.0802,
      'standard_labor_rate': 450.0,
      'business_contact_number': '+264811100001',
      'created_at': now.toIso8601String(),
      'last_active': now.toIso8601String(),
    },
    {
      'id': sayaId,
      'full_name': 'Saya Mubiana',
      if (!isSayaExisting) 'email': 'saya.mubiana.demo@boostdrive.app',
      'phone_number': '+264811100002',
      'role': 'customer',
      'is_buyer': true,
      'is_seller': true,
      'verification_status': 'approved',
      'status': 'active',
      'is_online': true,
      'created_at': now.toIso8601String(),
      'last_active': now.toIso8601String(),
      'emergency_contact_name': 'Carlos Mechanical Services',
      'emergency_contact_phone': '+264811100001',
    },
    {
      'id': batlorrihId,
      'full_name': 'BaTLorriH Logistics',
      if (!isBatlorrihExisting) 'email': 'batlorrih.logistics.demo@boostdrive.app',
      'phone_number': '+264811100003',
      'role': 'logistics',
      'is_buyer': false,
      'is_seller': false,
      'verification_status': 'approved',
      'status': 'active',
      'is_online': true,
      'primary_service_category': 'logistics',
      'provider_service_types': 'logistics',
      'service_area_description': 'Namibia local + regional',
      'working_hours': '24/7',
      'business_hours_24_7': true,
      'service_radius_km': 500,
      'workshop_address': 'Northern Industrial, Windhoek',
      'workshop_lat': -22.5458,
      'workshop_lng': 17.0832,
      'created_at': now.toIso8601String(),
      'last_active': now.toIso8601String(),
    },
  ];

  for (final profile in profiles) {
    await _safeUpsert(
      client: supabase,
      table: 'profiles',
      row: profile,
      onConflict: 'id',
    );
  }

  final providerServices = <Map<String, dynamic>>[
    {
      'id': DemoSeedIds.providerServiceInspect,
      'provider_id': carlosId,
      'user_id': carlosId,
      'name': 'Mobile Mechanic',
      'category': 'mechanic',
      'description': 'On-site diagnostics, repairs, and maintenance at your location.',
      'price': 650.0,
      'estimated_minutes': 45,
      'is_active': true,
    },
    {
      'id': DemoSeedIds.providerServiceTow,
      'provider_id': carlosId,
      'user_id': carlosId,
      'name': 'Towing Services',
      'category': 'towing',
      'description': 'Safe towing within Windhoek and nearby service areas.',
      'price': 900.0,
      'estimated_minutes': 60,
      'is_active': true,
    },
  ];
  for (final row in providerServices) {
    await _safeUpsert(
      client: supabase,
      table: 'provider_services',
      row: row,
      onConflict: 'id',
    );
  }

  await _safeUpsert(
    client: supabase,
    table: 'products',
    row: {
      'id': DemoSeedIds.demoProduct,
      'seller_id': sayaId,
      'category': 'part',
      'title': 'Toyota Hilux Front Brake Pads (OEM Spec)',
      'subtitle': 'Ready stock for emergency replacements',
      'description': 'Demonstration listing tied to Carlos service + BatlorriH delivery flow.',
      'price': 1250.0,
      'condition': 'new',
      'status': 'available',
      'location': 'Windhoek',
      'is_featured': true,
      'image_url': 'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?auto=format&fit=crop&w=900&q=80',
      'image_urls': <String>[
        'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?auto=format&fit=crop&w=900&q=80',
      ],
      'fitment': <String, dynamic>{
        'make': 'Toyota',
        'model': 'Hilux',
        'year': 2022,
      },
      'created_at': now.toIso8601String(),
    },
    onConflict: 'id',
  );

  await _safeUpsert(
    client: supabase,
    table: 'sos_requests',
    row: {
      'id': DemoSeedIds.demoSosRequest,
      'user_id': sayaId,
      'assigned_provider_id': carlosId,
      'type': 'mechanic',
      'status': 'assigned',
      'emergency_category': 'engine',
      'location': <String, dynamic>{'lat': -22.5609, 'lng': 17.0658},
      'user_note': 'Demo SOS: vehicle overheating near CBD.',
      'responded_at': now.subtract(const Duration(minutes: 8)).toIso8601String(),
      'provider_last_lat': -22.5538,
      'provider_last_lng': 17.0742,
      'provider_location_updated_at': now.subtract(const Duration(minutes: 1)).toIso8601String(),
      'eta_minutes': 6,
      'created_at': now.subtract(const Duration(minutes: 10)).toIso8601String(),
    },
    onConflict: 'id',
  );

  await _safeUpsert(
    client: supabase,
    table: 'provider_job_cards',
    row: {
      'id': DemoSeedIds.demoJobCard,
      'requester_id': sayaId,
      'requester_role': 'seller',
      'customer_id': sayaId,
      'provider_id': carlosId,
      'assigned_provider_id': carlosId,
      'vehicle_label': '2022 Toyota Hilux',
      'concern_summary': 'Brake vibration and reduced stopping power.',
      'diagnosis_notes': 'Pads worn out, rotors require skim.',
      'labor_amount': 1450.0,
      'status': 'accepted',
      'sos_request_id': DemoSeedIds.demoSosRequest,
      'quoted_at': now.subtract(const Duration(minutes: 4)).toIso8601String(),
      'customer_decision_at': now.subtract(const Duration(minutes: 2)).toIso8601String(),
      'created_at': now.subtract(const Duration(minutes: 12)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    },
    onConflict: 'id',
  );

  // Service requests schema can vary between environments. Keep this optional.
  await _safeInsert(
    client: supabase,
    table: 'service_requests',
    row: {
      'id': DemoSeedIds.demoServiceRequest,
      'title': 'Hilux brake service appointment',
      'status': 'open',
      'request_kind': 'scheduled',
      'assigned_provider_id': carlosId,
      'customer_id': sayaId,
      'provider_id': carlosId,
      'scheduled_start': now.add(const Duration(hours: 1)).toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    },
  );

  await _safeUpsert(
    client: supabase,
    table: 'delivery_orders',
    row: {
      'id': DemoSeedIds.demoDeliveryOrder,
      'customer_id': sayaId,
      'seller_id': sayaId,
      'driver_id': batlorrihId,
      'status': 'in_transit',
      'pickup_location': <String, dynamic>{
        'name': 'Carlos Mechanical Services Workshop',
        'lat': -22.5149,
        'lng': 17.0802,
      },
      'dropoff_location': <String, dynamic>{
        'name': 'Saya Mubiana - Eros, Windhoek',
        'lat': -22.5497,
        'lng': 17.0923,
      },
      'items': <String, dynamic>{
        'product_id': DemoSeedIds.demoProduct,
        'title': 'Toyota Hilux Front Brake Pads (OEM Spec)',
        'quantity': 1,
      },
      'eta': '18 min',
      'delivery_fee': 95.0,
      'vehicle_id': 'BATLORRIH-TRUCK-01',
      'driver_last_lat': -22.5311,
      'driver_last_lng': 17.0867,
      'driver_location_updated_at': now.toIso8601String(),
      'created_at': now.subtract(const Duration(minutes: 14)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    },
    onConflict: 'id',
  );

  print('Demo showcase seed complete: Carlos + Saya + BaTLorriH scenario ready.');
}

/// Backward-compatible alias retained for existing call-sites.
Future<void> seedBoostDriveData() async => seedDemoShowcaseData();
